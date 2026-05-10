import 'package:dio/dio.dart';
import 'secure_network_service.dart';

/// Lightweight AWS Location Service client that proxies calls via API Gateway.
///
/// NOTE: For security and SigV4 signing reasons, this implementation expects
/// a backend endpoint behind `AWS_API_GATEWAY_URL` which forwards requests to
/// Amazon Location Service (maps, trackers) using AWS SDK or signed requests.
/// This avoids embedding AWS secret keys in the mobile client.

class AwsLocationService {
  final Dio _dio;
  final String apiBase;

  AwsLocationService({Dio? dio, required this.apiBase})
      : _dio = dio ?? SecureNetworkService.createPinnedDio(
          baseUrl: apiBase,
          certificateSha256: const String.fromEnvironment('API_GATEWAY_CERT_SHA256', defaultValue: ''),
          pinnedHosts: {
            if (Uri.tryParse(apiBase)?.host.isNotEmpty == true) Uri.parse(apiBase).host,
          },
        );

  /// Request a map tile via the backend proxy.
  /// `z/x/y` tile coordinates or style-specific path is passed to backend.
  Future<Response> getMapTile(String mapName, int z, int x, int y) async {
    final url = '$apiBase/location/getMapTile';
    final resp = await _dio.get(url, queryParameters: {'mapName': mapName, 'z': z, 'x': x, 'y': y}, options: Options(responseType: ResponseType.bytes));
    return resp;
  }

  /// Send tracker position to backend, which forwards to Amazon Location Tracker
  Future<Response> putTrackerPosition(String trackerName, String deviceId, double lat, double lon) async {
    final url = '$apiBase/location/putTrackerPosition';
    final resp = await _dio.post(url, data: {'trackerName': trackerName, 'deviceId': deviceId, 'position': {'lat': lat, 'lon': lon}});
    return resp;
  }
}
