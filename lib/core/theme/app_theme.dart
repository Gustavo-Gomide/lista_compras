import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../customization/customization_model.dart';

class AppTheme {
  static ThemeData build(CustomizationModel c) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: c.seedColor,
      brightness: c.brightness,
    );

    TextTheme textTheme;
    try {
      textTheme = GoogleFonts.getTextTheme(
        c.fontFamily,
        ThemeData(brightness: c.brightness).textTheme,
      );
    } catch (_) {
      textTheme = ThemeData(brightness: c.brightness).textTheme;
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
