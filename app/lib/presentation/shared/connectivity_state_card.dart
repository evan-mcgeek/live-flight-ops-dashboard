import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

// bordered: true is a floating panel (Map/Detail); false is flat inline content (List).
class ConnectivityStateCard extends StatelessWidget {
  const ConnectivityStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onRetry,
    this.bordered = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onRetry;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colors.danger.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 28, color: colors.danger),
        ),
        SizedBox(height: bordered ? 14 : 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyles.cardTitle(
            colors.textPrimary,
            bordered: bordered,
          ),
        ),
        SizedBox(height: bordered ? 6 : 8),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: bordered ? double.infinity : 250,
          ),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.cardSubtitle(
              bordered ? colors.textSecondary : colors.textTertiary,
              bordered: bordered,
            ),
          ),
        ),
        SizedBox(height: bordered ? 16 : 18),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh, size: 16),
          label: Text(buttonLabel),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.accent,
            foregroundColor: colors.accentInk,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
          ),
        ),
      ],
    );

    if (!bordered) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 56),
          child: content,
        ),
      );
    }

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        margin: const EdgeInsets.all(28),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        decoration: BoxDecoration(
          color: colors.panel,
          border: Border.all(color: colors.line2),
          borderRadius: BorderRadius.circular(18),
        ),
        child: content,
      ),
    );
  }
}
