import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../shared/connectivity_state_card.dart';

// Overlays the still-visible map rather than replacing it.
class MapStateOverlay extends StatelessWidget {
  const MapStateOverlay({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onRetry,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Positioned.fill(
      child: ColoredBox(
        color: colors.scrim,
        child: ConnectivityStateCard(
          icon: icon,
          title: title,
          subtitle: subtitle,
          buttonLabel: buttonLabel,
          onRetry: onRetry,
        ),
      ),
    );
  }
}
