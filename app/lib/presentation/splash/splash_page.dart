import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'widgets/fill_bar.dart';
import 'widgets/footer_status.dart';
import 'widgets/radar.dart';
import 'widgets/wordmark.dart';

// Matches the mockup's Splash screen: radar sweep + plane + wordmark + fill bar.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key, required this.child});

  final Widget child;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final _radar = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();
  late final _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2500),
  )..forward();
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _entrance.addStatusListener((status) {
      if (status == AnimationStatus.completed) setState(() => _done = true);
    });
  }

  @override
  void dispose() {
    _radar.dispose();
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;
    final colors = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      backgroundColor: colors.background,
      // SizedBox.expand forces the Stack to fill the screen (Scaffold's body gives loose constraints).
      body: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [colors.accentDim, colors.background],
                    radius: 0.9,
                  ),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radar(radar: _radar, colors: colors, entrance: _entrance),
                const SizedBox(height: 26),
                Wordmark(entrance: _entrance, colors: colors),
                const SizedBox(height: 30),
                FillBar(entrance: _entrance, colors: colors),
              ],
            ),
            Positioned(
              bottom: 52,
              child: FooterStatus(radar: _radar, colors: colors),
            ),
          ],
        ),
      ),
    );
  }
}
