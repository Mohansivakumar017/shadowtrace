import 'package:flutter/material.dart';

class NearbyServicesScreen extends StatelessWidget {
  const NearbyServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = [
      {'name': 'Police Station', 'eta': '4 min', 'distance': '0.8 km'},
      {'name': 'Hospital', 'eta': '6 min', 'distance': '1.4 km'},
      {'name': '24/7 Taxi', 'eta': '3 min', 'distance': '0.5 km'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Services')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (_, index) {
          final s = services[index];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.location_on),
              title: Text(s['name']!),
              subtitle: Text('${s['distance']} away'),
              trailing: Text(s['eta']!),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemCount: services.length,
      ),
    );
  }
}
