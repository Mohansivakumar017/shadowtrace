import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(radius: 48, child: Icon(Icons.person, size: 48)),
          const SizedBox(height: 16),
          const ListTile(title: Text('Name'), subtitle: Text('ShadowTrace User')),
          const ListTile(title: Text('Email'), subtitle: Text('user@example.com')),
          const ListTile(title: Text('Phone'), subtitle: Text('+1 555 100 2000')),
          FilledButton(onPressed: () {}, child: const Text('Edit Profile')),
        ],
      ),
    );
  }
}
