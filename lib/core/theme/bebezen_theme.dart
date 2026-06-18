import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BebezenPalette {
  // Principal Colors
  static const Color primary = Color(0xFFE91E63);
  static const Color primaryLight = Color(0xFFFCE4EC);
  static const Color secondary = Color(0xFF6B2E8D);
  static const Color accent = Color(0xFF00BCD4);

  // Neutral Colors
  static const Color background = Color(0xFFFDF7F9);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF2D3142);
  static const Color textSecondary = Color(0xFF9094A6);
  static const Color divider = Color(0xFFF1F1F5);

  // Feedback
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFE91E63), Color(0xFFFF4081)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient softGradient = LinearGradient(
    colors: [Color(0xFFFDF7F9), Color(0xFFFCE4EC)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class BebezenTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: BebezenPalette.primary,
        primary: BebezenPalette.primary,
        secondary: BebezenPalette.secondary,
        surface: BebezenPalette.surface,
        background: BebezenPalette.background,
      ),
      scaffoldBackgroundColor: BebezenPalette.background,
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: BebezenPalette.textPrimary,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: BebezenPalette.textPrimary,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          color: BebezenPalette.textPrimary,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          color: BebezenPalette.textSecondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BebezenPalette.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BebezenPalette.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: BebezenPalette.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: BebezenPalette.primary, width: 2),
        ),
        hintStyle: const TextStyle(color: BebezenPalette.textSecondary),
      ),
      cardTheme: CardThemeData(
        color: BebezenPalette.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: BebezenPalette.divider),
        ),
      ),
    );
  }
}
