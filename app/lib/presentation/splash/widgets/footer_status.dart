import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_strings.dart';
import '../../../core/theme/app_theme.dart';

class FooterStatus extends StatelessWidget {
  const FooterStatus({super.key, required this.radar, required this.colors});

  final Animation<double> radar;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: radar,
      builder: (context, _) {
        final blink =
            (math.sin(radar.value * 2 * math.pi * (2600 / 1400)) + 1) / 2;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: 0.4 + blink * 0.6,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.accent,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              AppStrings.connectingToLiveFeed,
              style: AppTheme.monospace(
                color: colors.textTertiary,
                fontSize: 12,
              ),
            ),
          ],
        );
      },
    );
  }
}
