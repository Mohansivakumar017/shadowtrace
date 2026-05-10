import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

final firebaseInitProvider = FutureProvider<FirebaseApp>((ref) async {
  WidgetsFlutterBinding.ensureInitialized();
  return await Firebase.initializeApp();
});
