import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _backgroundTracking = true;
  bool _siren = true;
  bool _voiceActivation = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(value: _backgroundTracking, title: const Text('Background Tracking'), onChanged: (v) => setState(() => _backgroundTracking = v)),
          SwitchListTile(value: _siren, title: const Text('Siren Emergency Mode'), onChanged: (v) => setState(() => _siren = v)),
          SwitchListTile(value: _voiceActivation, title: const Text('Voice Activation'), onChanged: (v) => setState(() => _voiceActivation = v)),
          const Divider(),
          ListTile(title: const Text('OpenAI API Key'), subtitle: Text(dotenv.env['OPENAI_API_KEY']?.isNotEmpty == true ? 'Configured' : 'Missing')),
          ListTile(title: const Text('AWS Region'), subtitle: Text(dotenv.env['AWS_REGION'] ?? 'Not set')),
        ],
      ),
    );
  }
}
