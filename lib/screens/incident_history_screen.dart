import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';

class IncidentHistoryScreen extends StatefulWidget {
  final String userId;

  const IncidentHistoryScreen({
    super.key,
    required this.userId,
  });

  @override
  State<IncidentHistoryScreen> createState() => _IncidentHistoryScreenState();
}

class _IncidentHistoryScreenState extends State<IncidentHistoryScreen> {
  List<Map<String, dynamic>> _incidents = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchIncidents();
  }

  Future<void> _fetchIncidents() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await AuthService().getCurrentJwt();
      if (token == null || token.isEmpty) {
        setState(() {
          _error = 'Authentication failed';
          _loading = false;
        });
        return;
      }

      final resp = await http.get(
        Uri.parse(
          '${AppConfig.alertApiBase}/incidents?userId=${widget.userId}',
        ),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        setState(() {
          _incidents =
              List<Map<String, dynamic>>.from(data['incidents'] ?? []);
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load incidents (${resp.statusCode})';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'voice':
        return Icons.mic;
      case 'silent':
        return Icons.volume_off;
      case 'dead_zone':
        return Icons.signal_wifi_off;
      case 'deviation':
        return Icons.alt_route;
      case 'ai_detected':
        return Icons.psychology;
      default:
        return Icons.warning_amber;
    }
  }

  Color _colorForStatus(String status) {
    switch (status) {
      case 'ACTIVE':
        return Colors.red;
      case 'RESOLVED':
        return Colors.green;
      case 'ACKNOWLEDGED':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident History'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchIncidents,
          )
        ],
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
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _fetchIncidents,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _incidents.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shield,
                              size: 64, color: Colors.green),
                          SizedBox(height: 12),
                          Text('No incidents yet',
                              style: TextStyle(fontSize: 18)),
                          Text('Stay safe!',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchIncidents,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _incidents.length,
                        itemBuilder: (ctx, i) {
                          final incident = _incidents[i];
                          final ts = DateTime.tryParse(
                              incident['timestamp'] ?? '');
                          final formatted = ts != null
                              ? DateFormat('MMM d, y • h:mm a')
                                  .format(ts.toLocal())
                              : 'Unknown time';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.red.shade100,
                                child: Icon(
                                  _iconForType(incident['type'] ?? ''),
                                  color: Colors.red.shade700,
                                ),
                              ),
                              title: Text(
                                (incident['type'] ?? 'unknown')
                                    .replaceAll('_', ' ')
                                    .toUpperCase(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(formatted),
                                  if (incident['lat'] != null &&
                                      incident['lng'] != null)
                                    Text(
                                      '${(incident['lat'] as num).toStringAsFixed(4)}, '
                                      '${(incident['lng'] as num).toStringAsFixed(4)}',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _colorForStatus(
                                      incident['status'] ?? ''),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  incident['status'] ?? 'UNKNOWN',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
