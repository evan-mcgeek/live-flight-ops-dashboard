import 'package:flutter/material.dart';

// Named text styles, matching AppTheme.monospace's shape (color passed in,
// not the whole AppColors) — every non-monospace TextStyle in the app goes
// through one of these instead of an ad hoc TextStyle(...) call.
class AppTextStyles {
  const AppTextStyles._();

  static TextStyle sectionLabel(Color color) =>
      TextStyle(color: color, fontSize: 12);

  static TextStyle body(Color color) => TextStyle(color: color);

  static TextStyle caption(Color color) =>
      TextStyle(color: color, fontSize: 13.5);

  static TextStyle microLabel(Color color) =>
      TextStyle(color: color, fontSize: 11);

  static TextStyle fieldLabel(Color color) =>
      TextStyle(color: color, fontSize: 14);

  static TextStyle badge(Color color) =>
      TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12);

  static TextStyle chipLabel(Color color) =>
      TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13);

  static TextStyle navLabel(Color color) =>
      TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13.5);

  static TextStyle staleBanner(Color color) =>
      TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 12);

  static TextStyle eyebrow(Color color) => TextStyle(
    color: color,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 4,
  );

  static TextStyle wordmark(Color color) => TextStyle(
    color: color,
    fontSize: 27,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  static TextStyle cardTitle(Color color, {required bool bordered}) =>
      TextStyle(
        color: color,
        fontSize: bordered ? 18 : 17,
        fontWeight: FontWeight.w700,
      );

  static TextStyle cardSubtitle(Color color, {required bool bordered}) =>
      TextStyle(color: color, fontSize: bordered ? 13.5 : 14, height: 1.45);
}
