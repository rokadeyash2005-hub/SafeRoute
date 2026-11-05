import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'web_location.dart';

class PositionResult {
  final LatLng location;
  final bool isLiveGps;

  const PositionResult({required this.location, required this.isLiveGps});
}

class LocationService {
  // Default fallback starting location: Sanjivani College of Engineering, Kopargaon, Maharashtra
  static const LatLng defaultLocation = LatLng(19.8856, 74.4789);

  /// Requests permission properly on startup and returns live GPS coordinates.
  /// On Web, calls dart:html window.navigator.geolocation.getCurrentPosition() directly.
  /// On Mobile / fallback, uses Geolocator.getCurrentPosition().
  /// Prints the live coordinates or exact error string in debug console.
  static Future<PositionResult> determinePosition() async {
    // 1. Web-first direct Geolocation via dart:html
    if (kIsWeb) {
      try {
        final webLatLng = await WebLocationHelper.getCurrentPosition();
        if (webLatLng != null) {
          return PositionResult(location: webLatLng, isLiveGps: true);
        }
      } catch (webErr) {
        // ignore: avoid_print
        print(">>> GEOLOCATION ERROR (Web Geolocation API): $webErr");
      }
    }

    // 2. Fallback / Mobile Geolocator Plugin
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // ignore: avoid_print
        print(">>> GEOLOCATION ERROR: Location services are disabled on device");
        return const PositionResult(location: defaultLocation, isLiveGps: false);
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        // ignore: avoid_print
        print(">>> GEOLOCATION ERROR: Location permission is denied ($permission)");
        return const PositionResult(location: defaultLocation, isLiveGps: false);
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // ignore: avoid_print
      print(">>> LIVE GPS FETCHED: ${position.latitude}, ${position.longitude}");
      return PositionResult(
        location: LatLng(position.latitude, position.longitude),
        isLiveGps: true,
      );
    } catch (e) {
      // ignore: avoid_print
      print(">>> GEOLOCATION ERROR (Geolocator): $e");
      return const PositionResult(location: defaultLocation, isLiveGps: false);
    }
  }
}
