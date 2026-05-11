import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  StreamSubscription<Position>? _positionStream;
  Position? _lastKnownPosition;

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      return requested == LocationPermission.whileInUse ||
          requested == LocationPermission.always;
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  void startTracking(String userId, String tripId,
      Function(Position) onLocation) async {
    if (kIsWeb) {
      debugPrint('Location tracking not available on web');
      return;
    }

    final hasPermission = await requestPermissions();
    if (!hasPermission) return;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10,
        timeLimit: Duration(seconds: AppConfig.locationPollIntervalSeconds),
      ),
    ).listen((Position position) async {
      _lastKnownPosition = position;
      onLocation(position);

      try {
        final session = await Amplify.Auth.fetchAuthSession();
        final idToken = session.isSignedIn ? _getTokenString(session) : null;

        if (idToken != null) {
          await http.post(
            Uri.parse(AppConfig.locationEndpoint),
            headers: {
              'Authorization': 'Bearer $idToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'userId': userId,
              'tripId': tripId,
              'lat': position.latitude,
              'lng': position.longitude,
              'timestamp': DateTime.now().toIso8601String(),
              'accuracy': position.accuracy,
              'speed': position.speed,
            }),
          );

          await _sendHeartbeat(tripId, idToken);
        }
      } catch (e) {
        debugPrint('Location upload error: $e');
      }
    });
  }

  Future<void> _sendHeartbeat(String tripId, String idToken) async {
    try {
      await http.post(
        Uri.parse(AppConfig.heartbeatEndpoint),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'tripId': tripId}),
      );
    } catch (e) {
      debugPrint('Heartbeat error: $e');
    }
  }

  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  Position? getLastKnownPosition() {
    return _lastKnownPosition;
  }

  String _getTokenString(dynamic session) {
    try {
      return (session as dynamic).amplifyUserPoolTokens?.idToken?.toString() ?? "";
    } catch (_) {
      return "";
    }
  }
}
