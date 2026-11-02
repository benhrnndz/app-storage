// lib/core/theme/app_theme.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Central theme specification for Syllo.
///
/// Implements Option 1: Biophilic Focus & Endurance color palette grounded
/// in cognitive ergonomics research (Kaplan Attention Restoration Theory &
/// UBC learning performance studies) to maximize study focus and minimize eye strain.
/// Supports seamless Day (light) and Night (dark) themes with frosted glass aesthetics.
class AppTheme {
  // Option 1: Biophilic Focus & Endurance Palette
  static const Color primaryTeal = Color(0xFF0F766E); // Deep Oceanic Teal (Parasympathetic focus)
  static const Color accentTeal = Color(0xFF0D9488); // Luminous Focus Teal
  static const Color secondarySage = Color(0xFF10B981); // Sage Emerald (Attention restoration)
  static const Color accentGlacier = Color(0xFF0284C7); // Glacial Blue
  static const Color warningAmber = Color(0xFFF59E0B); // Warm Honey Ochre (Alertness without anxiety)
  static const Color dangerRose = Color(0xFFF43F5E); // Rose Coral
  static const Color canvasLight = Color(0xFFF6F9F8); // Alabaster Mint (Glare-free canvas)

  // Night Theme (Dark Mode) Accents
  static const Color canvasDark = Color(0xFF0A1211); // Deep obsidian teal
  static const Color surfaceDark = Color(0xFF111E1D); // Dark frosted glass surface
  static const Color primaryTealDark = Color(0xFF2DD4BF); // Vibrant mint teal for dark contrast
  static const Color secondarySageDark = Color(0xFF34D399); // Luminous sage for dark contrast

  // Backward-compatibility aliases
  static const Color primaryBlue = primaryTeal;
  static const Color accentIndigo = secondarySage;
  static const Color successEmerald = secondarySage;

  /// Pre-computed, memoized Day Version (Light Mode)
  static final ThemeData lightTheme = _buildLightTheme();

  /// Pre-computed, memoized Night Version (Dark Mode)
  static final ThemeData darkTheme = _buildDarkTheme();

  static ThemeData _buildLightTheme() {
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
      brightness: Brightness.light,
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
        iconTheme: IconThemeData(color: Color(0xFF0F172A)),
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
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: primaryTeal.withOpacity(0.25),
            width: 1.0,
          ),
        ),
        elevation: 8,
        backgroundColor: const Color(0xFF0F172A).withOpacity(0.92),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 16,
        backgroundColor: Colors.white.withOpacity(0.94),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: Colors.black.withOpacity(0.06), width: 1.0),
        ),
        color: Colors.white.withOpacity(0.78),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
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

  static ThemeData _buildDarkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryTealDark,
      primary: primaryTealDark,
      secondary: secondarySageDark,
      tertiary: accentTeal,
      surface: surfaceDark,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: canvasDark,
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: primaryTealDark,
        unselectedLabelColor: Colors.white60,
        indicatorColor: primaryTealDark,
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
        backgroundColor: primaryTealDark,
        foregroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: Color(0xFF2DD4BF),
            width: 1.0,
          ),
        ),
        elevation: 10,
        backgroundColor: const Color(0xFF0A1211).withOpacity(0.95),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(0.12), width: 1.0),
        ),
        elevation: 20,
        backgroundColor: const Color(0xFF111E1D).withOpacity(0.94),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: Colors.white.withOpacity(0.12), width: 1.0),
        ),
        color: const Color(0xFF111E1D).withOpacity(0.70),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: Colors.white12,
        thickness: 1,
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
