import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:record/record.dart';
import '../config/app_config.dart';

class AudioMonitoringService {
  static final AudioMonitoringService _instance =
      AudioMonitoringService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  String? _currentRecordingPath;
  DateTime? _recordingStartTime;

  factory AudioMonitoringService() {
    return _instance;
  }

  AudioMonitoringService._internal();

  Future<bool> startRecording(String alertId) async {
    try {
      if (!await _recorder.hasPermission()) {
        return false;
      }

      _currentRecordingPath = '/tmp/shadowtrace_alert_$alertId.m4a';
      _recordingStartTime = DateTime.now();

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

  Future<bool> stopRecording(String alertId) async {
    try {
      final path = await _recorder.stop();
      if (path == null) return false;

      await _uploadAudioChunk(alertId, path);
      _currentRecordingPath = null;
      _recordingStartTime = null;

      return true;
    } catch (e) {
      debugPrint('Stop recording error: $e');
      return false;
    }
  }

  Future<bool> _uploadAudioChunk(String alertId, String filePath) async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (!session.isSignedIn) return false;

      final idToken = _getTokenString(session);

      final response = await http.post(
        Uri.parse(AppConfig.audioStreamEndpoint),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'alertId': alertId}),
      );

      if (response.statusCode != 200) {
        return false;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final uploadUrl = data['uploadUrl'] as String?;

      if (uploadUrl == null) return false;

      final fileBytes = await _readFileAsBytes(filePath);
      final uploadResponse = await http.put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': 'audio/aac'},
        body: fileBytes,
      );

      return uploadResponse.statusCode == 200;
    } catch (e) {
      debugPrint('Upload audio chunk error: $e');
      return false;
    }
  }

  Future<List<String>> getAudioStreamUrls(String alertId) async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (!session.isSignedIn) return [];

      final idToken = _getTokenString(session);

      final response = await http.get(
        Uri.parse('${AppConfig.audioStreamEndpoint}/$alertId'),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

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

  Future<Uint8List> _readFileAsBytes(String filePath) async {
    // This would use dart:io in real app
    return Uint8List(0);
  }

  String _getTokenString(dynamic session) {
    try {
      return (session as dynamic).amplifyUserPoolTokens?.idToken?.toString() ??
          "";
    } catch (_) {
      return "";
    }
  }
}
