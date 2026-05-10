import 'package:dio/dio.dart';
import 'secure_network_service.dart';

class OpenAiService {
  final Dio _dio;

  OpenAiService({Dio? dio})
      : _dio = dio ?? SecureNetworkService.createPinnedDio(
          baseUrl: const String.fromEnvironment('OPENAI_BACKEND_PROXY_URL', defaultValue: ''),
          certificateSha256: const String.fromEnvironment('API_GATEWAY_CERT_SHA256', defaultValue: ''),
        );

  Future<String> sendMessage(List<Map<String, String>> messages) async {
    final response = await _dio.post(
      '/ai_request',
      data: {
        'messages': messages,
      },
    );
    final content = response.data['reply'] as String?;
    return content?.trim() ?? '';
  }
}
