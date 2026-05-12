import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';

class NearbyServicesScreen extends StatefulWidget {
  const NearbyServicesScreen({super.key});

  @override
  State<NearbyServicesScreen> createState() => _NearbyServicesScreenState();
}

class _NearbyServicesScreenState extends State<NearbyServicesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _hospitals = [];
  List<Map<String, dynamic>> _police = [];
  List<Map<String, dynamic>> _fire = [];
  bool _loading = true;
  String? _error;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchNearbyServices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchNearbyServices() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final token = await AuthService().getCurrentJwt();
      if (token == null || token.isEmpty) {
        setState(() {
          _error = 'Authentication failed';
          _loading = false;
        });
        return;
      }

      final results = await Future.wait([
        _searchPlaces('hospital', _currentPosition!, token),
        _searchPlaces('police station', _currentPosition!, token),
        _searchPlaces('fire station', _currentPosition!, token),
      ]);

      setState(() {
        _hospitals = results[0];
        _police = results[1];
        _fire = results[2];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _searchPlaces(
    String query,
    Position currentPos,
    String token,
  ) async {
    try {
      final resp = await http.get(
        Uri.parse(
          '${AppConfig.locationApiBase}/search-places'
          '?query=${Uri.encodeComponent(query)}'
          '&lat=${currentPos.latitude}&lng=${currentPos.longitude}'
          '&maxResults=10',
        ),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final places = List<Map<String, dynamic>>.from(data['places'] ?? []);

        for (final place in places) {
          final lat = place['lat'] as num?;
          final lng = place['lng'] as num?;
          if (lat != null && lng != null) {
            place['distanceKm'] = Geolocator.distanceBetween(
              currentPos.latitude,
              currentPos.longitude,
              lat.toDouble(),
              lng.toDouble(),
            ) / 1000;
          }
        }

        return places;
      }
    } catch (e) {
      debugPrint('Search places error: $e');
    }
    return [];
  }

  Widget _buildServiceList(List<Map<String, dynamic>> places, Color color) {
    if (places.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('No results found nearby'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: places.length,
      itemBuilder: (ctx, i) {
        final p = places[i];
        final distance = (p['distanceKm'] as num?)?.toStringAsFixed(1) ?? '?';

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p['name'] ?? 'Unknown',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  p['address'] ?? 'Address unavailable',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: color),
                    Text(' $distance km away',
                        style: TextStyle(color: color, fontSize: 12)),
                    const Spacer(),
                    if (p['phone'] != null)
                      TextButton.icon(
                        icon: const Icon(Icons.call, size: 16),
                        label: const Text('Call'),
                        onPressed: () {
                          launchUrl(Uri.parse('tel:${p['phone']}'));
                        },
                      ),
                    TextButton.icon(
                      icon: const Icon(Icons.navigation, size: 16),
                      label: const Text('Navigate'),
                      onPressed: () {
                        launchUrl(Uri.parse(
                          'https://maps.google.com/?q=${p['lat']},${p['lng']}',
                        ));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Emergency Services'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchNearbyServices,
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.local_hospital), text: 'Hospitals'),
            Tab(icon: Icon(Icons.local_police), text: 'Police'),
            Tab(icon: Icon(Icons.local_fire_department), text: 'Fire'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(_error!),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _fetchNearbyServices,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildServiceList(_hospitals, Colors.red),
                    _buildServiceList(_police, Colors.blue),
                    _buildServiceList(_fire, Colors.orange),
                  ],
                ),
    );
  }
}
