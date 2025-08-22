import 'package:crown_micro_solar/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Holds dynamic primary color variations. We keep a base light design and only swap seed/primary.
class ThemeNotifier extends ChangeNotifier {
  ThemeData _themeData;
  Color _primaryColor; // current selected primary

  ThemeNotifier(this._themeData) : _primaryColor = AppTheme.basePrimary;

  ThemeData get themeData => _themeData;
  Color get primaryColor => _primaryColor;

  static const _prefKey = 'primary_color_hex';

  Future<void> setPrimaryColor(Color color) async {
    _primaryColor = color;
    _themeData = AppTheme.buildLightWithPrimary(color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKey, color.value);
    notifyListeners();
  }

  Future<void> resetToDefault() async {
    await setPrimaryColor(AppTheme.basePrimary);
  }

  static Future<ThemeNotifier> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt(_prefKey);
    final color = colorValue != null ? Color(colorValue) : AppTheme.basePrimary;
    return ThemeNotifier(AppTheme.buildLightWithPrimary(color))
      .._primaryColor = color;
  }
}
