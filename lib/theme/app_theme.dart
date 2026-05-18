import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Core Brand Colors ──────────────────────────────────────
  static const Color seedColor = Color(0xFF4F46E5); // Indigo
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFEF4444); // Red

  // ── Backgrounds ───────────────────────────────────────────
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color bgDark = Color(0xFF0F172A);
  
  // ── Card & Surface Colors ─────────────────────────────────
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF1E293B);

  // ── Legacy Mappings (For backward compatibility during transition) ──
  static const Color bg = bgDark;
  static const Color bgCard = cardDark;
  static const Color bgCardLight = Color(0xFF334155);
  static const Color surface = Color(0xFF1E293B);
  static const Color neonBlue = seedColor;
  static const Color neonPurple = Color(0xFF7C3AED);
  static const Color neonPink = Color(0xFFE040FB);
  static const Color neonGreen = success;
  static const Color neonRed = error;
  static const Color neonOrange = warning;
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // ── Gradients ──────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
  );
  static const LinearGradient incomeGradient = LinearGradient(
    colors: [Color(0xFF34D399), Color(0xFF10B981)],
  );
  static const LinearGradient expenseGradient = LinearGradient(
    colors: [Color(0xFFF87171), Color(0xFFEF4444)],
  );

  // ── Shadows & Glows ──────────────────────────────────────
  static List<BoxShadow> glow(Color color, {double blur = 24}) => [
        BoxShadow(
          color: color.withValues(alpha: 0.25),
          blurRadius: blur,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
      
  static List<BoxShadow> get neonGlow => glow(seedColor);

  // ── Radii ─────────────────────────────────────────────────
  static const double r12 = 12.0;
  static const double r16 = 16.0;
  static const double r20 = 20.0;
  static const double r24 = 24.0;
  static const double r28 = 28.0;

  // ── Typography ────────────────────────────────────────────
  static TextTheme _buildTextTheme(TextTheme base) {
    return GoogleFonts.poppinsTextTheme(base).copyWith(
      headlineLarge: GoogleFonts.poppins(fontWeight: FontWeight.w700, letterSpacing: -1.0),
      headlineMedium: GoogleFonts.poppins(fontWeight: FontWeight.w700, letterSpacing: -0.5),
      titleLarge: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.poppins(fontWeight: FontWeight.w500),
      bodyMedium: GoogleFonts.poppins(fontWeight: FontWeight.w400),
      labelLarge: GoogleFonts.poppins(fontWeight: FontWeight.w600),
    );
  }

  // ── Light Theme ───────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      surface: bgLight,
      error: error,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bgLight,
      textTheme: _buildTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r24)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r16)),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r16),
          borderSide: const BorderSide(color: seedColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r16),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: Colors.white,
        indicatorColor: seedColor.withValues(alpha: 0.15),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }

  // ── Dark Theme ────────────────────────────────────────────
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      surface: bgDark,
      error: error,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bgDark,
      textTheme: _buildTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r24)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r16)),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r16),
          borderSide: const BorderSide(color: seedColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r16),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: bgDark,
        indicatorColor: seedColor.withValues(alpha: 0.3),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
