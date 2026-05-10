import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _routeNext();
  }

  Future<void> _routeNext() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final hasSession = await _authService.hasActiveSession();
    if (hasSession) {
      context.go('/home');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.cyanAccent, Colors.blueGrey.shade900],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.2),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.location_on, size: 64, color: Colors.black),
            ),
            const SizedBox(height: 16),
            Text('ShadowTrace', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Managed login and guest mode', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
