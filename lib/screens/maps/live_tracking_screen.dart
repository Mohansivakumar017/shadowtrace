import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shadowtrace_app/theme/app_theme.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  GoogleMapController? _mapController;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _markers.add(
      const Marker(
        markerId: MarkerId('user_location'),
        position: LatLng(37.42796133580664, -122.085749655962),
        infoWindow: InfoWindow(title: 'Your Location'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LIVE TRACKING', style: TextStyle(letterSpacing: 2)),
        backgroundColor: AppTheme.backgroundDark,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            markers: _markers,
            onMapCreated: (controller) => _mapController = controller,
            myLocationEnabled: true,
            mapType: MapType.dark,
          ),
          _buildTrackingOverlay(),
        ],
      ),
    );
  }

  Widget _buildTrackingOverlay() {
    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryNeonBlue.withOpacity(0.3)),
        ),
        child: const Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 8,
                  backgroundColor: AppTheme.primaryNeonBlue,
                ),
                SizedBox(width: 12),
                Text(
                  'BROADCASTING LIVE SIGNAL',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryNeonBlue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Location updates every 5 seconds. Guardians are monitoring.',
              style: TextStyle(fontSize: 10, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

extension on MapType {
  static const MapType dark = MapType.normal; // Google Maps doesn't have a direct 'dark' enum in the plugin, usually handled via styling JSON.
}
