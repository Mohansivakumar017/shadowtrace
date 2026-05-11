import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class TrafficData {
  final String congestionLevel;
  final int? currentSpeed;
  final int? speedLimit;
  final int safetyScore;
  final List<String> recommendations;

  TrafficData({
    required this.congestionLevel,
    this.currentSpeed,
    this.speedLimit,
    required this.safetyScore,
    required this.recommendations,
  });

  factory TrafficData.fromJson(Map<String, dynamic> json) {
    return TrafficData(
      congestionLevel: json['traffic']?['congestion'] ?? 'unknown',
      currentSpeed: json['traffic']?['currentSpeed'] as int?,
      speedLimit: json['traffic']?['speedLimit'] as int?,
      safetyScore: json['routeSafetyScore'] ?? 85,
      recommendations: List<String>.from(json['recommendations'] ?? []),
    );
  }
}

class TrafficService {
  static final TrafficService _instance = TrafficService._internal();

  factory TrafficService() {
    return _instance;
  }

  TrafficService._internal();

  Future<TrafficData> getTrafficData(
    double lat,
    double lng,
    String? authToken,
  ) async {
    try {
      if (authToken == null) {
        return TrafficData(
          congestionLevel: 'unknown',
          safetyScore: 85,
          recommendations: ['Unable to fetch traffic data without authentication'],
        );
      }

      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/traffic/$lat/$lng'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return TrafficData.fromJson(jsonDecode(response.body));
      }

      return TrafficData(
        congestionLevel: 'unknown',
        safetyScore: 85,
        recommendations: ['Unable to fetch traffic data'],
      );
    } catch (e) {
      debugPrint('Traffic service error: $e');
      return TrafficData(
        congestionLevel: 'unknown',
        safetyScore: 85,
        recommendations: ['Traffic service unavailable'],
      );
    }
  }

  Future<TrafficData?> getRouteTrafficAnalysis(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
    String? authToken,
  ) async {
    try {
      if (authToken == null) return null;

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/route_calc'),
        headers: {
          'Authorization': 'Bearer $authToken',
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
        return TrafficData.fromJson(jsonDecode(response.body));
      }

      return null;
    } catch (e) {
      debugPrint('Route traffic analysis error: $e');
      return null;
    }
  }

  bool isSafeTrafficCondition(int safetyScore) {
    return safetyScore >= 70;
  }

  String getTrafficWarning(String congestionLevel) {
    switch (congestionLevel) {
      case 'severe':
        return 'Heavy traffic detected - expect significant delays';
      case 'moderate':
        return 'Moderate traffic on this route';
      case 'light':
        return 'Light traffic conditions';
      case 'free-flow':
        return 'Clear road conditions';
      default:
        return 'Traffic data unavailable';
    }
  }
}
