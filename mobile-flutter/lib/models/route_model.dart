import 'package:google_maps_flutter/google_maps_flutter.dart';

class LatLngPoint {
  final double latitude;
  final double longitude;

  LatLngPoint({required this.latitude, required this.longitude});

  factory LatLngPoint.fromJson(Map<String, dynamic> json) {
    return LatLngPoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  LatLng toGoogleLatLng() => LatLng(latitude, longitude);
}

class SegmentAnalysisModel {
  final int segmentIndex;
  final LatLngPoint coordinate;
  final double crimeScore;
  final double lightingScore;
  final double crowdScore;
  final double lightingDeficit;
  final double crowdDeficit;
  final double timeFactor;
  final double rawSegmentCost;
  final int nearbyCrimesCount;
  final int nearbyRatingsCount;
  final bool isColdStart;

  SegmentAnalysisModel({
    required this.segmentIndex,
    required this.coordinate,
    required this.crimeScore,
    required this.lightingScore,
    required this.crowdScore,
    required this.lightingDeficit,
    required this.crowdDeficit,
    required this.timeFactor,
    required this.rawSegmentCost,
    required this.nearbyCrimesCount,
    required this.nearbyRatingsCount,
    required this.isColdStart,
  });

  factory SegmentAnalysisModel.fromJson(Map<String, dynamic> json) {
    return SegmentAnalysisModel(
      segmentIndex: json['segment_index'] ?? 0,
      coordinate: LatLngPoint.fromJson(json['coordinate'] ?? {'latitude': 0.0, 'longitude': 0.0}),
      crimeScore: (json['crime_score'] as num?)?.toDouble() ?? 0.0,
      lightingScore: (json['lighting_score'] as num?)?.toDouble() ?? 3.0,
      crowdScore: (json['crowd_score'] as num?)?.toDouble() ?? 3.0,
      lightingDeficit: (json['lighting_deficit'] as num?)?.toDouble() ?? 0.0,
      crowdDeficit: (json['crowd_deficit'] as num?)?.toDouble() ?? 0.0,
      timeFactor: (json['time_factor'] as num?)?.toDouble() ?? 1.0,
      rawSegmentCost: (json['raw_segment_cost'] as num?)?.toDouble() ?? 0.0,
      nearbyCrimesCount: json['nearby_crimes_count'] ?? 0,
      nearbyRatingsCount: json['nearby_ratings_count'] ?? 0,
      isColdStart: json['is_cold_start'] ?? false,
    );
  }
}

class RouteRecommendationModel {
  final String sessionId;
  final int safestRouteIndex;
  final String routeSummary;
  final double compositeRiskScore;
  final double safetyRating;
  final double totalDistanceMeters;
  final List<LatLng> recommendedPolyline;
  final List<LatLng> alternatePolyline;
  final List<SegmentAnalysisModel> detailedSegmentAnalysis;

  RouteRecommendationModel({
    required this.sessionId,
    required this.safestRouteIndex,
    required this.routeSummary,
    required this.compositeRiskScore,
    required this.safetyRating,
    required this.totalDistanceMeters,
    required this.recommendedPolyline,
    required this.alternatePolyline,
    required this.detailedSegmentAnalysis,
  });

