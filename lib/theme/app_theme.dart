import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color.fromARGB(255, 21, 255, 0),
      brightness: Brightness.light,
    ),
    brightness: Brightness.light,
  );

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color.fromARGB(255, 30, 255, 0),
      brightness: Brightness.dark,
    ),
    brightness: Brightness.dark,
  );
}
