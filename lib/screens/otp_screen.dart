import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;
  const OtpScreen({super.key, required this.verificationId});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cognito Verification')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text('Managed login handles verification and MFA inside the Cognito Hosted UI.', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text('Redirect code: ${widget.verificationId.isEmpty ? 'n/a' : widget.verificationId}', style: Theme.of(context).textTheme.bodySmall),
            const Spacer(),
            FilledButton(onPressed: () => context.go('/login'), child: const Text('Back to Login')),
          ],
        ),
      ),
    );
  }
}
