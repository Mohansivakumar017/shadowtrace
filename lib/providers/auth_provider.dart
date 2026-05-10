import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthMode>((ref) => AuthNotifier());

enum AuthMode { signedOut, guest, authenticated }

class AuthNotifier extends StateNotifier<AuthMode> {
  AuthNotifier() : super(AuthMode.signedOut);

  final AuthService _authService = AuthService();

  Future<void> bootstrap() async {
    final hasSession = await _authService.hasActiveSession();
    if (!hasSession) {
      state = AuthMode.signedOut;
      return;
    }

    state = await _authService.isGuest() ? AuthMode.guest : AuthMode.authenticated;
  }

  Future<void> signIn() async {
    final session = await _authService.signInWithCognito();
    if (session != null) {
      state = session.isGuest ? AuthMode.guest : AuthMode.authenticated;
    }
  }

  Future<void> signInAsGuest() async {
    await _authService.signInAsGuest();
    state = AuthMode.guest;
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = AuthMode.signedOut;
  }
}
