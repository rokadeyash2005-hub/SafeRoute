import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/route_model.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/mapbox_service.dart';

class NavigationProvider extends ChangeNotifier {
  GoogleMapController? _mapController;
  LatLng _currentLocation = LocationService.defaultLocation;
  LatLng? _destinationLocation;
  RouteRecommendationModel? _routeRecommendation;

  bool _isLoadingLocation = true;
  bool _isEvaluatingRoute = false;
  bool _isSosActive = false;
  bool _isNavigating = false;
  bool _isLiveLocationAcquired = false;
  String? _errorMessage;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  // Getters
  GoogleMapController? get mapController => _mapController;
  LatLng get currentLocation => _currentLocation;
  LatLng? get destinationLocation => _destinationLocation;
  RouteRecommendationModel? get routeRecommendation => _routeRecommendation;
  bool get isLoadingLocation => _isLoadingLocation;
  bool get isEvaluatingRoute => _isEvaluatingRoute;
  bool get isSosActive => _isSosActive;
  bool get isNavigating => _isNavigating;
  bool get isLiveLocationAcquired => _isLiveLocationAcquired;
  String? get errorMessage => _errorMessage;
  Set<Marker> get markers => _markers;
  Set<Polyline> get polylines => _polylines;

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
    controller.animateCamera(
      CameraUpdate.newLatLngZoom(_currentLocation, 15.0),
    );
  }

  Future<void> fetchCurrentLocation() async {
    _isLoadingLocation = true;
    notifyListeners();

    final result = await LocationService.determinePosition();
    _currentLocation = result.location;
    _isLiveLocationAcquired = result.isLiveGps;
    _isLoadingLocation = false;

    _updateCurrentLocationMarker();

    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation, 15.0),
      );
    }
    notifyListeners();
  }

  void _updateCurrentLocationMarker() {
    _markers.removeWhere((m) => m.markerId.value == 'user_location');
    _markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: _currentLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(
          title: _isLiveLocationAcquired ? 'Your Live Location' : 'Sanjivani College, Kopargaon',
          snippet: _isLiveLocationAcquired
              ? 'GPS: ${_currentLocation.latitude.toStringAsFixed(5)}, ${_currentLocation.longitude.toStringAsFixed(5)}'
              : 'Default fallback location',
        ),
      ),
    );
  }

  Future<bool> selectDestinationAndEvaluate({
    required LatLng destination,
    required String token,
    String? destinationTitle,
  }) async {
    _destinationLocation = destination;
    _isEvaluatingRoute = true;
    _errorMessage = null;
    notifyListeners();

    // Add destination marker
    _markers.removeWhere((m) => m.markerId.value == 'destination_location');
    _markers.add(
      Marker(
        markerId: const MarkerId('destination_location'),
        position: destination,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: destinationTitle ?? 'Selected Destination',
          snippet: 'Destination Pin',
        ),
      ),
    );

    RouteRecommendationModel? rec;

    // Step 1: Query Spring Boot Orchestrator (which uses Mapbox + FastAPI ML scoring)
    try {
      rec = await ApiService.getSafeRoute(
        sourceLat: _currentLocation.latitude,
        sourceLng: _currentLocation.longitude,
        destLat: destination.latitude,
        destLng: destination.longitude,
        token: token,
      );
    } catch (backendError) {
      debugPrint('Spring Boot backend routing unavailable: $backendError. Falling back to direct Mapbox Directions.');
    }

    // Step 2: Fall back to direct Mapbox Directions API if needed
    // (If backend was offline OR returned a simulated straight chord with < 5 coordinates)
    if (rec == null || rec.recommendedPolyline.length < 5) {
      try {
        final mapboxRec = await MapboxService.fetchDirections(
          startLat: _currentLocation.latitude,
          startLng: _currentLocation.longitude,
          endLat: destination.latitude,
          endLng: destination.longitude,
        );

        if (rec != null) {
          // If backend returned risk metrics but lacked complete road waypoints,
          // overlay Mapbox's full turn-by-turn road geometry.
          rec = RouteRecommendationModel(
            sessionId: rec.sessionId,
            safestRouteIndex: rec.safestRouteIndex,
            routeSummary: rec.routeSummary,
            compositeRiskScore: rec.compositeRiskScore,
            safetyRating: rec.safetyRating,
            totalDistanceMeters: mapboxRec.totalDistanceMeters > 0
                ? mapboxRec.totalDistanceMeters
                : rec.totalDistanceMeters,
            recommendedPolyline: mapboxRec.recommendedPolyline,
            alternatePolyline: mapboxRec.alternatePolyline.isNotEmpty
                ? mapboxRec.alternatePolyline
                : rec.alternatePolyline,
            detailedSegmentAnalysis: rec.detailedSegmentAnalysis,
          );
        } else {
          rec = mapboxRec;
        }
      } catch (mapboxError) {
        if (rec == null) {
          _isEvaluatingRoute = false;
          _errorMessage = mapboxError.toString().replaceAll('Exception: ', '');
          notifyListeners();
          return false;
        }
      }
    }

    _routeRecommendation = rec;

    // Step 4: Render complete road waypoints into GoogleMap polylines
    _buildRoutePolylines(rec);

    // Fit map camera to bounds of both origin, destination, and all road waypoints
    _fitMapToBounds(
      _currentLocation,
      destination,
      routePoints: rec.recommendedPolyline,
    );

    _isEvaluatingRoute = false;
    notifyListeners();
    return true;
  }

  void _buildRoutePolylines(RouteRecommendationModel rec) {
    _polylines.clear();

    if (rec.recommendedPolyline.isNotEmpty) {
      // 1a. Casing border polyline (crisp dark outline for Google Maps aesthetic)
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('safest_route_casing'),
          points: rec.recommendedPolyline,
          color: const Color(0xFF00381B), // Dark emerald border
          width: 9,
          zIndex: 10,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );

      // 1b. Vibrant inner core polyline (vivid safety emerald green)
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('safest_route_core'),
          points: rec.recommendedPolyline,
          color: const Color(0xFF00E676), // Bright vivid safety green
          width: 6,
          zIndex: 11,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );
    }

    // 2. ALTERNATIVE ROUTE: Slate grey dashed line following alternate road path
    if (rec.alternatePolyline.isNotEmpty) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('alternate_route'),
          points: rec.alternatePolyline,
          color: const Color(0xFF78909C), // Slate grey
          width: 4,
          zIndex: 5,
          patterns: [PatternItem.dash(18), PatternItem.gap(10)],
        ),
      );
    }
  }

  void _fitMapToBounds(LatLng p1, LatLng p2, {List<LatLng>? routePoints}) {
    if (_mapController == null) return;

    double south = p1.latitude;
    double north = p1.latitude;
    double west = p1.longitude;
    double east = p1.longitude;

    final pointsToInclude = (routePoints != null && routePoints.isNotEmpty)
        ? routePoints
        : [p1, p2];

    for (final pt in pointsToInclude) {
      if (pt.latitude < south) south = pt.latitude;
      if (pt.latitude > north) north = pt.latitude;
      if (pt.longitude < west) west = pt.longitude;
      if (pt.longitude > east) east = pt.longitude;
    }

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(south - 0.005, west - 0.005),
      northeast: LatLng(north + 0.005, east + 0.005),
    );

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));
  }

  Future<Map<String, dynamic>> triggerEmergencySos(String token) async {
    _isSosActive = true;
    notifyListeners();

    try {
      final res = await ApiService.triggerEmergencySos(
        latitude: _currentLocation.latitude,
        longitude: _currentLocation.longitude,
        token: token,
      );
      _isSosActive = false;
      notifyListeners();
      return res;
    } catch (e) {
      _isSosActive = false;
      notifyListeners();
      rethrow;
    }
  }

  void startNavigation() {
    _isNavigating = true;
    notifyListeners();
  }

  void stopNavigation() {
    _isNavigating = false;
    notifyListeners();
  }

  void clearRoute() {
    _destinationLocation = null;
    _routeRecommendation = null;
    _polylines.clear();
    _markers.removeWhere((m) => m.markerId.value == 'destination_location');
    _isNavigating = false;
    notifyListeners();
  }
}