  factory RouteRecommendationModel.fromJson(Map<String, dynamic> json) {
    List<LatLng> mainPoly = [];

    // Helper to safely extract LatLng from various coordinate representations
    LatLng? parsePoint(dynamic pt) {
      if (pt == null) return null;
      if (pt is LatLng) return pt;
      if (pt is List && pt.length >= 2) {
        // Mapbox / GeoJSON format: [longitude, latitude]
        final double lng = (pt[0] as num).toDouble();
        final double lat = (pt[1] as num).toDouble();
        return LatLng(lat, lng);
      }
      if (pt is Map) {
        final latVal = pt['latitude'] ?? pt['lat'];
        final lngVal = pt['longitude'] ?? pt['lng'] ?? pt['lon'];
        if (latVal != null && lngVal != null) {
          return LatLng((latVal as num).toDouble(), (lngVal as num).toDouble());
        }
      }
      return null;
    }

    if (json['recommendedPolyline'] != null) {
      for (var pt in json['recommendedPolyline']) {
        final p = parsePoint(pt);
        if (p != null) mainPoly.add(p);
      }
    } else if (json['routes'] != null && (json['routes'] as List).isNotEmpty) {
      // Direct Mapbox GeoJSON response structure
      final primary = json['routes'][0];
      if (primary['geometry'] != null && primary['geometry']['coordinates'] != null) {
        for (var pt in primary['geometry']['coordinates']) {
          final p = parsePoint(pt);
          if (p != null) mainPoly.add(p);
        }
      }
    }

    List<LatLng> altPoly = [];
    if (json['alternatePolyline'] != null && (json['alternatePolyline'] as List).isNotEmpty) {
      for (var pt in json['alternatePolyline']) {
        final p = parsePoint(pt);
        if (p != null) altPoly.add(p);
      }
    } else if (json['allEvaluatedRoutes'] != null && (json['allEvaluatedRoutes'] as List).isNotEmpty) {
      var allRoutes = json['allEvaluatedRoutes'] as List;
      // Pick second candidate if present for alternative polyline visualization
      int altIndex = allRoutes.length > 1 ? (json['safestRouteIndex'] == 0 ? 1 : 0) : 0;
      var candidate = allRoutes[altIndex];
      if (candidate['coordinates'] != null) {
        for (var pt in candidate['coordinates']) {
          final p = parsePoint(pt);
          if (p != null) altPoly.add(p);
        }
      } else if (candidate['detailed_segment_analysis'] != null) {
        for (var seg in candidate['detailed_segment_analysis']) {
          var coord = seg['coordinate'];
          if (coord != null) {
            final p = parsePoint(coord);
            if (p != null) altPoly.add(p);
          }
        }
      }
    } else if (json['routes'] != null && (json['routes'] as List).length > 1) {
      final alt = json['routes'][1];
      if (alt['geometry'] != null && alt['geometry']['coordinates'] != null) {
        for (var pt in alt['geometry']['coordinates']) {
          final p = parsePoint(pt);
          if (p != null) altPoly.add(p);
        }
      }
    }

    List<SegmentAnalysisModel> segments = [];
    if (json['detailedSegmentAnalysis'] != null) {
      for (var seg in json['detailedSegmentAnalysis']) {
        segments.add(SegmentAnalysisModel.fromJson(seg));
      }
    }

    return RouteRecommendationModel(
      sessionId: json['sessionId'] ?? '',
      safestRouteIndex: json['safestRouteIndex'] ?? 0,
      routeSummary: json['routeSummary'] ?? 'Safest Evaluated Corridor',
      compositeRiskScore: (json['compositeRiskScore'] as num?)?.toDouble() ?? 2.5,
      safetyRating: (json['safetyRating'] as num?)?.toDouble() ?? 4.5,
      totalDistanceMeters: (json['totalDistanceMeters'] as num?)?.toDouble() ?? 0.0,
      recommendedPolyline: mainPoly,
      alternatePolyline: altPoly,
      detailedSegmentAnalysis: segments,
    );
  }

  String get formattedDistance {
    if (totalDistanceMeters >= 1000) {
      return '${(totalDistanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '${totalDistanceMeters.toStringAsFixed(0)} m';
  }

  String get estimatedWalkingTime {
    return estimatedTimeForMode('walking');
  }

  String estimatedTimeForMode(String mode) {
    double speedMpm;
    if (mode == 'walking') {
      speedMpm = 80.0; // 4.8 km/h
    } else if (mode == 'two_wheeler') {
      speedMpm = 450.0; // ~27 km/h
    } else {
      speedMpm = 600.0; // ~36 km/h driving
    }

    int minutes = (totalDistanceMeters / speedMpm).ceil();
    if (minutes < 1) minutes = 1;
    if (minutes > 60) {
      int hrs = minutes ~/ 60;
      int rem = minutes % 60;
      return rem > 0 ? '$hrs hr $rem min' : '$hrs hr';
    }
    return '$minutes min';
  }
}
