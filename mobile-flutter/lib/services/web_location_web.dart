// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use, avoid_print
import 'dart:html' as html;
import 'package:google_maps_flutter/google_maps_flutter.dart';

Future<LatLng?> getWebCurrentPosition() async {
  try {
    final pos = await html.window.navigator.geolocation.getCurrentPosition(
      enableHighAccuracy: true,
      timeout: const Duration(seconds: 10),
    );

    final coords = pos.coords;
    if (coords != null) {
      final num? lat = coords.latitude;
      final num? lng = coords.longitude;
      if (lat != null && lng != null) {
        final double latitude = lat.toDouble();
        final double longitude = lng.toDouble();
        print(">>> LIVE GPS FETCHED: $latitude, $longitude");
        return LatLng(latitude, longitude);
      }
    }
    print(">>> GEOLOCATION ERROR: Received empty coordinates from navigator.geolocation");
    return null;
  } catch (error) {
    print(">>> GEOLOCATION ERROR: $error");
    return null;
  }
}
