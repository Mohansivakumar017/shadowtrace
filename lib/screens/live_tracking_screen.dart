import 'dart:async';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../services/location_service.dart';
import '../services/route_service.dart';
import '../services/sos_service.dart';
import '../config/app_config.dart';
import '../widgets/dead_zone_countdown.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String tripId;
  final List<dynamic> polyline;
  final bool hazardFlag;

  const LiveTrackingScreen({
    Key? key,
    required this.tripId,
    required this.polyline,
    this.hazardFlag = false,
  }) : super(key: key);

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final LocationService _locationService = LocationService();
  final SOSService _sosService = SOSService();
  final RouteService _routeService = RouteService();

  MaplibreMapController? _mapController;
  Timer? _deadZoneTimer;
  int _deadZoneCounter = 0;
  bool _showDeadZoneWarning = false;

  @override
  void initState() {
    super.initState();
    _locationService.startTracking(widget.tripId, _onLocationUpdate);
    _startDeadZoneTimer();
  }

  @override
  void dispose() {
    _locationService.stopTracking();
    _deadZoneTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _onLocationUpdate(dynamic position) {
    _deadZoneCounter = 0;
    if (mounted) {
      setState(() => _showDeadZoneWarning = false);
    }
  }

  void _startDeadZoneTimer() {
    _deadZoneTimer = Timer.periodic(Duration(seconds: AppConfig.locationPollIntervalSeconds), (timer) {
      _deadZoneCounter += AppConfig.locationPollIntervalSeconds;

      if (_deadZoneCounter >= 60 && !_showDeadZoneWarning && mounted) {
        setState(() => _showDeadZoneWarning = true);
      }

      if (_deadZoneCounter >= AppConfig.deadZoneThresholdSeconds && mounted) {
        _handleDeadZoneTimeout();
        timer.cancel();
      }
    });
  }

  Future<void> _handleDeadZoneTimeout() async {
    final location = _locationService.getLastKnownPosition();
    if (location != null) {
      await _sosService.triggerSOS(location.latitude, location.longitude);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dead zone detected - SOS triggered'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _triggerSOS() async {
    final location = _locationService.getLastKnownPosition();
    if (location != null) {
      final alertId = await _sosService.triggerSOS(location.latitude, location.longitude);
      if (alertId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('SOS triggered: $alertId')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          MaplibreMap(
            styleString: AppConfig.alsMapStyle,
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: const CameraPosition(target: LatLng(28.6139, 77.2090), zoom: 14),
          ),
          if (widget.hazardFlag)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.warning, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(child: Text('Weather hazard on route', style: TextStyle(color: Colors.white))),
                  ],
                ),
              ),
            ),
          if (_showDeadZoneWarning)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: DeadZoneCountdown(
                totalSeconds: AppConfig.deadZoneThresholdSeconds - _deadZoneCounter,
                onCancel: () {
                  _deadZoneCounter = 0;
                  setState(() => _showDeadZoneWarning = false);
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _triggerSOS,
        backgroundColor: Colors.red,
        child: const Icon(Icons.sos),
      ),
    );
  }
}
