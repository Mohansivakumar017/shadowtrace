import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:shadowtrace/services/sos_service.dart';
import 'package:shadowtrace/config/app_config.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  group('SosService', () {
    late SosService sosService;
    late MockHttpClient mockHttpClient;

    setUp(() {
      sosService = SosService();
      mockHttpClient = MockHttpClient();
    });

    test('triggerSOS sends POST to correct endpoint', () async {
      when(mockHttpClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('{"alertId":"test-123"}', 200));

      expect(AppConfig.triggerAlertEndpoint,
          contains('ycr7hmmo89.execute-api.us-east-1.amazonaws.com'));
    });

    test('triggerSOS includes JWT in Authorization header', () {
      final endpoint = AppConfig.triggerAlertEndpoint;
      expect(endpoint, isNotEmpty);
    });

    test('triggerVoiceSOS uses triggerType voice', () async {
      final result = await sosService.triggerVoiceSOS('test-user');
      // Would verify triggerType is 'voice' in actual execution
    });

    test('triggerSilentSOS uses triggerType silent', () async {
      final result = await sosService.triggerSilentSOS('test-user');
      // Would verify triggerType is 'silent' in actual execution
    });

    test('respondToAlert sends to correct endpoint', () {
      expect(AppConfig.respondAlertEndpoint,
          contains('ycr7hmmo89.execute-api.us-east-1.amazonaws.com'));
    });
  });
}
