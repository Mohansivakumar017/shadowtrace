import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/live_tracking_screen.dart';
import '../screens/sos_screen.dart';
import '../screens/register_screen.dart';
import '../screens/otp_screen.dart';
import '../screens/ai_assistant_screen.dart';
import '../screens/guardian_contacts_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/notification_center_screen.dart';
import '../screens/incident_history_screen.dart';
import '../screens/nearby_services_screen.dart';
import '../screens/fake_call_screen.dart';
import '../screens/voice_command_screen.dart';

import '../screens/settings_screen.dart';
import '../widgets/route_access_gate.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
    GoRoute(path: '/otp', builder: (context, state) => OtpScreen(verificationId: state.uri.queryParameters['vid'] ?? '')),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/live/:tripId', builder: (context, state) => LiveTrackingScreen(
      tripId: state.pathParameters['tripId'] ?? '',
      polyline: const [],
    )),
    GoRoute(path: '/sos', builder: (context, state) => const SosScreen()),
    GoRoute(path: '/assistant', builder: (context, state) => const RouteAccessGate(child: AiAssistantScreen())),
    GoRoute(path: '/guardians', builder: (context, state) => const RouteAccessGate(child: GuardianContactsScreen())),
    GoRoute(path: '/profile', builder: (context, state) => const RouteAccessGate(child: ProfileScreen())),
    GoRoute(path: '/notifications', builder: (context, state) => const RouteAccessGate(allowGuest: true, child: NotificationCenterScreen())),
    GoRoute(path: '/history', builder: (context, state) => const RouteAccessGate(child: IncidentHistoryScreen())),
    GoRoute(path: '/nearby', builder: (context, state) => const RouteAccessGate(child: NearbyServicesScreen())),
    GoRoute(path: '/fake-call', builder: (context, state) => const RouteAccessGate(child: FakeCallScreen())),
    GoRoute(path: '/voice', builder: (context, state) => const RouteAccessGate(child: VoiceCommandScreen())),
    GoRoute(path: '/settings', builder: (context, state) => const RouteAccessGate(child: SettingsScreen())),
  ],
);
