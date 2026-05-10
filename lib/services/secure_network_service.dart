import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:crypto/crypto.dart';

class SecureNetworkService {
  SecureNetworkService._();

  static Dio createPinnedDio({required String baseUrl, String? certificateSha256, Set<String>? pinnedHosts}) {
    final dio = Dio(BaseOptions(baseUrl: baseUrl));
    final adapter = IOHttpClientAdapter();

    adapter.createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (X509Certificate cert, String host, int port) {
        if (pinnedHosts != null && !pinnedHosts.contains(host)) {
          return false;
        }

        if (certificateSha256 == null || certificateSha256.isEmpty) {
          return false;
        }

        final derBytes = utf8.encode(cert.pem);
        final digest = sha256.convert(derBytes).toString();
        return digest.toLowerCase() == certificateSha256.toLowerCase();
      };
      return client;
    };

    dio.httpClientAdapter = adapter;
    return dio;
  }
}
