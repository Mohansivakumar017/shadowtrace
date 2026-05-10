import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'dart:async';
import '../config/feature_flags.dart';

class DeadZoneCountdown extends StatefulWidget {
  final int totalSeconds;
  final VoidCallback onCancel;

  const DeadZoneCountdown({
    Key? key,
    required this.totalSeconds,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<DeadZoneCountdown> createState() => _DeadZoneCountdownState();
}

class _DeadZoneCountdownState extends State<DeadZoneCountdown> {
  late int _remainingSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.totalSeconds;
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _remainingSeconds--);

      if (_remainingSeconds == 60 && FeatureFlags.PRE_ALERT_VIBRATION) {
        Vibration.vibrate(duration: 500);
      }

      if (_remainingSeconds <= 0) {
        timer.cancel();
      }
    });
  }

  Future<void> _handleCancel() async {
    _timer?.cancel();
    widget.onCancel();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Heartbeat sent - timer reset')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _remainingSeconds / widget.totalSeconds;

    return Card(
      color: Colors.red[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Dead Zone Warning',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: progress,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _remainingSeconds <= 60 ? Colors.orange : Colors.white,
                    ),
                    strokeWidth: 4,
                  ),
                ),
                Text(
                  '$_remainingSeconds s',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _handleCancel,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Send Heartbeat'),
            ),
          ],
        ),
      ),
    );
  }
}
