import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../config/app_config.dart';
import 'auth_service.dart';

class AudioMonitoringService {
  static final AudioMonitoringService _instance =
      AudioMonitoringService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  String? _currentRecordingPath;
  DateTime? _recordingStartTime;
  String? _currentAlertId;
  int _chunkIndex = 0;

  factory AudioMonitoringService() {
    return _instance;
  }

  AudioMonitoringService._internal();

  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  Future<bool> startRecording(String alertId) async {
    try {
      if (!await hasPermission()) {
        debugPrint('Audio: Microphone permission denied');
        return false;
      }

      _currentAlertId = alertId;
      _chunkIndex = 0;
      _recordingStartTime = DateTime.now();

      final dir = await getApplicationDocumentsDirectory();
      _currentRecordingPath =
          '${dir.path}/audio_${alertId}_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      return true;
    } catch (e) {
      debugPrint('Start recording error: $e');
      return false;
    }
  }

  Future<bool> stopRecording() async {
    try {
      final path = await _recorder.stop();
      if (path == null) return false;

      if (_currentAlertId != null) {
        await _uploadAudioChunk(_currentAlertId!, path);
      }
      _currentRecordingPath = null;
      _recordingStartTime = null;
      _currentAlertId = null;

      return true;
    } catch (e) {
      debugPrint('Stop recording error: $e');
      return false;
    }
  }

  Future<bool> _uploadAudioChunk(String alertId, String filePath) async {
    try {
      final token = await AuthService().getCurrentJwt();
      if (token == null || token.isEmpty) return false;

      final response = await http.post(
        Uri.parse(AppConfig.audioStreamEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'alertId': alertId,
          'chunkIndex': _chunkIndex,
          'type': 'audio',
          'contentType': 'audio/m4a',
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return false;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final uploadUrl = data['uploadUrl'] as String?;

      if (uploadUrl == null) return false;

      final fileBytes = await _readFileAsBytes(filePath);
      if (fileBytes.isEmpty) return false;

      final uploadResponse = await http.put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': 'audio/m4a'},
        body: fileBytes,
      ).timeout(const Duration(seconds: 15));

      _chunkIndex++;
      return uploadResponse.statusCode == 200;
    } catch (e) {
      debugPrint('Upload audio chunk error: $e');
      return false;
    }
  }

  Future<Uint8List> _readFileAsBytes(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('Audio file not found: $filePath');
        return Uint8List(0);
      }
      return await file.readAsBytes();
    } catch (e) {
      debugPrint('Read file error: $e');
      return Uint8List(0);
    }
  }

  Future<List<String>> getAudioStreamUrls(String alertId) async {
    try {
      final token = await AuthService().getCurrentJwt();
      if (token == null || token.isEmpty) return [];

      final response = await http.get(
        Uri.parse('${AppConfig.audioStreamEndpoint}/$alertId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final urls = (data['streamUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      return urls;
    } catch (e) {
      debugPrint('Get audio stream urls error: $e');
      return [];
    }
  }

  void dispose() {
    _recorder.dispose();
  }
}
