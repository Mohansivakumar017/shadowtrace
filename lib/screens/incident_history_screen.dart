import 'package:flutter/material.dart';

class IncidentHistoryScreen extends StatelessWidget {
  const IncidentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final incidents = [
      {'title': 'SOS trigger', 'status': 'Resolved', 'date': '2026-05-06'},
      {'title': 'Route risk alert', 'status': 'Review', 'date': '2026-05-05'},
      {'title': 'Fake call used', 'status': 'Completed', 'date': '2026-05-01'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Incident History')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: incidents.length,
        itemBuilder: (_, index) {
          final item = incidents[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.history),
              title: Text(item['title']!),
              subtitle: Text(item['date']!),
              trailing: Chip(label: Text(item['status']!)),
            ),
          );
        },
      ),
    );
  }
}
