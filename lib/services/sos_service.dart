import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:amplify_flutter/amplify_flutter.dart';
import '../config/app_config.dart';
import 'location_service.dart';

class SosService {
  static final SosService _instance = SosService._internal();
  final LocationService _locationService = LocationService();

  factory SosService() {
    return _instance;
  }

  SosService._internal();

  Future<Map<String, dynamic>> triggerSOS({
    required String userId,
    required String triggerType,
    String? tripId,
    double? lat,
    double? lng,
  }) async {
    try {
      double finalLat = lat ?? _locationService.getLastKnownPosition()?.latitude ?? 0.0;
      double finalLng = lng ?? _locationService.getLastKnownPosition()?.longitude ?? 0.0;

      if (finalLat == 0.0) {
        final pos = await Geolocator.getCurrentPosition();
        finalLat = pos.latitude;
        finalLng = pos.longitude;
      }

      final session = await Amplify.Auth.fetchAuthSession();
      if (!session.isSignedIn) {
        return {'error': 'User not authenticated', 'status': 401};
      }

      final idToken = _getTokenString(session);

      final response = await http.post(
        Uri.parse(AppConfig.triggerAlertEndpoint),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
          'tripId': tripId,
          'lat': finalLat,
          'lng': finalLng,
          'triggerType': triggerType,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {'error': 'SOS trigger failed', 'status': response.statusCode};
    } catch (e) {
      debugPrint('SOS error: $e');
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> triggerVoiceSOS(
    String userId, {
    String? tripId,
    double? lat,
    double? lng,
  }) {
    return triggerSOS(
      userId: userId,
      triggerType: 'voice',
      tripId: tripId,
      lat: lat,
      lng: lng,
    );
  }

  Future<Map<String, dynamic>> triggerSilentSOS(
    String userId, {
    String? tripId,
    double? lat,
    double? lng,
  }) {
    return triggerSOS(
      userId: userId,
      triggerType: 'silent',
      tripId: tripId,
      lat: lat,
      lng: lng,
    );
  }

  Future<bool> respondToAlert({
    required String alertId,
    required String responderId,
    required String response,
  }) async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (!session.isSignedIn) {
        return false;
      }

      final idToken = _getTokenString(session);
      final res = await http.post(
        Uri.parse(AppConfig.respondAlertEndpoint),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'alertId': alertId,
          'responderId': responderId,
          'response': response,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('respondToAlert error: $e');
      return false;
    }
  }

  String _getTokenString(dynamic session) {
    try {
      return (session as dynamic).amplifyUserPoolTokens?.idToken?.toString() ??
          "";
    } catch (_) {
      return "";
    }
  }
}
