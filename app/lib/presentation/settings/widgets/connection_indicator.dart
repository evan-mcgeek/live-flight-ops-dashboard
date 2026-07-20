import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../bloc/settings_bloc.dart';

// Error deliberately shows no dot/icon — only the other three states get one.
class ConnectionIndicator extends StatelessWidget {
  const ConnectionIndicator({super.key, required this.state});

  final SettingsState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final Widget? indicator;
    final String label;
    switch (state.connectionStatus) {
      case ConnectionConnecting():
        indicator = const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
        label = AppStrings.connecting;
      case ConnectionError():
        indicator = null;
        label = AppStrings.error;
      case ConnectionConnected():
        indicator = _Dot(color: colors.accent);
        label = AppStrings.connected;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (indicator != null) ...[indicator, const SizedBox(width: 7)],
        Text(
          label,
          style: AppTheme.monospace(color: colors.textPrimary, fontSize: 14),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
