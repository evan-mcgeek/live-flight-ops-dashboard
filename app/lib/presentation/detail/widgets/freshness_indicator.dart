import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

// Ticks once a second; the dot blinks off the same timer rather than its own controller.
class FreshnessIndicator extends StatefulWidget {
  const FreshnessIndicator({super.key, required this.lastUpdate});

  final DateTime lastUpdate;

  @override
  State<FreshnessIndicator> createState() => _FreshnessIndicatorState();
}

class _FreshnessIndicatorState extends State<FreshnessIndicator> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _label {
    final elapsed = DateTime.now().difference(widget.lastUpdate.toLocal());
    if (elapsed.inMinutes < 1) return 'Updated ${elapsed.inSeconds}s ago';
    if (elapsed.inHours < 1) return 'Updated ${elapsed.inMinutes}m ago';
    return 'Updated ${elapsed.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: colors.accent.withValues(
              alpha: DateTime.now().second.isEven ? 1.0 : 0.35,
            ),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(_label, style: AppTextStyles.sectionLabel(colors.textTertiary)),
      ],
    );
  }
}
