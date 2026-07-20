import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_strings.dart';
import '../../../core/theme/app_text_styles.dart';

class StaleDataBanner extends StatelessWidget {
  const StaleDataBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: colors.accentDim,
        border: Border.all(color: colors.stale),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 15, color: colors.stale),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppStrings.staleSnapshot,
              style: AppTextStyles.staleBanner(colors.stale),
            ),
          ),
        ],
      ),
    );
  }
}
