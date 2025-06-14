import 'package:crown_micro_solar/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeData _themeData;

  ThemeNotifier(this._themeData);

  ThemeData get themeData => _themeData;

  Future<void> setTheme(ThemeData themeData) async {
    _themeData = themeData;
    final prefs = await SharedPreferences.getInstance();
    String themeName = 'RedTheme';
    // if (themeData == yellowTheme) {
    //   themeName = 'yellowtheme';
    // } else if (themeData == greentheme) {
    //   themeName = 'greentheme';
    // } else if (themeData == blueTheme) {
    //   themeName = 'bluetheme';
    // }
    await prefs.setString('theme', themeName);
    notifyListeners();
  }
}
