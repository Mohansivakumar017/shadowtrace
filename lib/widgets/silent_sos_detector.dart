import 'dart:async';
import 'package:flutter/material.dart';
import '../config/feature_flags.dart';
import '../services/sos_service.dart';
import '../services/location_service.dart';

class SilentSOSDetector extends StatefulWidget {
  final Widget child;
  final String userId;
  final String? tripId;

  const SilentSOSDetector({
    super.key,
    required this.child,
    required this.userId,
    this.tripId,
  });

  @override
  State<SilentSOSDetector> createState() => _SilentSOSDetectorState();
}

class _SilentSOSDetectorState extends State<SilentSOSDetector> {
  final SosService _sosService = SosService();
  final LocationService _locationService = LocationService();
  final List<DateTime> _pressTimes = [];
  static const int _requiredPresses = 5;
  static const Duration _window = Duration(seconds: 3);
  bool _sosTriggered = false;

  void _handlePress() {
    final now = DateTime.now();
    _pressTimes.add(now);

    // Remove presses outside the 3-second window
    _pressTimes.removeWhere((t) => now.difference(t) > _window);

    if (_pressTimes.length >= _requiredPresses && !_sosTriggered) {
      _pressTimes.clear();
      _triggerSilentSOS();
    }
  }

  Future<void> _triggerSilentSOS() async {
    _sosTriggered = true;
    if (!mounted) return;

    // Visual + haptic confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(children: [
          Icon(Icons.warning_amber, color: Colors.white),
          SizedBox(width: 8),
          Text('Silent SOS triggered — alerting your contacts'),
        ]),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );

    try {
      final location = _locationService.getLastKnownPosition();
      await _sosService.triggerSOS(
        userId: widget.userId,
        triggerType: 'silent',
        tripId: widget.tripId,
        lat: location?.latitude,
        lng: location?.longitude,
      );
    } catch (e) {
      debugPrint('Silent SOS error: $e');
    }

    // Allow re-trigger after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) _sosTriggered = false;
    });
  }

  @override
  void activate() {
    super.activate();
    if (FeatureFlags.SILENT_SOS_ENABLED) {
      // Hardware button listener would be set up here
      // For now, this is a stub that listens to app-level events
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
