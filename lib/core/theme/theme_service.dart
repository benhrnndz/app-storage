// lib/core/theme/theme_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

/// Central theme controller for Syllo.
///
/// Manages persistent Day/Night theme preferences via SharedPreferences
/// and provides a reactive ValueNotifier for immediate zero-reload UI updates.
class ThemeService {
  static const String _prefKey = 'syllo_theme_mode';
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);
  static SharedPreferences? _prefs;

  /// Initializes the saved theme mode from persistent local storage
  /// and pre-warms ThemeData structures into memory for zero-latency response.
  static Future<void> init() async {
    // Pre-warm ThemeData memory structures (including Material 3 color seeds)
    final _ = AppTheme.lightTheme;
    final __ = AppTheme.darkTheme;

    try {
      _prefs = await SharedPreferences.getInstance();
      final savedMode = _prefs?.getString(_prefKey);
      if (savedMode == 'dark') {
        themeModeNotifier.value = ThemeMode.dark;
      } else if (savedMode == 'system') {
        themeModeNotifier.value = ThemeMode.system;
      } else {
        themeModeNotifier.value = ThemeMode.light;
      }
    } catch (_) {
      themeModeNotifier.value = ThemeMode.light;
    }
  }

  /// Returns true if the currently active theme mode is Night / Dark.
  static bool get isDarkMode => themeModeNotifier.value == ThemeMode.dark;

  /// Sets the active theme mode synchronously for instant frame-0 response,
  /// and persists it asynchronously in the background.
  static Future<void> setThemeMode(ThemeMode mode) async {
    if (themeModeNotifier.value == mode) return;
    // Immediate synchronous UI state flip
    themeModeNotifier.value = mode;

    // Asynchronous non-blocking persistence
    _persistMode(mode);
  }

  static Future<void> _persistMode(ThemeMode mode) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final modeString = mode == ThemeMode.dark
          ? 'dark'
          : (mode == ThemeMode.system ? 'system' : 'light');
      await _prefs?.setString(_prefKey, modeString);
    } catch (_) {}
  }

  /// Toggles between Day (light) and Night (dark) modes with instant response.
  static Future<void> toggleTheme() async {
    final nextMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(nextMode);
  }
}
