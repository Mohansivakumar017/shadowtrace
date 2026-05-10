import 'package:flutter/material.dart';

class AppTheme {
  static final Color primary = const Color(0xFF00FFE1);
  static final Color accent = const Color(0xFF7C4DFF);

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: primary,
      secondary: accent,
      surface: const Color(0xFF0B0F1A),
      background: const Color(0xFF05060A),
      onPrimary: Colors.black,
    ),
    scaffoldBackgroundColor: const Color(0xFF05060A),
    textTheme: Typography.whiteMountainView,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
  );
}
