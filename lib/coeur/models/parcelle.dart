import 'package:latlong2/latlong.dart';

class Parcelle {
  final String id;
  final String producteurId;
  final String nom;
  final double surface; // en hectares
  final String typeSol;
  final LatLng coordonnees;
  final DateTime createdAt;
  final DateTime updatedAt;

  Parcelle({
    required this.id,
    required this.producteurId,
    required this.nom,
    required this.surface,
    required this.typeSol,
    required this.coordonnees,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Parcelle.fromJson(Map<String, dynamic> json) {
    final coords = json['coordonnees'];
    LatLng latLng;
    if (coords is Map && coords['type'] == 'Point') {
      final coordinates = coords['coordinates'] as List;
      latLng = LatLng(coordinates[1], coordinates[0]);
    } else {
      latLng = const LatLng(0, 0);
    }

    return Parcelle(
      id: json['id'],
      producteurId: json['producteur_id'],
      nom: json['nom'],
      surface: (json['surface'] as num).toDouble(),
      typeSol: json['type_sol'],
      coordonnees: latLng,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'producteur_id': producteurId,
      'nom': nom,
      'surface': surface,
      'type_sol': typeSol,
      'coordonnees': {
        'type': 'Point',
        'coordinates': [coordonnees.longitude, coordonnees.latitude]
      },
    };
  }
}
