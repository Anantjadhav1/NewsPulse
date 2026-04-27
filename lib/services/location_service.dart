import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  // Get current GPS position
  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition();
  }

  // Save city manually
  Future<void> saveCity(String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_city', city);
    await prefs.setString('user_country', 'in');
  }

  // Get saved city
  Future<String> getSavedCity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_city') ?? '';
  }

  // Get news query from location
  Future<String> getLocationQuery() async {
    final prefs = await SharedPreferences.getInstance();
    final city = prefs.getString('user_city') ?? '';
    return city.isNotEmpty ? city : 'India';
  }

  // Save location from GPS coordinates
  Future<void> saveLocationFromGPS(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('user_lat', lat);
    await prefs.setDouble('user_lng', lng);
  }

  // Check if location is set
  Future<bool> isLocationSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_city') != null;
  }
}