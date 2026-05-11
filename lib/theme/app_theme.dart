import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const primaryNeonBlue = Color(0xFF00E5FF);
  static const secondaryPurple = Color(0xFF9C27B0);
  static const emergencyRed = Color(0xFFFF1744);
  static const backgroundDark = Color(0xFF0A0E14);
  static const surfaceDark = Color(0xFF161B22);
  static const accentGlow = Color(0xFF2979FF);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryNeonBlue,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryNeonBlue,
        secondary: secondaryPurple,
        error: emergencyRed,
        surface: surfaceDark,
        onSurface: Colors.white,
      ),
      textTheme: GoogleFonts.orbitronTextTheme(ThemeData.dark().textTheme)
          .copyWith(
        displayLarge: GoogleFonts.orbitron(
          color: primaryNeonBlue,
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
        bodyLarge: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      cardTheme: CardTheme(
        color: surfaceDark.withOpacity(0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryNeonBlue,
          foregroundColor: backgroundDark,
          textStyle: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

