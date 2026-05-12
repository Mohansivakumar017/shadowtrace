import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  static final BiometricAuthService _instance =
      BiometricAuthService._internal();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  factory BiometricAuthService() {
    return _instance;
  }

  BiometricAuthService._internal();

  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      debugPrint('Biometric availability check error: $e');
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Get available biometrics error: $e');
      return [];
    }
  }

  Future<bool> authenticateWithBiometric(String reason) async {
    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      return isAuthenticated;
    } catch (e) {
      debugPrint('Biometric authentication error: $e');
      return false;
    }
  }

  Future<bool> enableBiometric(String jwt) async {
    try {
      final authenticated = await authenticateWithBiometric(
        'Authenticate to enable biometric login',
      );

      if (authenticated) {
        await _secureStorage.write(
          key: 'shadowtrace_jwt',
          value: jwt,
        );
        await _secureStorage.write(
          key: 'biometric_enabled',
          value: 'true',
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Enable biometric error: $e');
      return false;
    }
  }

  Future<bool> disableBiometric() async {
    try {
      await _secureStorage.delete(key: 'shadowtrace_jwt');
      await _secureStorage.delete(key: 'biometric_enabled');
      return true;
    } catch (e) {
      debugPrint('Disable biometric error: $e');
      return false;
    }
  }

  Future<bool> isBiometricEnabled() async {
    try {
      final enabled =
          await _secureStorage.read(key: 'biometric_enabled');
      return enabled == 'true';
    } catch (e) {
      debugPrint('Check biometric enabled error: $e');
      return false;
    }
  }

  Future<String?> getStoredJwt() async {
    try {
      return await _secureStorage.read(key: 'shadowtrace_jwt');
    } catch (e) {
      debugPrint('Get stored JWT error: $e');
      return null;
    }
  }

  Future<String?> authenticateAndGetJwt() async {
    try {
      final enabled = await isBiometricEnabled();
      if (!enabled) return null;

      final authenticated = await authenticateWithBiometric(
        'Authenticate to access ShadowTrace',
      );

      if (authenticated) {
        return await getStoredJwt();
      }
      return null;
    } catch (e) {
      debugPrint('Authenticate and get JWT error: $e');
      return null;
    }
  }
}
