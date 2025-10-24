import 'package:flutter/material.dart';

enum AppThemeType {
  deepBlue,
  deepPurple,
  deepGreen,
  dark,
  light,
}

class AppTheme {
  static ThemeData getTheme(AppThemeType type) {
    switch (type) {
      case AppThemeType.deepBlue:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue[900]!,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        );
      case AppThemeType.deepPurple:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        );
      case AppThemeType.deepGreen:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green[900]!,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        );
      case AppThemeType.dark:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue[900]!,
            brightness: Brightness.dark,
          ).copyWith(
            surface: const Color(0xFF1E1E1E),
            surfaceContainerHighest: const Color(0xFF2A2A2A),
            outline: const Color(0xFF606060),
            outlineVariant: const Color(0xFF505050),
          ),
          useMaterial3: true,
          cardTheme: const CardThemeData(
            color: Color(0xFF2A2A2A),
            elevation: 2,
          ),
          dividerTheme: const DividerThemeData(
            color: Color(0xFF505050),
            thickness: 0.5,
          ),
        );
      case AppThemeType.light:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue[100]!,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        );
    }
  }

  static String getThemeName(AppThemeType type) {
    switch (type) {
      case AppThemeType.deepBlue:
        return '딥 블루';
      case AppThemeType.deepPurple:
        return '딥 퍼플';
      case AppThemeType.deepGreen:
        return '딥 그린';
      case AppThemeType.dark:
        return '다크';
      case AppThemeType.light:
        return '라이트';
    }
  }
}