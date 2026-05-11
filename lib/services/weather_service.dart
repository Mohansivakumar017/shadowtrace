import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:amplify_flutter/amplify_flutter.dart';
import '../config/app_config.dart';

class WeatherService {
  static final WeatherService _instance = WeatherService._internal();

  factory WeatherService() {
    return _instance;
  }

  WeatherService._internal();

  Future<Map<String, dynamic>> getCurrentWeather(double lat, double lng) async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (!session.isSignedIn) {
        return {'error': 'User not authenticated'};
      }

      final idToken = _getTokenString(session);
      final uri = Uri.parse(AppConfig.weatherDataEndpoint)
          .replace(queryParameters: {
        'lat': lat.toString(),
        'lng': lng.toString(),
      });

      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $idToken',
      });

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {
        'error': 'Failed to fetch weather',
        'status': response.statusCode
      };
    } catch (e) {
      debugPrint('Weather service error: $e');
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getRouteForecast({
    required List<Map<String, double>> waypoints,
    required String departureTime,
  }) async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (!session.isSignedIn) {
        return {'error': 'User not authenticated'};
      }

      final idToken = _getTokenString(session);
      final response = await http.post(
        Uri.parse(AppConfig.weatherForecastEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'waypoints': waypoints,
          'departureTime': departureTime,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {
        'error': 'Forecast failed',
        'status': response.statusCode
      };
    } catch (e) {
      debugPrint('Forecast service error: $e');
      return {'error': e.toString()};
    }
  }

  bool isHazardous(Map<String, dynamic> weatherData) {
    final condition = weatherData['condition']?.toString().toLowerCase() ?? '';
    const hazards = [
      'thunderstorm',
      'snow',
      'tornado',
      'squall',
      'flood',
      'hail'
    ];
    return hazards.any((h) => condition.contains(h));
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
