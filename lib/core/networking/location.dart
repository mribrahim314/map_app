import 'package:geolocator/geolocator.dart';

Future<List<double>> getCurrentLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Check if location services are enabled
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled, return an error
    throw Exception('Location services are disabled.');
  }

  // Check permission status
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied
      throw Exception('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are permanently denied
    throw Exception('Location permissions are permanently denied');
  }

  // Everything is fine, get the current position
  Position position = await Geolocator.getCurrentPosition();
  return [position.longitude, position.latitude];
}
