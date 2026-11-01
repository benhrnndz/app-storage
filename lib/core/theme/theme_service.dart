// lib/core/theme/theme_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central theme controller for Syllo.
///
/// Manages persistent Day/Night theme preferences via SharedPreferences
/// and provides a reactive ValueNotifier for immediate zero-reload UI updates.
class ThemeService {
  static const String _prefKey = 'syllo_theme_mode';
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

  /// Initializes the saved theme mode from persistent local storage.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_prefKey);
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

  /// Sets the active theme mode and persists it to SharedPreferences.
  static Future<void> setThemeMode(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeString = mode == ThemeMode.dark
          ? 'dark'
          : (mode == ThemeMode.system ? 'system' : 'light');
      await prefs.setString(_prefKey, modeString);
    } catch (_) {}
  }

  /// Toggles between Day (light) and Night (dark) modes.
  static Future<void> toggleTheme() async {
    final nextMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(nextMode);
  }
}
