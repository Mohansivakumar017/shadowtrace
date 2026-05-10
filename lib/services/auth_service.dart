import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  Future<bool> signIn(String email, String password) async {
    try {
      final result = await Amplify.Auth.signIn(
        username: email,
        password: password,
      );
      return result.isSignedIn;
    } catch (e) {
      print('Sign in error: $e');
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String name) async {
    try {
      final userAttributes = <CognitoUserAttributeKey, String>{
        CognitoUserAttributeKey.email: email,
        CognitoUserAttributeKey.name: name,
      };

      final result = await Amplify.Auth.signUp(
        username: email,
        password: password,
        userAttributes: userAttributes,
      );

      return !result.isSignUpComplete;
    } catch (e) {
      print('Sign up error: $e');
      return false;
    }
  }

  Future<bool> signOut() async {
    try {
      await Amplify.Auth.signOut();
      return true;
    } catch (e) {
      print('Sign out error: $e');
      return false;
    }
  }

  Future<String?> getCurrentJwt() async {
    try {
      final session = await Amplify.Auth.getSession();
      if (session.isSignedIn) {
        return session.userPoolTokens?.idToken.toString();
      }
      return null;
    } catch (e) {
      print('Get JWT error: $e');
      return null;
    }
  }

  Future<bool> isSignedIn() async {
    try {
      final session = await Amplify.Auth.getSession();
      return session.isSignedIn;
    } catch (e) {
      print('Is signed in error: $e');
      return false;
    }
  }
}
