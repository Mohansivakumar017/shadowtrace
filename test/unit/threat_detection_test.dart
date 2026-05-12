import 'package:flutter_test/flutter_test.dart';
import 'package:shadowtrace/services/threat_detection_service.dart';

void main() {
  group('ThreatDetectionService', () {
    test('ThreatResult.fromJson parses HIGH threat level correctly', () {
      final json = {
        'threatLevel': 'HIGH',
        'threatType': 'prolonged_inactivity',
        'confidence': 0.92,
        'reason': 'No movement for 5 minutes',
      };

      final result = ThreatResult.fromJson(json);

      expect(result.level, ThreatLevel.high);
      expect(result.type, 'prolonged_inactivity');
      expect(result.confidence, 0.92);
    });

    test('ThreatResult.fromJson parses MEDIUM threat level correctly', () {
      final json = {
        'threatLevel': 'MEDIUM',
        'threatType': 'erratic_movement',
        'confidence': 0.70,
        'reason': 'Erratic movement detected',
      };

      final result = ThreatResult.fromJson(json);

      expect(result.level, ThreatLevel.medium);
      expect(result.type, 'erratic_movement');
      expect(result.confidence, 0.70);
    });

    test('ThreatResult.fromJson parses LOW threat level correctly', () {
      final json = {
        'threatLevel': 'LOW',
        'threatType': 'normal_movement',
        'confidence': 0.85,
        'reason': 'Movement patterns appear normal',
      };

      final result = ThreatResult.fromJson(json);

      expect(result.level, ThreatLevel.low);
      expect(result.type, 'normal_movement');
      expect(result.confidence, 0.85);
    });

    test('ThreatResult defaults to LOW when threatLevel is undefined', () {
      final json = {
        'threatType': 'unknown',
        'confidence': 0.5,
        'reason': 'Unknown classification',
      };

      final result = ThreatResult.fromJson(json);

      expect(result.level, ThreatLevel.low);
    });

    test('ThreatResult handles missing reason gracefully', () {
      final json = {
        'threatLevel': 'MEDIUM',
        'threatType': 'test_type',
        'confidence': 0.75,
      };

      final result = ThreatResult.fromJson(json);

      expect(result.reason, '');
      expect(result.confidence, 0.75);
    });
  });
}
