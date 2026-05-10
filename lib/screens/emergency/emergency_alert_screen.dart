import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shadowtrace_app/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class EmergencyAlertScreen extends StatefulWidget {
  const EmergencyAlertScreen({super.key});

  @override
  State<EmergencyAlertScreen> createState() => _EmergencyAlertScreenState();
}

class _EmergencyAlertScreenState extends State<EmergencyAlertScreen> {
  int _countdown = 10;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 0) {
        timer.cancel();
        _triggerAlert();
      } else {
        setState(() {
          _countdown--;
        });
      }
    });
  }

  void _triggerAlert() {
    // Logic to call API POST /trigger-alert
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CRITICAL ALERT DISPATCHED')),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.emergencyRed,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF8B0000),
              AppTheme.emergencyRed,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'EMERGENCY TRIGGERED',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 40),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 250,
                      height: 250,
                      child: CircularProgressIndicator(
                        value: _countdown / 10,
                        strokeWidth: 12,
                        color: Colors.white,
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    Text(
                      '$_countdown',
                      style: const TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 60),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Guardians will be notified automatically if you don\'t cancel.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 80),
                _buildCancelButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        _timer?.cancel();
        context.pop();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.emergencyRed,
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
      ),
      child: const Text(
        'CANCEL ALERT',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
