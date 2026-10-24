import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const charcoal = Color(0xFF282828);
  static const pink = Color(0xFFFF5ABB);
  static const lime = Color(0xFFCCFF00);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: pink,
      brightness: brightness,
      primary: brightness == Brightness.light ? charcoal : pink,
      secondary: lime,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? const Color(0xFFFFF9FC)
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
