import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class FakeCallScreen extends StatefulWidget {
  const FakeCallScreen({super.key});

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen> {
  final AudioPlayer _player = AudioPlayer();
  bool _ringing = false;

  Future<void> _startCall() async {
    setState(() => _ringing = true);
    try {
      await _player.setAsset('assets/sounds/ringtone.mp3');
      _player.setLoopMode(LoopMode.one);
      _player.play();
    } catch (_) {}
  }

  Future<void> _stopCall() async {
    await _player.stop();
    setState(() => _ringing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fake Call')),
      body: Center(
        child: AnimatedScale(
          scale: _ringing ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 280),
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(colors: [Colors.black, Colors.blueGrey.shade900]),
              boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.15), blurRadius: 30)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(radius: 44, child: Icon(Icons.person, size: 42)),
                const SizedBox(height: 16),
                const Text('Incoming Call', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(_ringing ? 'Emergency Escape Mode' : 'Schedule a fake incoming call', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FilledButton.tonal(onPressed: _ringing ? _stopCall : _startCall, child: Text(_ringing ? 'End' : 'Start')),
                    FilledButton(onPressed: () {}, child: const Text('Schedule')),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
