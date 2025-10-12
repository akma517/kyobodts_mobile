import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  AppThemeType _currentTheme = AppThemeType.deepBlue;
  
  AppThemeType get currentTheme => _currentTheme;
  ThemeData get themeData => AppTheme.getTheme(_currentTheme);
  bool get isDarkMode => themeData.brightness == Brightness.dark;

  ThemeProvider() {
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme') ?? 0;
    _currentTheme = AppThemeType.values[themeIndex];
    notifyListeners();
  }

  void setTheme(AppThemeType theme) async {
    _currentTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme', theme.index);
    notifyListeners();
  }

  void toggleTheme() {
    // 현재 테마가 다크 모드인지 확인하고 라이트/다크 테마 간 전환
    if (isDarkMode) {
      setTheme(AppThemeType.deepBlue); // 라이트 테마로 전환
    } else {
      setTheme(AppThemeType.dark); // 다크 테마로 전환
    }
  }
}