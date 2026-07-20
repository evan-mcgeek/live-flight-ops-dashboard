import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.canvas,
    required this.background,
    required this.panel,
    required this.panel2,
    required this.line,
    required this.line2,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.accentInk,
    required this.accentDim,
    required this.ground,
    required this.stale,
    required this.danger,
    required this.scrim,
  });

  final Color canvas;
  final Color background;
  final Color panel;
  final Color panel2;
  final Color line;
  final Color line2;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color accent;
  final Color accentInk;
  final Color accentDim;
  final Color ground;
  final Color stale;
  final Color danger;
  final Color scrim;

  static const dark = AppColors(
    canvas: Color(0xFF0C1017),
    background: Color(0xFF0A0F17),
    panel: Color(0xFF111A27),
    panel2: Color(0xFF16202F),
    line: Color(0x14FFFFFF),
    line2: Color(0x26FFFFFF),
    textPrimary: Color(0xFFE8EEF7),
    textSecondary: Color(0xFF9FB0C6),
    textTertiary: Color(0xFF63748D),
    accent: Color(0xFF38E1C4),
    accentInk: Color(0xFF04150F),
    accentDim: Color(0x2438E1C4),
    ground: Color(0xFFF5A623),
    stale: Color(0xFFF5A623),
    danger: Color(0xFFFF5470),
    scrim: Color(0x8C000000),
  );

  static const light = AppColors(
    canvas: Color(0xFFDFE3EA),
    background: Color(0xFFEEF1F6),
    panel: Color(0xFFFFFFFF),
    panel2: Color(0xFFF4F6FA),
    line: Color(0x170F192D),
    line2: Color(0x290F192D),
    textPrimary: Color(0xFF0E1728),
    textSecondary: Color(0xFF57677F),
    textTertiary: Color(0xFF8A97AB),
    accent: Color(0xFF0EA28C),
    accentInk: Color(0xFFFFFFFF),
    accentDim: Color(0x1F0EA28C),
    ground: Color(0xFFC77D0A),
    stale: Color(0xFFC77D0A),
    danger: Color(0xFFE02F52),
    scrim: Color(0x8C000000),
  );

  @override
  AppColors copyWith({
    Color? canvas,
    Color? background,
    Color? panel,
    Color? panel2,
    Color? line,
    Color? line2,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? accent,
    Color? accentInk,
    Color? accentDim,
    Color? ground,
    Color? stale,
    Color? danger,
    Color? scrim,
  }) {
    return AppColors(
      canvas: canvas ?? this.canvas,
      background: background ?? this.background,
      panel: panel ?? this.panel,
      panel2: panel2 ?? this.panel2,
      line: line ?? this.line,
      line2: line2 ?? this.line2,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      accent: accent ?? this.accent,
      accentInk: accentInk ?? this.accentInk,
      accentDim: accentDim ?? this.accentDim,
      ground: ground ?? this.ground,
      stale: stale ?? this.stale,
      danger: danger ?? this.danger,
      scrim: scrim ?? this.scrim,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      background: Color.lerp(background, other.background, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      panel2: Color.lerp(panel2, other.panel2, t)!,
      line: Color.lerp(line, other.line, t)!,
      line2: Color.lerp(line2, other.line2, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentInk: Color.lerp(accentInk, other.accentInk, t)!,
      accentDim: Color.lerp(accentDim, other.accentDim, t)!,
      ground: Color.lerp(ground, other.ground, t)!,
      stale: Color.lerp(stale, other.stale, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
    );
  }
}
