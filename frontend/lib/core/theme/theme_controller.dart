import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_accent.dart';
import 'app_theme.dart';

/// Holds the user's display preferences (light/dark + accent color) and
/// persists them. Drives [MaterialApp] theme selection and powers the
/// in-app "display" settings button.
class ThemeController extends ChangeNotifier {
  static const _kModeKey = 'display_theme_mode';
  static const _kAccentKey = 'display_theme_accent';

  ThemeMode _mode = ThemeMode.light;
  AppAccent _accent = AppAccent.camel;

  ThemeMode get mode => _mode;
  AppAccent get accent => _accent;
  bool get isDark => _mode == ThemeMode.dark;

  ThemeData get lightTheme =>
      AppTheme.build(brightness: Brightness.light, accent: _accent);
  ThemeData get darkTheme =>
      AppTheme.build(brightness: Brightness.dark, accent: _accent);

  /// Loads saved preferences from disk. Safe to call once at startup.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedAccent = AppAccent.tryFromName(prefs.getString(_kAccentKey));
      if (savedAccent == null) {
        // Stale/removed preference (e.g. old palette) — reset to defaults.
        _mode = ThemeMode.light;
        _accent = AppAccent.camel;
      } else {
        _accent = savedAccent;
        final modeName = prefs.getString(_kModeKey);
        _mode = ThemeMode.values.firstWhere(
          (m) => m.name == modeName,
          orElse: () => ThemeMode.light,
        );
      }
    } catch (_) {
      // Keep defaults on any storage error.
    }
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    await _persist(_kModeKey, mode.name);
  }

  Future<void> toggleDarkMode() =>
      setMode(isDark ? ThemeMode.light : ThemeMode.dark);

  Future<void> setAccent(AppAccent accent) async {
    if (_accent == accent) return;
    _accent = accent;
    notifyListeners();
    await _persist(_kAccentKey, accent.name);
  }

  Future<void> _persist(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (_) {
      // Non-fatal: preference just won't survive a restart.
    }
  }
}
