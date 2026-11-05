import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'web_location_stub.dart'
    if (dart.library.html) 'web_location_web.dart';

class WebLocationHelper {
  static Future<LatLng?> getCurrentPosition() => getWebCurrentPosition();
}

