import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../services/secure_network_service.dart';

final fcmTokenProvider = StateNotifierProvider<FcmTokenNotifier, String?>((ref) => FcmTokenNotifier());

class FcmTokenNotifier extends StateNotifier<String?> {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final Dio _dio = SecureNetworkService.createPinnedDio(
    baseUrl: const String.fromEnvironment('AWS_API_GATEWAY_URL', defaultValue: ''),
    certificateSha256: const String.fromEnvironment('API_GATEWAY_CERT_SHA256', defaultValue: ''),
    pinnedHosts: {
      if (Uri.tryParse(const String.fromEnvironment('AWS_API_GATEWAY_URL', defaultValue: ''))?.host.isNotEmpty == true)
        Uri.parse(const String.fromEnvironment('AWS_API_GATEWAY_URL', defaultValue: '')).host,
    },
  );

  FcmTokenNotifier(): super(null) {
    _init();
  }

  Future<void> _init() async {
    try {
      final token = await _messaging.getToken();
      state = token;
      if (token != null) await _uploadToken(token);

      FirebaseMessaging.onTokenRefresh.listen((newToken) async {
        state = newToken;
        if (newToken != null) await _uploadToken(newToken);
      });
    } catch (e) {
      // ignore errors for now
    }
  }

  Future<void> _uploadToken(String token) async {
    final api = const String.fromEnvironment('AWS_API_GATEWAY_URL', defaultValue: '');
    if (api.isEmpty) return;
    try {
      await _dio.post('$api/registerDeviceToken', data: {'token': token});
    } catch (e) {
      // ignore upload error; will retry on token refresh
    }
  }
}
