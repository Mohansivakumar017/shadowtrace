import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:provider/provider.dart';
import 'package:shadowtrace_app/providers/alert_provider.dart';
import 'package:shadowtrace_app/theme/app_theme.dart';
import 'package:shadowtrace_app/widgets/loading_overlay.dart';

class GuardianAlertScreen extends StatelessWidget {
  const GuardianAlertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alertProvider = Provider.of<AlertProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildEmergencyHeader(),
                  const Spacer(),
                  _buildActionPanel(context, alertProvider),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          if (alertProvider.isLoading) const LoadingOverlay(message: "TRANSMITTING RESPONSE..."),
        ],
      ),
    );
  }

  Widget _buildEmergencyHeader() {
    return Column(
      children: [
        const Icon(Icons.emergency_share, color: AppTheme.emergencyRed, size: 80),
        const SizedBox(height: 20),
        const Text(
          "INCOMING EMERGENCY",
          style: TextStyle(color: AppTheme.emergencyRed, fontSize: 24, fontWeight: FontWeight.black, letterSpacing: 2),
        ),
        const SizedBox(height: 10),
        Text(
          "User: agent_001 is in danger",
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildActionPanel(BuildContext context, AlertProvider provider) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 350,
      borderRadius: 32,
      blur: 20,
      alignment: Alignment.center,
      border: 2,
      linearGradient: LinearGradient(colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]),
      borderGradient: const LinearGradient(colors: [AppTheme.primaryNeonBlue, Colors.transparent]),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildResponseButton(context, "ACCEPT", AppTheme.primaryNeonBlue, () => _handleResponse(context, provider, "ACCEPTED")),
            _buildResponseButton(context, "REJECT", Colors.white24, () => _handleResponse(context, provider, "REJECTED")),
            const Divider(color: Colors.white10),
            _buildResponseButton(context, "SAFE NOW", const Color(0xFF4CAF50), () => _handleResponse(context, provider, "SAFE_NOW")),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseButton(BuildContext context, String label, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.15),
          side: BorderSide(color: color, width: 1.5),
          elevation: 0,
        ),
        child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, letterSpacing: 4)),
      ),
    );
  }

  void _handleResponse(BuildContext context, AlertProvider provider, String response) async {
    final success = await provider.sendResponse(response);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("RESPONSE $response SENT"), backgroundColor: AppTheme.primaryNeonBlue),
      );
    }
  }
}
