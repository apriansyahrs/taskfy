import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadSavedThemeMode();
  }

  static const String _themeModeKey = 'theme_mode';

  Future<void> _loadSavedThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedThemeMode = prefs.getString(_themeModeKey);
    
    if (savedThemeMode != null) {
      switch (savedThemeMode) {
        case 'light':
          state = ThemeMode.light;
          break;
        case 'dark':
          state = ThemeMode.dark;
          break;
        default:
          state = ThemeMode.system;
      }
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    
    switch (mode) {
      case ThemeMode.light:
        await prefs.setString(_themeModeKey, 'light');
        break;
      case ThemeMode.dark:
        await prefs.setString(_themeModeKey, 'dark');
        break;
      case ThemeMode.system:
        await prefs.setString(_themeModeKey, 'system');
        break;
    }
    
    state = mode;
  }

  void toggleTheme() {
    if (state == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else if (state == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.light);
    }
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});
