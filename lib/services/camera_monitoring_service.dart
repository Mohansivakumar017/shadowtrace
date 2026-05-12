import 'dart:async';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../config/app_config.dart';
import 'auth_service.dart';

class CameraMonitoringService {
  CameraController? _controller;
  Timer? _captureTimer;
  bool _isMonitoring = false;
  String? _currentAlertId;

  Future<void> initialize() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('Camera: No cameras available');
        return;
      }

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _controller!.initialize();
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  Future<void> startMonitoring(String alertId) async {
    if (_isMonitoring) return;
    _isMonitoring = true;
    _currentAlertId = alertId;

    // Ensure camera is initialized
    if (_controller == null || !_controller!.value.isInitialized) {
      await initialize();
    }

    if (_controller == null) {
      debugPrint('Camera: Controller not initialized');
      _isMonitoring = false;
      return;
    }

    // Capture frame immediately
    await _captureAndUpload(alertId);

    // Then every 30 seconds
    _captureTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (_isMonitoring && _controller != null) {
        await _captureAndUpload(alertId);
      }
    });
  }

  Future<void> _captureAndUpload(String alertId) async {
    try {
      if (_controller == null || !_controller!.value.isInitialized) return;

      final dir = await getApplicationDocumentsDirectory();
      final imageFile = await _controller!.takePicture();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'frame_${alertId}_$timestamp.jpg';

      // Get pre-signed S3 URL from backend
      final token = await AuthService().getCurrentJwt();
      if (token == null || token.isEmpty) return;

      final urlResponse = await http.post(
        Uri.parse(AppConfig.audioStreamEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'alertId': alertId,
          'type': 'camera',
          'fileName': fileName,
          'contentType': 'image/jpeg',
        }),
      ).timeout(const Duration(seconds: 10));

      if (urlResponse.statusCode == 200) {
        final data = jsonDecode(urlResponse.body) as Map<String, dynamic>;
        final uploadUrl = data['uploadUrl'] as String?;

        if (uploadUrl != null) {
          // Upload image bytes to S3 pre-signed URL
          final bytes = await imageFile.readAsBytes();
          await http.put(
            Uri.parse(uploadUrl),
            headers: {'Content-Type': 'image/jpeg'},
            body: bytes,
          ).timeout(const Duration(seconds: 15));
        }
      }
    } catch (e) {
      debugPrint('Camera capture/upload error: $e');
    }
  }

  Future<List<String>> getMonitoringUrls(String alertId) async {
    try {
      final token = await AuthService().getCurrentJwt();
      if (token == null || token.isEmpty) return [];

      final response = await http.get(
        Uri.parse('${AppConfig.audioStreamEndpoint}/$alertId?type=camera'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return List<String>.from(data['streamUrls'] ?? []);
      }
    } catch (e) {
      debugPrint('Get camera URLs error: $e');
    }
    return [];
  }

  Future<void> stopMonitoring() async {
    _isMonitoring = false;
    _captureTimer?.cancel();
    _captureTimer = null;
  }

  void dispose() {
    stopMonitoring();
    _controller?.dispose();
  }
}
