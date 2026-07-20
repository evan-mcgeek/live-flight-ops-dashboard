import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../shared/shimmer_box.dart';

class AircraftListSkeleton extends StatefulWidget {
  const AircraftListSkeleton({super.key});

  @override
  State<AircraftListSkeleton> createState() => _AircraftListSkeletonState();
}

class _AircraftListSkeletonState extends State<AircraftListSkeleton>
    with TickerProviderStateMixin, ShimmerTickerMixin<AircraftListSkeleton> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: 6,
      separatorBuilder: (_, __) => Divider(height: 1, color: colors.line),
      itemBuilder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            ShimmerBox(
              animation: shimmerController,
              width: 20,
              height: 20,
              borderRadius: 10,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(
                    animation: shimmerController,
                    width: 140,
                    height: 16,
                  ),
                  const SizedBox(height: 8),
                  ShimmerBox(
                    animation: shimmerController,
                    width: 90,
                    height: 11,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ShimmerBox(animation: shimmerController, width: 56, height: 13),
                const SizedBox(height: 8),
                ShimmerBox(animation: shimmerController, width: 38, height: 11),
              ],
            ),
            const SizedBox(width: 14),
            ShimmerBox(
              animation: shimmerController,
              width: 44,
              height: 20,
              borderRadius: 10,
            ),
          ],
        ),
      ),
    );
  }
}
