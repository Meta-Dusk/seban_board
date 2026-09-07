import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  ThemeService._();

  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(
    .system,
  );

  static final ValueNotifier<Color> seedColor = ValueNotifier<Color>(
    Colors.blue,
  );

  static const String _modeKey = 'theme_mode';
  static const String _colorKey = 'seed_color';

  /// Loads the saved theme settings from disk
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Brightness Mode
    final modeString = prefs.getString(_modeKey);
    if (modeString != null) {
      themeMode.value = ThemeMode.values.firstWhere(
        (e) => e.name == modeString,
        orElse: () => .system,
      );
    }

    // Load Seed Color
    final colorInt = prefs.getInt(_colorKey);
    if (colorInt != null) {
      seedColor.value = Color(colorInt);
    }
  }

  /// Updates the mode and saves it to disk
  static Future<void> setMode(ThemeMode mode) async {
    themeMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, mode.name);
  }

  /// Updates the color and saves it to disk
  static Future<void> setSeedColor(Color color) async {
    seedColor.value = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_colorKey, color.toARGB32());
  }
}
