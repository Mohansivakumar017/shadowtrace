import 'package:flutter/foundation.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart' if (dart.library.html) 'package:amplify_flutter/amplify_flutter.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  Future<bool> signIn(String email, String password) async {
    if (kIsWeb) {
      debugPrint('Sign in not supported on web');
      return false;
    }
    try {
      final result = await Amplify.Auth.signIn(
        username: email,
        password: password,
      );
      return result.isSignedIn;
    } catch (e) {
      debugPrint('Sign in error: $e');
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String name) async {
    if (kIsWeb) {
      debugPrint('Sign up not supported on web');
      return false;
    }
    try {
      final result = await Amplify.Auth.signUp(
        username: email,
        password: password,
      );
      return !result.isSignUpComplete;
    } catch (e) {
      debugPrint('Sign up error: $e');
      return false;
    }
  }

  Future<bool> signOut() async {
    if (kIsWeb) return true;
    try {
      await Amplify.Auth.signOut();
      return true;
    } catch (e) {
      debugPrint('Sign out error: $e');
      return false;
    }
  }

  Future<String?> getCurrentJwt() async {
    if (kIsWeb) return null;
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      // Try to access token through dynamic to handle API changes
      try {
        final tokens = (session as dynamic).amplifyUserPoolTokens;
        return tokens?.idToken?.toString();
      } catch (_) {
        return null;
      }
    } catch (e) {
      debugPrint('Get JWT error: $e');
      return null;
    }
  }

  Future<bool> isSignedIn() async {
    if (kIsWeb) return false;
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      return session.isSignedIn;
    } catch (e) {
      debugPrint('Is signed in error: $e');
      return false;
    }
  }

  Future<bool> hasActiveSession() async {
    return isSignedIn();
  }

  Future<bool> isGuest() async {
    // For now, we'll treat all authenticated users as non-guests
    return false;
  }

  Future<dynamic> signInWithCognito() async {
    if (kIsWeb) {
      debugPrint('Cognito sign in not available on web');
      return null;
    }
    // This would typically trigger the Cognito hosted UI
    // For now, return a mock session
    try {
      await signIn('user@example.com', 'password');
      return await fetchAuthSession();
    } catch (e) {
      debugPrint('Cognito sign in error: $e');
      return null;
    }
  }

  Future<void> signInAsGuest() async {
    // Implement guest mode
    debugPrint('Signed in as guest');
  }

  Future<bool> signUpWithCognito() async {
    if (kIsWeb) {
      debugPrint('Cognito sign up not available on web');
      return false;
    }
    // This would typically trigger Cognito sign up
    debugPrint('Cognito sign up initiated');
    return false;
  }

  Future<dynamic> fetchAuthSession() async {
    if (kIsWeb) return null;
    try {
      return await Amplify.Auth.fetchAuthSession();
    } catch (e) {
      debugPrint('Fetch session error: $e');
      return null;
    }
  }
}
