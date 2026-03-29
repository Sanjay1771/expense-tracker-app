// Premium dark theme with neon gradient colors and glowing effects
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Core Dark Colors ──────────────────────────────────────
  static const Color bg = Color(0xFF0A0E21);
  static const Color bgCard = Color(0xFF111530);
  static const Color bgCardLight = Color(0xFF1A1F3D);
  static const Color surface = Color(0xFF151937);

  // ── Neon Accent Colors ────────────────────────────────────
  static const Color neonBlue = Color(0xFF00D4FF);
  static const Color neonPurple = Color(0xFF7C3AED);
  static const Color neonPink = Color(0xFFE040FB);
  static const Color neonGreen = Color(0xFF00E676);
  static const Color neonRed = Color(0xFFFF5252);
  static const Color neonOrange = Color(0xFFFF9100);
  static const Color neonYellow = Color(0xFFFFEA00);

  // ── Text Colors ───────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF0F0F5);
  static const Color textSecondary = Color(0xFF8890B5);
  static const Color textMuted = Color(0xFF5A6088);

  // ── Gradient Presets ──────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C5CE7), Color(0xFF00CEFF)],
  );
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1F3D), Color(0xFF111530)],
  );
  static const LinearGradient incomeGradient = LinearGradient(
    colors: [Color(0xFF00E676), Color(0xFF00C853)],
  );
  static const LinearGradient expenseGradient = LinearGradient(
    colors: [Color(0xFFFF5252), Color(0xFFFF1744)],
  );

  // ── Shadows & Glows ──────────────────────────────────────
  static List<BoxShadow> neonGlow(Color color, {double blur = 20}) => [
        BoxShadow(
          color: color.withValues(alpha: 0.35),
          blurRadius: blur,
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get subtleGlow => [
        BoxShadow(
          color: neonBlue.withValues(alpha: 0.08),
          blurRadius: 30,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  // ── Radii ─────────────────────────────────────────────────
  static const double r12 = 12.0;
  static const double r16 = 16.0;
  static const double r20 = 20.0;
  static const double r24 = 24.0;

  // ── Theme Data ────────────────────────────────────────────
  // ── Light Theme Data ───────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8F9FE),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF6C5CE7),
        secondary: neonBlue,
        surface: Colors.white,
        error: neonRed,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme)
          .copyWith(
        headlineLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1A1F3D),
          letterSpacing: -0.5,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF5A6088),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1A1F3D),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A1F3D)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r12),
          borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 1.5),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: neonBlue,
        secondary: neonPurple,
        surface: surface,
        error: neonRed,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme)
          .copyWith(
        headlineLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgCardLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r12),
          borderSide: BorderSide(
            color: textMuted.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r12),
          borderSide: const BorderSide(color: neonBlue, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: GoogleFonts.poppins(color: textMuted, fontSize: 14),
      ),
    );
  }
}
