import 'package:flutter/material.dart';
import 'dart:async';
import '../services/sos_service.dart';
import '../services/location_service.dart';
import '../services/auth_service.dart';
import '../config/feature_flags.dart';

class SilentSOSDetector extends StatefulWidget {
  final Widget child;

  const SilentSOSDetector({Key? key, required this.child}) : super(key: key);

  @override
  State<SilentSOSDetector> createState() => _SilentSOSDetectorState();
}

class _SilentSOSDetectorState extends State<SilentSOSDetector> {
  final SosService _sosService = SosService();
  final LocationService _locationService = LocationService();
  final AuthService _authService = AuthService();

  int _pressCount = 0;
  Timer? _pressResetTimer;

  @override
  void initState() {
    super.initState();
    if (FeatureFlags.SILENT_SOS_ENABLED) {
      _setupVolumeButtonListener();
    }
  }

  @override
  void dispose() {
    _pressResetTimer?.cancel();
    super.dispose();
  }

  void _setupVolumeButtonListener() {
    _pressResetTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pressCount > 0) {
        _pressCount = 0;
      }
    });
  }

  void _handlePowerButtonPress() {
    _pressCount++;
    _pressResetTimer?.cancel();
    _pressResetTimer = Timer(const Duration(seconds: 3), () => _pressCount = 0);

    if (_pressCount >= 5) {
      _triggerSilentSOS();
      _pressCount = 0;
    }
  }

  Future<void> _triggerSilentSOS() async {
    final location = _locationService.getLastKnownPosition();
    if (location != null) {
      final userId = await _authService.getCurrentUserId();
      if (userId != null) {
        final result = await _sosService.triggerSOS(
          userId: userId,
          triggerType: 'silent',
          lat: location.latitude,
          lng: location.longitude,
        );

        if (mounted && result['error'] == null) {
          _showConfirmationOverlay();
        }
      }
    }
  }

  void _showConfirmationOverlay() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('SOS Triggered'),
        content: const Text('Silent SOS activated. Guardians are being notified with your location.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
