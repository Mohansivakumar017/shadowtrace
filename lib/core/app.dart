import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../routes/app_router.dart';
import '../providers/auth_provider.dart';
import 'theme.dart';

class ShadowTraceApp extends ConsumerStatefulWidget {
  const ShadowTraceApp({super.key});

  @override
  ConsumerState<ShadowTraceApp> createState() => _ShadowTraceAppState();
}

class _ShadowTraceAppState extends ConsumerState<ShadowTraceApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(authProvider.notifier).bootstrap());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ShadowTrace',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: appRouter,
    );
  }
}
