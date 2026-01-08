// ============================================
// SERVICE MAPS - ABSTRACTION
// ============================================
// Architecture PROPRE pour migrer vers Google Maps facilement
// 
// MIGRATION GOOGLE MAPS - ÉTAPES:
// 1. Ajouter google_maps_flutter aux pubspec.yaml
// 2. Créer GoogleMapsProvider implements MapProvider
// 3. Changer useGoogleMaps = true dans la config
// 4. Ajouter votre API Key dans AndroidManifest.xml et Info.plist
//
// Aucune modification des écrans nécessaire !
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

// ============================================
// INTERFACE ABSTRAITE (Contract)
// ============================================

/// Interface que TOUS les providers de carte doivent implémenter
/// Permet de switcher entre OpenStreetMap, Google Maps, Mapbox, etc.
abstract class MapProvider {
  /// Nom du provider (pour debug/logs)
  String get name;

  /// Widget de carte à afficher dans l'UI
  Widget buildMap({
    required LatLng center,
    required double zoom,
    List<MapMarker>? markers,
    List<LatLng>? polyline,
    Function(LatLng)? onTap,
    MapController? controller,
  });

  /// Calcule la distance entre 2 points (en mètres)
  /// Retourne toujours la distance à vol d'oiseau (Haversine)
  Future<double> calculateDistance(LatLng from, LatLng to);

  /// Obtient un itinéraire entre 2 points
  /// - OpenStreetMap: ligne droite simple
  /// - Google Maps: itinéraire routier réel (si API activée)
  Future<List<LatLng>> getRoute(LatLng from, LatLng to);

  /// Dispose les ressources (si nécessaire)
  void dispose() {}
}

// ============================================
// MODÈLE MARKER (Universel)
// ============================================

/// Marker universel compatible tous providers
class MapMarker {
  final LatLng position;
  final String? label;
  final Color color;
  final IconData icon;

  const MapMarker({
    required this.position,
    this.label,
    this.color = Colors.red,
    this.icon = Icons.location_on,
  });
}

// ============================================
// IMPLÉMENTATION 1 : OPENSTREETMAP (Gratuit)
// ============================================

/// Provider OpenStreetMap (gratuit, illimité)
/// Parfait pour MVP et petits volumes
class OpenStreetMapProvider implements MapProvider {
  @override
  String get name => 'OpenStreetMap';

  @override
  Widget buildMap({
    required LatLng center,
    required double zoom,
    List<MapMarker>? markers,
    List<LatLng>? polyline,
    Function(LatLng)? onTap,
    MapController? controller,
  }) {
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        onTap: onTap != null 
            ? (_, pos) => onTap(pos)
            : null,
      ),
      children: [
        // Tuiles OpenStreetMap
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.agronet.app',
        ),
        
