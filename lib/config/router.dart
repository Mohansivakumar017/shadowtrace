import 'package:go_router/go_router.dart';
import '../screens/sos_screen.dart';
import '../screens/guardian_alert_screen.dart';
import '../screens/maps/live_tracking_screen.dart';
import '../screens/splash_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/sos',
      builder: (context, state) => const SosScreen(),
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

