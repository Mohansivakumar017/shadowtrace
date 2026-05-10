import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:amplify_flutter/amplify_flutter.dart';
import '../config/app_config.dart';

class SOSService {
  static final SOSService _instance = SOSService._internal();

  factory SOSService() {
    return _instance;
  }

  SOSService._internal();

  Future<String?> triggerSOS(double lat, double lng) async {
    try {
      final session = await Amplify.Auth.getSession();
      if (!session.isSignedIn) {
        throw Exception('User not authenticated');
      }

      final idToken = session.userPoolTokens!.idToken.toString();

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/sos'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'lat': lat,
          'lng': lng,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['alertId'] as String?;
      } else {
        throw Exception('SOS trigger failed: ${response.statusCode}');
      }
    } catch (e) {
      print('SOS error: $e');
      return null;
    }
  }

  Future<void> triggerVoiceSOS() async {
    try {
      final location = await _getCurrentLocation();
      if (location != null) {
        await triggerSOS(location['lat'] as double, location['lng'] as double);
      }
    } catch (e) {
      print('Voice SOS error: $e');
    }
  }

  Future<bool> cancelAlert(String alertId) async {
    try {
      final session = await Amplify.Auth.getSession();
      if (!session.isSignedIn) {
        throw Exception('User not authenticated');
      }

      final idToken = session.userPoolTokens!.idToken.toString();

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/sos/cancel'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'alertId': alertId}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Cancel alert error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> _getCurrentLocation() async {
    try {
      final session = await Amplify.Auth.getSession();
      if (!session.isSignedIn) {
        return null;
      }

      final idToken = session.userPoolTokens!.idToken.toString();
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/device-position'),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'lat': data['lat'],
          'lng': data['lng'],
        };
      }
      return null;
    } catch (e) {
      print('Get location error: $e');
      return null;
    }
  }
}