        // Polyline (itinéraire)
        if (polyline != null && polyline.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: polyline,
                strokeWidth: 4.0,
                color: Colors.blue,
              ),
            ],
          ),
        
        // Markers
        if (markers != null && markers.isNotEmpty)
          MarkerLayer(
            markers: markers.map((m) {
              return Marker(
                point: m.position,
                width: 40,
                height: 40,
                child: Icon(
                  m.icon,
                  color: m.color,
                  size: 40,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  @override
  Future<double> calculateDistance(LatLng from, LatLng to) async {
    // Formule Haversine (distance à vol d'oiseau)
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, from, to);
  }

  @override
  Future<List<LatLng>> getRoute(LatLng from, LatLng to) async {
    // Pour OpenStreetMap: ligne droite simple
    // Si vous voulez un vrai routage, utilisez OSRM (API externe gratuite)
    return [from, to];
  }

  @override
  void dispose() {
    // Rien à nettoyer pour OSM
  }
}

// ============================================
// IMPLÉMENTATION 2 : GOOGLE MAPS (Futur)
// ============================================

/// Provider Google Maps (nécessite API Key)
/// À implémenter quand vous serez prêt
/// 
/// MIGRATION ÉTAPES:
/// 1. Installer: flutter pub add google_maps_flutter
/// 2. Ajouter clé API dans:
///    - android/app/src/main/AndroidManifest.xml:
///      <meta-data
///        android:name="com.google.android.geo.API_KEY"
///        android:value="VOTRE_CLE_ICI"/>
///    - ios/Runner/AppDelegate.swift:
///      GMSServices.provideAPIKey("VOTRE_CLE_ICI")
/// 3. Décommenter le code ci-dessous
/// 4. Changer MapsService.useGoogleMaps = true

/*
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:http/http.dart' as http;
import 'dart:convert';

class GoogleMapsProvider implements MapProvider {
  gm.GoogleMapController? _controller;
  
  @override
  String get name => 'Google Maps';

  @override
  Widget buildMap({
    required LatLng center,
    required double zoom,
    List<MapMarker>? markers,
    List<LatLng>? polyline,
    Function(LatLng)? onTap,
    MapController? controller,
  }) {
    return gm.GoogleMap(
      initialCameraPosition: gm.CameraPosition(
        target: gm.LatLng(center.latitude, center.longitude),
        zoom: zoom,
      ),
      onMapCreated: (c) => _controller = c,
      onTap: onTap != null 
          ? (pos) => onTap(LatLng(pos.latitude, pos.longitude))
          : null,
      markers: markers?.map((m) {
        return gm.Marker(
          markerId: gm.MarkerId(m.position.toString()),
          position: gm.LatLng(m.position.latitude, m.position.longitude),
          infoWindow: gm.InfoWindow(title: m.label),
        );
      }).toSet() ?? {},
      polylines: polyline != null ? {
        gm.Polyline(
          polylineId: const gm.PolylineId('route'),
          points: polyline.map((p) => gm.LatLng(p.latitude, p.longitude)).toList(),
          color: Colors.blue,
          width: 4,
        ),
      } : {},
    );
  }

  @override
  Future<double> calculateDistance(LatLng from, LatLng to) async {
    // Utilise l'API Distance Matrix de Google
    const apiKey = 'VOTRE_CLE_GOOGLE_MAPS';
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/distancematrix/json'
      '?origins=${from.latitude},${from.longitude}'
      '&destinations=${to.latitude},${to.longitude}'
      '&key=$apiKey'
    );
    
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['rows'][0]['elements'][0]['distance']['value'] as num).toDouble();
    }
    
    // Fallback: Haversine
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, from, to);
  }

  @override
  Future<List<LatLng>> getRoute(LatLng from, LatLng to) async {
    // Utilise l'API Directions de Google
    const apiKey = 'VOTRE_CLE_GOOGLE_MAPS';
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=${from.latitude},${from.longitude}'
      '&destination=${to.latitude},${to.longitude}'
      '&key=$apiKey'
    );
    
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final points = data['routes'][0]['overview_polyline']['points'] as String;
      return _decodePolyline(points);
    }
    
    // Fallback: ligne droite
    return [from, to];
  }

  @override
  void dispose() {
    _controller?.dispose();
  }

  /// Décode une polyline encodée Google
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }
}
*/

// ============================================
// SERVICE PRINCIPAL (Singleton)
// ============================================

/// Service centralisé pour la gestion des cartes
/// Utilise le pattern Strategy pour switcher entre providers
class MapsService {
  static final MapsService _instance = MapsService._internal();
  factory MapsService() => _instance;
  MapsService._internal();

  // ============================================
  // CONFIGURATION (Changez ici pour migrer)
  // ============================================
  
  /// MIGRATION GOOGLE MAPS : Changez cette valeur à true
  /// Assurez-vous d'avoir décommenté GoogleMapsProvider au-dessus
  static const bool useGoogleMaps = false;  // 👈 Changez à true pour Google Maps

  /// Provider actif (OpenStreetMap par défaut)
  late final MapProvider _provider;

  /// Initialise le provider selon la config
  void initialize() {
    if (useGoogleMaps) {
      // _provider = GoogleMapsProvider();  // Décommenter quand prêt
      throw UnimplementedError(
        'Google Maps pas encore configuré. '
        'Suivez les instructions dans maps_service.dart'
      );
    } else {
      _provider = OpenStreetMapProvider();
    }
  }

  /// Provider actif (accessible depuis l'extérieur)
  MapProvider get provider => _provider;

  // ============================================
  // MÉTHODES UTILITAIRES
  // ============================================

  /// Calcule distance entre 2 points (en km)
  Future<double> calculateDistanceKm(LatLng from, LatLng to) async {
    final meters = await _provider.calculateDistance(from, to);
    return meters / 1000;
  }

  /// Obtient l'itinéraire entre 2 points
  Future<List<LatLng>> getRoute(LatLng from, LatLng to) async {
    return _provider.getRoute(from, to);
  }

  /// Trie une liste de destinations par distance (plus proche en premier)
  /// UTILISÉ POUR L'OPTIMISATION SIMPLE (MVP)
  Future<List<T>> sortByDistance<T>({
    required LatLng from,
    required List<T> destinations,
    required LatLng Function(T) getLatLng,
  }) async {
    // Calcule distances pour chaque destination
    final List<MapEntry<T, double>> withDistances = [];
    
    for (final dest in destinations) {
      final distance = await calculateDistanceKm(from, getLatLng(dest));
      withDistances.add(MapEntry(dest, distance));
    }
    
    // Trie par distance croissante
    withDistances.sort((a, b) => a.value.compareTo(b.value));
    
    return withDistances.map((e) => e.key).toList();
  }

  /// Calcule le centre géographique (centroid) d'une liste de points
  /// UTILE POUR : Centrer la carte sur plusieurs livraisons
  LatLng calculateCenter(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(0, 0);
    if (points.length == 1) return points.first;

    double x = 0, y = 0, z = 0;

    for (final point in points) {
      final lat = point.latitude * math.pi / 180;
      final lng = point.longitude * math.pi / 180;

      x += math.cos(lat) * math.cos(lng);
      y += math.cos(lat) * math.sin(lng);
      z += math.sin(lat);
    }

    final total = points.length;
    x /= total;
    y /= total;
    z /= total;

    final centralLng = math.atan2(y, x);
    final centralSqrt = math.sqrt(x * x + y * y);
    final centralLat = math.atan2(z, centralSqrt);

    return LatLng(
      centralLat * 180 / math.pi,
      centralLng * 180 / math.pi,
    );
  }

  /// Calcule le zoom approprié pour afficher tous les points
  /// UTILE POUR : Auto-zoom sur plusieurs livraisons
  double calculateZoom(List<LatLng> points, double mapWidthPx) {
    if (points.isEmpty) return 13;
    if (points.length == 1) return 15;

    // Trouve les limites
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final latDiff = maxLat - minLat;
    final lngDiff = maxLng - minLng;

    // Formule approximative pour le zoom
    final maxDiff = math.max(latDiff, lngDiff);
    final zoom = (math.log(360 / maxDiff) / math.ln2).floorToDouble();

    return zoom.clamp(1, 18);
  }

  /// Dispose les ressources
  void dispose() {
    _provider.dispose();
  }
}
