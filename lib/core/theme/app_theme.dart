// lib/core/theme/app_theme.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF2563EB); // Royal Azure
  static const Color accentIndigo = Color(0xFF4F46E5); // Electric Indigo
  static const Color successEmerald = Color(0xFF10B981); // Emerald Glow
  static const Color warningAmber = Color(0xFFF59E0B); // Warm Amber
  static const Color dangerRose = Color(0xFFF43F5E); // Rose Coral
  static const Color canvasLight = Color(0xFFF5F7FB); // Alabaster Frost

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryBlue,
      primary: primaryBlue,
      secondary: accentIndigo,
      tertiary: successEmerald,
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
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.3,
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: primaryBlue,
        unselectedLabelColor: Colors.black54,
        indicatorColor: primaryBlue,
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
