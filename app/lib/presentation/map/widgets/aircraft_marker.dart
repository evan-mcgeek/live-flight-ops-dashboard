import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';

const _fillAssetPath = 'assets/icons/aircraft_marker.svg';
const _outlineAssetPath = 'assets/icons/aircraft_marker_outline.svg';

class AircraftMarker extends StatelessWidget {
  const AircraftMarker({
    super.key,
    required this.headingDegrees,
    required this.onGround,
    this.selected = false,
    this.size = 30,
  });

  final double headingDegrees;
  final bool onGround;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final color = onGround ? colors.ground : colors.accent;
    final effectiveSize = selected ? size + 6 : size;
    // Outline swaps dark/light on selection so it stays visible against any fill/tile combination.
    final outlineColor = selected ? Colors.white : Colors.black;

    return Transform.rotate(
      angle: headingDegrees * (pi / 180),
      // Two layers: the outline behind a dynamically-tinted fill — a single
      // asset can't have both a colorFilter-tinted stroke and fill at once.
      child: Stack(
        alignment: Alignment.center,
        children: [
          SvgPicture.asset(
            _outlineAssetPath,
            width: effectiveSize,
            height: effectiveSize,
            colorFilter: ColorFilter.mode(outlineColor, BlendMode.srcIn),
          ),
          SvgPicture.asset(
            _fillAssetPath,
            width: effectiveSize,
            height: effectiveSize,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
        ],
      ),
    );
  }
}
