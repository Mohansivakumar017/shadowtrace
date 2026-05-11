import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:amplify_flutter/amplify_flutter.dart';
import '../config/app_config.dart';

class RouteService {
  static final RouteService _instance = RouteService._internal();

  factory RouteService() {
    return _instance;
  }

  RouteService._internal();

  Future<Map<String, dynamic>?> startTrip(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (!session.isSignedIn) {
        throw Exception('User not authenticated');
      }

      final idToken = _getTokenString(session);

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/route'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'originLat': originLat,
          'originLng': originLng,
          'destLat': destLat,
          'destLng': destLng,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Route calculation failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Route calculation error: $e');
      return null;
    }
  }

  Future<bool> endTrip(String tripId) async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (!session.isSignedIn) {
        throw Exception('User not authenticated');
      }

      final idToken = _getTokenString(session);

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/trip/end'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'tripId': tripId}),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('End trip error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getDevicePosition(String userId) async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (!session.isSignedIn) {
        throw Exception('User not authenticated');
      }

      final idToken = _getTokenString(session);

      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/device-position/$userId'),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Get device position error: $e');
      return null;
    }
  }

  String _getTokenString(dynamic session) {
    try {
      return (session as dynamic).amplifyUserPoolTokens?.idToken?.toString() ?? "";
    } catch (_) {
      return "";
    }
  }
}
