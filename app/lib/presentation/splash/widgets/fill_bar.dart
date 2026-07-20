import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class FillBar extends StatelessWidget {
  const FillBar({super.key, required this.entrance, required this.colors});

  final Animation<double> entrance;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: entrance,
      builder: (context, _) {
        final t = ((entrance.value - 0.2) / 0.8).clamp(0.0, 1.0);
        return Container(
          width: 150,
          height: 3,
          decoration: BoxDecoration(
            color: colors.line2,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: t,
              child: Container(
                decoration: BoxDecoration(
                  color: colors.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
