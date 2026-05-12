import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../services/biometric_auth_service.dart';
import '../services/auth_service.dart';

class BiometricSetupScreen extends StatefulWidget {
  const BiometricSetupScreen({super.key});

  @override
  State<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends State<BiometricSetupScreen> {
  final _biometricService = BiometricAuthService();
  final _authService = AuthService();

  bool _isAvailable = false;
  List<BiometricType> _availableBiometrics = [];
  bool _isEnabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkBiometricStatus();
  }

  Future<void> _checkBiometricStatus() async {
    final isAvailable = await _biometricService.isBiometricAvailable();
    final available = await _biometricService.getAvailableBiometrics();
    final isEnabled = await _biometricService.isBiometricEnabled();

    setState(() {
      _isAvailable = isAvailable;
      _availableBiometrics = available;
      _isEnabled = isEnabled;
      _loading = false;
    });
  }

  Future<void> _toggleBiometric(bool enable) async {
    if (enable) {
      final jwt = await _authService.getCurrentJwt();
      if (jwt == null || jwt.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not authenticated')),
        );
        return;
      }

      final success = await _biometricService.enableBiometric(jwt);
      if (success && mounted) {
        setState(() => _isEnabled = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric authentication enabled'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to enable biometric'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      final success = await _biometricService.disableBiometric();
      if (success && mounted) {
        setState(() => _isEnabled = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric authentication disabled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  String _getBiometricName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face Recognition';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris Scan';
      case BiometricType.strong:
        return 'Biometric';
      case BiometricType.weak:
        return 'Biometric (Weak)';
    }
  }

  IconData _getBiometricIcon(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return Icons.face;
      case BiometricType.fingerprint:
        return Icons.fingerprint;
      case BiometricType.iris:
        return Icons.remove_red_eye;
      default:
        return Icons.verified;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Settings'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Biometric Authentication',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  if (!_isAvailable)
                    Card(
                      color: Colors.orange.shade100,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.info,
                                color: Colors.orange.shade700, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Biometric authentication not available on this device',
                                style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Enable Biometric Login',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge,
                                    ),
                                    Switch(
                                      value: _isEnabled,
                                      onChanged: _toggleBiometric,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _isEnabled
                                        ? Colors.green.shade100
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _isEnabled
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        color: _isEnabled
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _isEnabled ? 'ENABLED' : 'DISABLED',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _isEnabled
                                              ? Colors.green
                                              : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Available Methods',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        ..._availableBiometrics.map((biometric) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Icon(
                                    _getBiometricIcon(biometric),
                                    size: 28,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(_getBiometricName(biometric)),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  const SizedBox(height: 24),
                  ExpansionTile(
                    title: const Text('Why Biometric Authentication?'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              '• Fast & Secure: Unlock ShadowTrace without entering your password',
                              style: TextStyle(height: 1.5),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '• Convenient: Quick access in emergency situations',
                              style: TextStyle(height: 1.5),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '• Private: Your biometric data stays on your device',
                              style: TextStyle(height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
