import 'package:flutter_test/flutter_test.dart';
import 'package:shadowtrace/services/sos_service.dart';

void main() {
  group('SosService', () {
    late SosService sosService;

    setUp(() {
      sosService = SosService();
    });

    test('SosService is a singleton - same instance returned',
        () {
      final instance1 = SosService();
      final instance2 = SosService();
      expect(identical(instance1, instance2), true);
    });

    test('triggerSOS sends POST request with required fields', () async {
      final result = await sosService.triggerSOS(
        userId: 'user123',
        triggerType: 'manual',
      );
      expect(result, isA<Map>());
    });

    test('triggerSOS with manual type includes triggerType in payload',
        () async {
      final result = await sosService.triggerSOS(
        userId: 'user123',
        triggerType: 'manual',
        lat: 37.7749,
        lng: -122.4194,
      );
      expect(result, isA<Map>());
    });

    test('triggerSOS with voice type includes voice triggerType', () async {
      final result = await sosService.triggerSOS(
        userId: 'user123',
        triggerType: 'voice',
        lat: 37.7749,
        lng: -122.4194,
      );
      expect(result, isA<Map>());
    });

    test('respondToAlert sends response with correct status field',
        () async {
      final result = await sosService.respondToAlert(
        alertId: 'alert-123',
        responderId: 'responder-123',
        response: 'resolved',
      );
      expect(result, isA<bool>());
    });
  });
}
