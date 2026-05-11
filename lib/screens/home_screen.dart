import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final allTiles = <({String title, IconData icon, String route})>[
      (title: 'Live Tracking', icon: Icons.map, route: '/live/default-trip'),
      (title: 'SOS', icon: Icons.sos, route: '/sos'),
      (title: 'Notifications', icon: Icons.notifications, route: '/notifications'),
      (title: 'AI Assistant', icon: Icons.smart_toy, route: '/assistant'),
      (title: 'Guardians', icon: Icons.shield, route: '/guardians'),
      (title: 'Profile', icon: Icons.person, route: '/profile'),
      (title: 'History', icon: Icons.history, route: '/history'),
      (title: 'Nearby', icon: Icons.local_hospital, route: '/nearby'),
      (title: 'Fake Call', icon: Icons.call, route: '/fake-call'),
      (title: 'Voice', icon: Icons.mic, route: '/voice'),
      (title: 'Settings', icon: Icons.settings, route: '/settings'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('ShadowTrace'),
        actions: [
          IconButton(onPressed: () => context.go('/settings'), icon: const Icon(Icons.tune)),
        ],
      ),
      body: FutureBuilder<bool>(
        future: AuthService().isGuest(),
        builder: (context, snapshot) {
          final isGuest = snapshot.data == true;
          final tiles = isGuest
              ? allTiles.where((tile) => tile.route == '/live/default-trip' || tile.route == '/sos' || tile.route == '/notifications').toList()
              : allTiles;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(colors: [Colors.cyanAccent.withValues(alpha: 0.12), Colors.white.withValues(alpha: 0.03)]),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Safety status', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        const Text('Live location, SOS, route analysis, and AI assistant are ready.'),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isGuest ? Colors.amber.withValues(alpha: 0.14) : Colors.cyanAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Text(
                            isGuest ? 'Guest mode: live monitoring and SOS alerts only' : 'Authenticated mode: full guardian and travel tracking access',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => context.go('/sos'),
                                icon: const Icon(Icons.sos),
                                label: const Text('SOS'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.tonalIcon(
                                onPressed: () => context.go('/live/default-trip'),
                                icon: const Icon(Icons.map),
                                label: const Text('Track'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final tile = tiles[index];
                      return InkWell(
                        onTap: () => context.go(tile.route),
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            color: const Color(0xFF0C1220),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 8))],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(tile.icon, color: Colors.cyanAccent, size: 30),
                              Text(tile.title, style: Theme.of(context).textTheme.titleMedium),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: tiles.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
