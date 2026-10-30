// lib/features/ai_assistant/services/ai_preferences_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized service managing AI Assistant user preferences.
/// Uses a ValueNotifier so UI components (like bottom navigation)
/// can reactively add or remove the AI Assistant tab in real time.
class AiPreferencesService {
  static const String _keyAiEnabled = 'ai_academic_assistant_enabled';
  static const String _keyApiKey = 'gemini_api_key_custom';

  static final ValueNotifier<bool> isAiEnabledNotifier = ValueNotifier<bool>(false);
  static bool _initialized = false;

  /// Initializes preferences on app launch.
  static Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_keyAiEnabled) ?? false;
    isAiEnabledNotifier.value = enabled;
    _initialized = true;
  }

  /// Checks if the AI Assistant has been opted into by the user.
  static Future<bool> isAiEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_keyAiEnabled) ?? false;
    isAiEnabledNotifier.value = enabled;
    return enabled;
  }

  /// Sets whether the AI Assistant is enabled and notifies all active listeners.
  static Future<void> setAiEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAiEnabled, enabled);
    isAiEnabledNotifier.value = enabled;
  }

  /// Gets any user-provided custom Gemini API key.
  static Future<String?> getCustomApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyApiKey);
  }

  /// Sets a user-provided custom Gemini API key.
  static Future<void> setCustomApiKey(String? key) async {
    final prefs = await SharedPreferences.getInstance();
    if (key == null || key.trim().isEmpty) {
      await prefs.remove(_keyApiKey);
    } else {
      await prefs.setString(_keyApiKey, key.trim());
    }
  }
}

