import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadowtrace_app/theme/app_theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              AppTheme.accentGlow.withOpacity(0.1),
              AppTheme.backgroundDark,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildSafetyStatusCard(),
                const SizedBox(height: 24),
                _buildQuickActions(context),
                const SizedBox(height: 32),
                const Text(
                  'Active Guardians',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryNeonBlue,
                  ),
                ),
                const SizedBox(height: 16),
                _buildGuardianList(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildSOSButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SHADOWTRACE',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 4,
                color: AppTheme.primaryNeonBlue.withOpacity(0.7),
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Welcome, Agent',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const CircleAvatar(
          radius: 24,
          backgroundColor: AppTheme.primaryNeonBlue,
          child: Icon(Icons.person, color: AppTheme.backgroundDark),
        ),
      ],
    );
  }

  Widget _buildSafetyStatusCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.primaryNeonBlue.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              _buildPulseIndicator(),
              const SizedBox(width: 20),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SYSTEM STATUS',
                    style: TextStyle(fontSize: 10, letterSpacing: 2),
                  ),
                  Text(
                    'FULLY PROTECTED',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryNeonBlue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPulseIndicator() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryNeonBlue.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
        gradient: const SweepGradient(
          colors: [AppTheme.primaryNeonBlue, Colors.transparent],
        ),
      ),
      child: const Center(
        child: Icon(FontAwesomeIcons.shieldHalved, color: Colors.white),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        _buildActionItem(
          FontAwesomeIcons.locationDot,
          'Live Tracking',
          () => context.push('/tracking'),
        ),
        const SizedBox(width: 16),
        _buildActionItem(
          FontAwesomeIcons.robot,
          'AI Assistant',
          () {},
        ),
      ],
    );
  }

  Widget _buildActionItem(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.primaryNeonBlue),
              const SizedBox(height: 12),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuardianList() {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryNeonBlue, AppTheme.secondaryPurple],
                  ),
                ),
                child: const CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.surfaceDark,
                  child: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Guardian 1', style: TextStyle(fontSize: 10)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSOSButton(BuildContext context) {
    return GestureDetector(
      onLongPress: () => context.push('/emergency'),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.emergencyRed,
          boxShadow: [
            BoxShadow(
              color: AppTheme.emergencyRed.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'SOS',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
