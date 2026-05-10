import 'package:flutter/material.dart';

class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {'title': 'SOS Alert', 'body': 'Guardian notified and live tracking shared.', 'time': '2m ago'},
      {'title': 'Route Warning', 'body': 'Safer route recomputed with low-risk streets.', 'time': '11m ago'},
      {'title': 'Background Monitor', 'body': 'Voice trigger is armed.', 'time': '30m ago'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (_, index) {
          final n = notifications[index];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_active),
              title: Text(n['title']!),
              subtitle: Text(n['body']!),
              trailing: Text(n['time']!),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemCount: notifications.length,
      ),
    );
  }
}
