import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A simple singleton that holds and persists the user's theme preference.
class ThemeProvider extends ValueNotifier<ThemeMode> {
  static final ThemeProvider _instance = ThemeProvider._internal();
  factory ThemeProvider() => _instance;

  static const _key = 'theme_mode';

  ThemeProvider._internal() : super(ThemeMode.light);

  /// Call once at app start to load saved preference.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved == 'dark') {
      value = ThemeMode.dark;
    } else {
      value = ThemeMode.light;
    }
  }

  bool get isDark => value == ThemeMode.dark;

  Future<void> toggleTheme() async {
    value = isDark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, isDark ? 'dark' : 'light');
  }
}
