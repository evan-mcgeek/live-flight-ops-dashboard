import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

// Takes a shared animation rather than owning its own controller, so several
// boxes in one loading row stay in phase off a single Ticker.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    required this.animation,
    required this.width,
    required this.height,
    this.borderRadius = 6,
  });

  final Animation<double> animation;
  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final dx = -1.5 + 3 * animation.value;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment(dx - 1, 0),
              end: Alignment(dx + 1, 0),
              colors: [colors.panel, colors.panel2, colors.panel],
            ),
          ),
        );
      },
    );
  }
}

// Mix into any State rendering a skeleton row/grid for one shared shimmer Ticker.
mixin ShimmerTickerMixin<T extends StatefulWidget>
    on State<T>, TickerProviderStateMixin<T> {
  late final AnimationController shimmerController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    shimmerController.dispose();
    super.dispose();
  }
}
