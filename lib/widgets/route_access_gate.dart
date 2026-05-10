import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';

class RouteAccessGate extends StatelessWidget {
  const RouteAccessGate({
    super.key,
    required this.child,
    this.allowGuest = false,
    this.requireSession = true,
  });

  final Widget child;
  final bool allowGuest;
  final bool requireSession;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _canAccess(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.data == true) {
          return child;
        }

        return _AccessDeniedScreen(
          allowGuest: allowGuest,
          onGoLogin: () => context.go('/login'),
          onGoHome: () => context.go('/home'),
        );
      },
    );
  }

  Future<bool> _canAccess() async {
    final auth = AuthService();
    final hasSession = await auth.hasActiveSession();
    if (!requireSession) {
      return true;
    }

    if (!hasSession) {
      return false;
    }

    final guest = await auth.isGuest();
    if (guest && !allowGuest) {
      return false;
    }

    return true;
  }
}

class _AccessDeniedScreen extends StatelessWidget {
  const _AccessDeniedScreen({
    required this.allowGuest,
    required this.onGoLogin,
    required this.onGoHome,
  });

  final bool allowGuest;
  final VoidCallback onGoLogin;
  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Access restricted')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 56),
              const SizedBox(height: 16),
              const Text(
                'This section is available only to authenticated users.',
                textAlign: TextAlign.center,
              ),
              if (allowGuest)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Guest mode is allowed for monitoring-only screens.',
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 20),
              FilledButton(onPressed: onGoLogin, child: const Text('Login / Sign Up')),
              const SizedBox(height: 12),
              FilledButton.tonal(onPressed: onGoHome, child: const Text('Go to Dashboard')),
            ],
          ),
        ),
      ),
    );
  }
}
