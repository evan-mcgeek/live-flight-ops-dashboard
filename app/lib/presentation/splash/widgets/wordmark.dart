import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_strings.dart';
import '../../../core/theme/app_text_styles.dart';

class Wordmark extends StatelessWidget {
  const Wordmark({super.key, required this.entrance, required this.colors});

  final Animation<double> entrance;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: entrance,
      builder: (context, _) {
        final t = ((entrance.value - 0.15) / 0.4).clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 10),
            child: Column(
              children: [
                Text(
                  AppStrings.appNameEyebrow,
                  style: AppTextStyles.eyebrow(colors.accent),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.appNameWordmark,
                  style: AppTextStyles.wordmark(colors.textPrimary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
