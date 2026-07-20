import 'package:flight_ops_app/core/theme/app_colors.dart';
import 'package:flight_ops_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme', () {
    testWidgets(
      'darkTheme and lightTheme build without throwing and carry AppColors',
      (tester) async {
        final dark = AppTheme.darkTheme;
        final light = AppTheme.lightTheme;

        expect(dark.extension<AppColors>(), AppColors.dark);
        expect(light.extension<AppColors>(), AppColors.light);
      },
    );

    test('dark and light AppColors are distinct', () {
      expect(AppColors.dark, isNot(equals(AppColors.light)));
    });

    test('monospace applies the IBM Plex Mono font family', () {
      final style = AppTheme.monospace(color: const Color(0xFFFFFFFF));

      expect(style.fontFamily, contains('IBMPlexMono'));
    });
  });
}
