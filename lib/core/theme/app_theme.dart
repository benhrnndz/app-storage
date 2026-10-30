// lib/core/theme/app_theme.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Central theme specification for Syllo.
///
/// Implements Option 1: Biophilic Focus & Endurance color palette grounded
/// in cognitive ergonomics research (Kaplan Attention Restoration Theory &
/// UBC learning performance studies) to maximize study focus and minimize eye strain.
class AppTheme {
  // Option 1: Biophilic Focus & Endurance Palette
  static const Color primaryTeal = Color(0xFF0F766E); // Deep Oceanic Teal (Parasympathetic focus)
  static const Color accentTeal = Color(0xFF0D9488); // Luminous Focus Teal
  static const Color secondarySage = Color(0xFF10B981); // Sage Emerald (Attention restoration)
  static const Color accentGlacier = Color(0xFF0284C7); // Glacial Blue
  static const Color warningAmber = Color(0xFFF59E0B); // Warm Honey Ochre (Alertness without anxiety)
  static const Color dangerRose = Color(0xFFF43F5E); // Rose Coral
  static const Color canvasLight = Color(0xFFF6F9F8); // Alabaster Mint (Glare-free canvas)

  // Backward-compatibility aliases
  static const Color primaryBlue = primaryTeal;
  static const Color accentIndigo = secondarySage;
  static const Color successEmerald = secondarySage;

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryTeal,
      primary: primaryTeal,
      secondary: secondarySage,
      tertiary: accentTeal,
      surface: Colors.white,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: canvasLight,
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.3,
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: primaryTeal,
        unselectedLabelColor: Colors.black54,
        indicatorColor: primaryTeal,
        labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 3,
        backgroundColor: primaryTeal,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
