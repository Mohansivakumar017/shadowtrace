import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sos_service.dart';
import '../providers/tracking_provider.dart';

class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen> {
  final SosService _sos = SosService();
  bool _active = false;

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(trackingProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency SOS')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onLongPress: () async {
                if (loc == null) return;
                setState(() => _active = true);
                await _sos.triggerSos(lat: loc.latitude, lon: loc.longitude, userId: 'user-1');
              },
              onLongPressEnd: (_) async {
                await _sos.stopSos();
                setState(() => _active = false);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _active ? 220 : 180,
                height: _active ? 220 : 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [Colors.redAccent.withOpacity(0.9), Colors.black]),
                  boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.6), blurRadius: 24, spreadRadius: 8)],
                ),
                child: Center(child: Text(_active ? 'SENDING SOS' : 'HOLD TO SOS', style: Theme.of(context).textTheme.titleLarge)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Long-press to activate emergency mode', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:provider/provider.dart';
import 'package:shadowtrace_app/providers/alert_provider.dart';
import 'package:shadowtrace_app/theme/app_theme.dart';
import 'package:shadowtrace_app/widgets/loading_overlay.dart';
import 'package:go_router/go_router.dart';

class SOSScreen extends StatelessWidget {
  const SOSScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alertProvider = Provider.of<AlertProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryNeonBlue.withOpacity(0.1),
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 3.seconds),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const Spacer(),
                  _buildSOSCentral(context, alertProvider),
                  const Spacer(),
                  _buildStatusCard(),
                ],
              ),
            ),
          ),

          if (alertProvider.isLoading) const LoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "SHADOWTRACE",
          style: TextStyle(
            color: AppTheme.primaryNeonBlue,
            letterSpacing: 8,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          "Safety Protocol",
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 800.ms).slideX(begin: -0.2);
  }

  Widget _buildSOSCentral(BuildContext context, AlertProvider provider) {
    return Center(
      child: GestureDetector(
        onLongPress: () => _triggerSOS(context, provider),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pulse Effects
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.emergencyRed.withOpacity(0.1),
              ),
            ).animate(onPlay: (controller) => controller.repeat())
              .scale(duration: 2.seconds, begin: const Offset(0.8, 0.8), end: const Offset(1.5, 1.5))
              .fadeOut(),

            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.emergencyRed.withOpacity(0.5),
                    blurRadius: 40,
                    spreadRadius: 10,
                  )
                ],
                gradient: const RadialGradient(
                  colors: [AppTheme.emergencyRed, Color(0xFF8B0000)],
                ),
              ),
              child: const Center(
                child: Text(
                  "SOS",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.black,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 120,
      borderRadius: 24,
      blur: 20,
      alignment: Alignment.center,
      border: 2,
      linearGradient: LinearGradient(
        colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
      ),
      borderGradient: LinearGradient(
        colors: [AppTheme.primaryNeonBlue.withOpacity(0.5), Colors.transparent],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            const Icon(Icons.shield_outlined, color: AppTheme.primaryNeonBlue, size: 32),
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("SYSTEM STATUS", style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 2)),
                Text("ENCRYPTED & ACTIVE",
                  style: TextStyle(color: AppTheme.primaryNeonBlue.withOpacity(0.9), fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _triggerSOS(BuildContext context, AlertProvider provider) {
    provider.sendSOS(
      userId: "user_final_001",
      guardianPhone: "+919999999999",
      lat: 16.5062,
      lng: 80.6480,
      onSuccess: () {
        _showEmergencyPopup(context);
      },
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppTheme.emergencyRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  void _showEmergencyPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A0000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderStroke(color: AppTheme.emergencyRed, width: 2)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.emergencyRed),
            SizedBox(width: 10),
            Text("ALERT DISPATCHED", style: TextStyle(color: AppTheme.emergencyRed, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text("Your emergency signal has been broadcasted to the command center and your guardians.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/tracking');
            },
            child: const Text("PROCEED TO TRACKING", style: TextStyle(color: AppTheme.primaryNeonBlue)),
          )
        ],
      ),
    );
  }
}
