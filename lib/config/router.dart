import 'package:go_router/go_router.dart';
import 'package:shadowtrace_app/screens/sos_screen.dart';
import 'package:shadowtrace_app/screens/guardian_alert_screen.dart';
import 'package:shadowtrace_app/screens/maps/live_tracking_screen.dart';
import 'package:shadowtrace_app/screens/splash_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/sos',
      builder: (context, state) => const SOSScreen(),
    ),
    GoRoute(
      path: '/guardian',
      builder: (context, state) => const GuardianAlertScreen(),
    ),
    GoRoute(
      path: '/tracking',
      builder: (context, state) => const LiveTrackingScreen(),
    ),
  ],
);
