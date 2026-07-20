import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class Radar extends StatelessWidget {
  const Radar({
    super.key,
    required this.radar,
    required this.colors,
    required this.entrance,
  });

  final Animation<double> radar;
  final Animation<double> entrance;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: AnimatedBuilder(
        animation: Listenable.merge([radar, entrance]),
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.line2),
                ),
              ),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.line2),
                ),
              ),
              _ring(0.0),
              _ring(0.5),
              Transform.rotate(
                angle: radar.value * 2 * math.pi,
                child: ClipOval(
                  child: SizedBox(
                    width: 150,
                    height: 150,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: SweepGradient(
                          colors: [
                            colors.accentDim,
                            colors.accentDim.withValues(alpha: 0),
                          ],
                          stops: const [0, 0.3],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Transform.scale(
                scale: Curves.easeOutBack.transform(
                  entrance.value.clamp(0.0, 1.0),
                ),
                child: Opacity(
                  opacity: entrance.value.clamp(0.0, 1.0),
                  child: Transform.rotate(
                    angle: math.pi / 4,
                    child: Icon(
                      Icons.airplanemode_active,
                      size: 52,
                      color: colors.accent,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _ring(double phaseOffset) {
    final phase = (radar.value + phaseOffset) % 1.0;
    final scale = 0.4 + phase * 0.6;
    final opacity = (1 - phase).clamp(0.0, 1.0);
    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colors.accent, width: 1.5),
          ),
        ),
      ),
    );
  }
}
