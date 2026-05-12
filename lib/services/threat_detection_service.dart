import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';
import 'sos_service.dart';

enum ThreatLevel { low, medium, high }

class ThreatResult {
  final ThreatLevel level;
  final String type;
  final double confidence;
  final String reason;

  const ThreatResult({
    required this.level,
    required this.type,
    required this.confidence,
    required this.reason,
  });

  factory ThreatResult.fromJson(Map<String, dynamic> json) {
    return ThreatResult(
      level: json['threatLevel'] == 'HIGH'
          ? ThreatLevel.high
          : json['threatLevel'] == 'MEDIUM'
          ? ThreatLevel.medium
          : ThreatLevel.low,
      type: json['threatType'] ?? 'unknown',
      confidence: (json['confidence'] ?? 0.5).toDouble(),
      reason: json['reason'] ?? '',
    );
  }
}

final threatProvider =
    StateNotifierProvider<ThreatNotifier, ThreatResult>((ref) {
  return ThreatNotifier(ref);
});

class ThreatNotifier extends StateNotifier<ThreatResult> {
  final Ref _ref;
  Timer? _classifyTimer;
  final List<Map<String, dynamic>> _locationHistory = [];

  ThreatNotifier(this._ref)
      : super(const ThreatResult(
          level: ThreatLevel.low,
          type: 'normal',
          confidence: 1.0,
          reason: 'Starting',
        ));

  void startMonitoring(String tripId, String userId) {
    _classifyTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _runClassification(tripId, userId);
    });
  }

  void addLocationPoint(double lat, double lng, {int? stallSeconds}) {
    _locationHistory.add({
      'lat': lat,
      'lng': lng,
      'timestamp': DateTime.now().toIso8601String(),
      'stallSeconds': stallSeconds ?? 0,
    });
    if (_locationHistory.length > 20) _locationHistory.removeAt(0);
  }

  Future<void> _runClassification(String tripId, String userId) async {
    if (_locationHistory.length < 3) return;

    try {
      final token = await AuthService().getCurrentJwt();
      if (token == null || token.isEmpty) return;

      final response = await http.post(
        Uri.parse('${AppConfig.locationApiBase}/ai-threat-classify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'tripId': tripId,
          'userId': userId,
          'locationHistory': List.from(_locationHistory),
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final result = ThreatResult.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
        state = result;

        // Auto-trigger SOS if HIGH confidence threat
        if (result.level == ThreatLevel.high && result.confidence >= 0.80) {
          final last = _locationHistory.last;
          await SosService().triggerSOS(
            userId: userId,
            tripId: tripId,
            triggerType: 'ai_detected',
            lat: last['lat'] as double,
            lng: last['lng'] as double,
          );
        }
      }
    } catch (e) {
      debugPrint('Threat classification error: $e');
    }
  }

  void stopMonitoring() {
    _classifyTimer?.cancel();
    _locationHistory.clear();
  }
}
