
import 'package:geolocator/geolocator.dart';

class LocationService {
  // Vérifier permissions
  static Future<bool> checkPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    return permission == LocationPermission.always ||
           permission == LocationPermission.whileInUse;
  }
  
  // Obtenir position actuelle
  static Future<Position?> getCurrentPosition() async {
    if (!await checkPermissions()) return null;
    
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
  
  // Écouter position en temps réel (pour transporteurs)
  static Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Mise à jour tous les 10m
      ),
    );
  }
  
  // Calculer distance entre 2 points
  static double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // en km
  }
}
