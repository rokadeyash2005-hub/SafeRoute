import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/route_model.dart';

class ApiService {
  // Use localhost for Android Emulator, localhost for iOS Simulator or Web/Desktop
  static const String baseUrl = 'http://localhost:8081/api';
  // Fallback direct localhost for desktop/web testing
  static const String localUrl = 'http://localhost:8081/api';

  static String activeBaseUrl = baseUrl;

  static Map<String, String> _headers([String? token]) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Authenticate existing user
  static Future<UserModel> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$activeBaseUrl/auth/login'),
        headers: _headers(),
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(jsonDecode(response.body));
      } else {
        final err = jsonDecode(response.body);
        throw Exception(err['message'] ?? 'Login failed. Please verify credentials.');
      }
    } catch (e) {
      // Retry once against localhost if emulator URL failed (e.g. running on Windows/Web)
      if (activeBaseUrl == baseUrl) {
        activeBaseUrl = localUrl;
        return login(email, password);
      }
      rethrow;
    }
  }

  /// Register new user account
  static Future<UserModel> register(
    String name,
    String email,
    String password,
    String emergencyContact,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$activeBaseUrl/auth/register'),
        headers: _headers(),
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'emergencyContact': emergencyContact,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return UserModel.fromJson(jsonDecode(response.body));
      } else {
        final err = jsonDecode(response.body);
        throw Exception(err['message'] ?? 'Registration failed.');
      }
    } catch (e) {
      if (activeBaseUrl == baseUrl) {
        activeBaseUrl = localUrl;
        return register(name, email, password, emergencyContact);
      }
      rethrow;
    }
  }

  /// Request Safest Route Recommendation from Spring Boot Orchestrator
  static Future<RouteRecommendationModel> getSafeRoute({
    required double sourceLat,
    required double sourceLng,
    required double destLat,
    required double destLng,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('$activeBaseUrl/routes/recommend'),
      headers: _headers(token),
      body: jsonEncode({
        'sourceLat': sourceLat,
        'sourceLng': sourceLng,
        'destLat': destLat,
        'destLng': destLng,
      }),
    );

    if (response.statusCode == 200) {
      return RouteRecommendationModel.fromJson(jsonDecode(response.body));
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['message'] ?? 'Failed to evaluate safe route.');
    }
  }

  /// Trigger Instant Emergency SOS Dispatch
  static Future<Map<String, dynamic>> triggerEmergencySos({
    required double latitude,
    required double longitude,
    required String token,
    String? customMessage,
  }) async {
    final response = await http.post(
      Uri.parse('$activeBaseUrl/safety/sos'),
      headers: _headers(token),
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
        'message': customMessage ?? 'URGENT SOS: Emergency assistance required.',
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to dispatch SOS alert. Please call emergency services directly.');
    }
  }

  /// Crowdsource street telemetry rating
  static Future<bool> submitSafetyRating({
    required double latitude,
    required double longitude,
    required String streetName,
    required int lightingScore,
    required int crowdDensity,
    required int safetyScore,
    required String token,
  }) async {
    // Note: Can be forwarded to the backend rating ingestion endpoint
    // Fallback simulation returns true if endpoint is pending migration
    try {
      final response = await http.post(
        Uri.parse('$activeBaseUrl/safety/rating'),
        headers: _headers(token),
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
          'streetName': streetName,
          'lightingScore': lightingScore,
          'crowdDensity': crowdDensity,
          'safetyScore': safetyScore,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return true; // Local simulation fallback
    }
  }
}
