import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get darkTheme => _themeFor(AppColors.dark, Brightness.dark);

  static ThemeData get lightTheme =>
      _themeFor(AppColors.light, Brightness.light);

  static ThemeData _themeFor(AppColors colors, Brightness brightness) {
    final textTheme = GoogleFonts.barlowTextTheme().apply(
      bodyColor: colors.textPrimary,
      displayColor: colors.textPrimary,
    );

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.canvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.accent,
        brightness: brightness,
        surface: colors.panel,
      ),
      textTheme: textTheme,
      extensions: [colors],
    );
  }

  // IBM Plex Mono for data values (callsigns, coordinates, altitude/velocity, timestamps).
  static TextStyle monospace({
    required Color color,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return GoogleFonts.ibmPlexMono(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }
}
