import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const navy = Color(0xFF0B1F3A);
  static const orange = Color(0xFFFF6B35);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: orange,
      brightness: brightness,
      primary: brightness == Brightness.light ? navy : orange,
      secondary: orange,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? const Color(0xFFF7F8FA)
          : null,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      cardTheme: const CardThemeData(margin: EdgeInsets.symmetric(vertical: 6)),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
      ),
    );
  }
}
