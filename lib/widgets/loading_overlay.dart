import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shadowtrace_app/theme/app_theme.dart';

class LoadingOverlay extends StatelessWidget {
  final String message;
  const LoadingOverlay({super.key, this.message = "INITIALIZING PROTOCOL..."});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryNeonBlue),
                strokeWidth: 2,
              ),
              const SizedBox(height: 20),
              Text(
                message,
                style: const TextStyle(
                  color: AppTheme.primaryNeonBlue,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
