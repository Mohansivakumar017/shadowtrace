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
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onLongPress: () async {
                    if (loc == null) return;
                    setState(() => _active = true);
                    try {
                      await _sos.triggerSOS(
                        userId: 'user-default',
                        triggerType: 'manual',
                        lat: loc.latitude,
                        lng: loc.longitude,
                      );
                    } catch (e) {
                      debugPrint('SOS error: $e');
                    }
                  },
                  onLongPressEnd: (_) {
                    setState(() => _active = false);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _active ? 220 : 180,
                    height: _active ? 220 : 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.redAccent.withValues(alpha: 0.9),
                          Colors.black
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withValues(alpha: 0.6),
                          blurRadius: 24,
                          spreadRadius: 8,
                        )
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _active ? 'SENDING SOS' : 'HOLD TO SOS',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Long-press to activate emergency mode',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
