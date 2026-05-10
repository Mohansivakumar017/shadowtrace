import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
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
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      return requested == LocationPermission.whileInUse ||
          requested == LocationPermission.always;
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  void startTracking(String tripId, Function(Position) onLocation) async {
    final hasPermission = await requestPermissions();
    if (!hasPermission) return;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
        timeLimit: Duration(seconds: AppConfig.locationPollIntervalSeconds),
      ),
    ).listen((Position position) async {
      _lastKnownPosition = position;
      onLocation(position);

      try {
        final session = await Amplify.Auth.getSession();
        final idToken = session.isSignedIn ? session.userPoolTokens!.idToken.toString() : null;

        if (idToken != null) {
          await http.post(
            Uri.parse('${AppConfig.apiBaseUrl}/location'),
            headers: {
              'Authorization': 'Bearer $idToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'lat': position.latitude,
              'lng': position.longitude,
              'tripId': tripId,
              'timestamp': DateTime.now().toIso8601String(),
              'speed': position.speed,
              'heading': position.heading,
            }),
          );

          await _sendHeartbeat(tripId, idToken);
        }
      } catch (e) {
        print('Location upload error: $e');
      }
    });
  }

  Future<void> _sendHeartbeat(String tripId, String idToken) async {
    try {
      await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/heartbeat'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'tripId': tripId}),
      );
    } catch (e) {
      print('Heartbeat error: $e');
    }
  }

  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  Position? getLastKnownPosition() {
    return _lastKnownPosition;
  }
}
