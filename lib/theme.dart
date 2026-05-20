import 'package:flutter/material.dart';

class AppTheme {
  // Couleurs principales - Thème Blanc & Rouge
  static const Color primary = Color(0xFFFFFFFF);       // Fond blanc
  static const Color accent = Color(0xFFE53935);         // Rouge principal
  static const Color lostColor = Color(0xFFE53935);      // Rouge
  static const Color foundColor = Color(0xFF43A047);     // Vert
  static const Color cardBg = Color(0xFFF5F5F5);         // Gris très clair
  static const Color surface = Color(0xFFFFEBEE);        // Rouge très clair
  static const Color textPrimary = Color(0xFF212121);    // Texte noir
  static const Color textSecondary = Color(0xFF757575);  // Texte gris
  static const Color divider = Color(0xFFE0E0E0);        // Séparateur gris clair

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: primary,
      colorScheme: const ColorScheme.light(
        primary: accent,
        secondary: surface,
        surface: cardBg,
      ),
      fontFamily: 'SF Pro Display',
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textSecondary),
        prefixIconColor: textSecondary,
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: divider, width: 1),
        ),
      ),
    );
  }
}