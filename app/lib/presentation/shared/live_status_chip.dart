import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_strings.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';

enum LiveStatusChipVariant { loading, live, error }

// One chip for all three states — callers morph between them with a single
// AnimatedSize + AnimatedSwitcher rather than swapping in separate widgets.
class LiveStatusChip extends StatelessWidget {
  const LiveStatusChip({
    super.key,
    this.aircraftCount = 0,
    this.isRefreshing = false,
    this.variant = LiveStatusChipVariant.live,
  });

  final int aircraftCount;
  final bool isRefreshing;
  final LiveStatusChipVariant variant;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final isError = variant == LiveStatusChipVariant.error;
    final dotColor = isError ? colors.danger : colors.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: colors.panel.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: isError ? colors.danger : colors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (variant == LiveStatusChipVariant.loading)
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.8,
                color: colors.textSecondary,
              ),
            )
          else
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 9),
          if (variant == LiveStatusChipVariant.loading)
            Text(
              AppStrings.connecting,
              style: AppTextStyles.chipLabel(colors.textSecondary),
            )
          else if (isError)
            Text(
              AppStrings.error,
              style: AppTextStyles.chipLabel(colors.danger),
            )
          else ...[
            Text(
              AppStrings.live,
              style: AppTextStyles.chipLabel(colors.textPrimary),
            ),
            const SizedBox(width: 9),
            Container(width: 1, height: 14, color: colors.line2),
            const SizedBox(width: 9),
            if (isRefreshing) ...[
              SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
            ],
            AnimatedFlipCounter(
              value: aircraftCount,
              duration: const Duration(milliseconds: 400),
              suffix: ' aircraft',
              textStyle: AppTheme.monospace(
                color: colors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
