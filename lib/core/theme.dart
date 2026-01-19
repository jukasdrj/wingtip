import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Swiss Utility color palette
  static const Color oledBlack = Color(0xFF000000);
  static const Color internationalOrange = Color(0xFFFF3B30);
  static const Color borderGray = Color(0xFF1C1C1E);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);

  static ThemeData get darkTheme {
    return ThemeData(
      // Force dark mode with OLED black background
      brightness: Brightness.dark,
      scaffoldBackgroundColor: oledBlack,

      // Color scheme with International Orange accent
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: internationalOrange,
        onPrimary: textPrimary,
        secondary: internationalOrange,
        onSecondary: textPrimary,
        surface: oledBlack,
        onSurface: textPrimary,
        error: internationalOrange,
        onError: textPrimary,
      ),

      // Typography: Inter for body, JetBrains Mono for numbers/IDs
      textTheme: TextTheme(
        // Display styles (large headers)
        displayLarge: GoogleFonts.inter(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.25,
          color: textPrimary,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 45,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),

        // Headline styles
        headlineLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),

        // Title styles
        titleLarge: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
          color: textPrimary,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: textPrimary,
        ),

        // Body styles
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          color: textPrimary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          color: textSecondary,
        ),

        // Label styles
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: textPrimary,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: textPrimary,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: textSecondary,
        ),
      ),

      // AppBar theme with 1px borders instead of shadows
      appBarTheme: AppBarTheme(
        backgroundColor: oledBlack,
        foregroundColor: textPrimary,
        elevation: 0,
        shadowColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        shape: const Border(
          bottom: BorderSide(
            color: borderGray,
            width: 1.0,
          ),
        ),
      ),

      // Card theme with borders instead of elevation
      cardTheme: const CardThemeData(
        color: oledBlack,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: borderGray,
            width: 1.0,
          ),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),

      // Elevated button with border style
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: internationalOrange,
          foregroundColor: textPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            side: const BorderSide(
              color: internationalOrange,
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          side: const BorderSide(
            color: borderGray,
            width: 1.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: internationalOrange,
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Input decoration with borders
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: oledBlack,
        border: const OutlineInputBorder(
          borderSide: BorderSide(
            color: borderGray,
            width: 1.0,
          ),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(
            color: borderGray,
            width: 1.0,
          ),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(
            color: internationalOrange,
            width: 1.0,
          ),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(
            color: internationalOrange,
            width: 1.0,
          ),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderSide: BorderSide(
            color: internationalOrange,
            width: 1.0,
          ),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        labelStyle: GoogleFonts.inter(
          color: textSecondary,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.inter(
          color: textSecondary,
          fontSize: 14,
        ),
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: borderGray,
        thickness: 1.0,
        space: 1.0,
      ),

      // Bottom navigation bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: oledBlack,
        selectedItemColor: internationalOrange,
        unselectedItemColor: textSecondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Floating action button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: internationalOrange,
        foregroundColor: textPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: internationalOrange,
            width: 1.0,
          ),
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: oledBlack,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          side: BorderSide(
            color: borderGray,
            width: 1.0,
          ),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
      ),

      // Disable all shadows globally
      useMaterial3: true,
    );
  }

  // Monospace style for numbers and IDs
  static TextStyle monoStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize ?? 14,
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color ?? textPrimary,
      letterSpacing: 0,
    );
  }
}
