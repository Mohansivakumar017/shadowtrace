import 'package:flutter_test/flutter_test.dart';
import 'package:shadowtrace/services/sos_service.dart';

void main() {
  group('SosService', () {
    late SosService sosService;

    setUp(() {
      sosService = SosService();
    });

    test('SosService is a singleton', () {
      final instance1 = SosService();
      final instance2 = SosService();
      expect(identical(instance1, instance2), true);
    });

    test('triggerVoiceSOS can be called with required parameters', () async {
      expect(
        () => sosService.triggerVoiceSOS(
          'test-user',
          lat: 37.7749,
          lng: -122.4194,
        ),
        isA<Future>(),
      );
    });

    test('triggerSilentSOS can be called with required parameters', () async {
      expect(
        () => sosService.triggerSilentSOS(
          'test-user',
          lat: 37.7749,
          lng: -122.4194,
        ),
        isA<Future>(),
      );
    });

    test('respondToAlert has required parameters', () async {
      expect(
        () => sosService.respondToAlert(
          alertId: 'alert-123',
          responderId: 'responder-456',
          response: 'ACCEPTED',
        ),
        isA<Future>(),
      );
    });
  });
}
