import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The app background: the base colour with two soft brand-coloured glows.
/// The glows give the glass tab bar something to pick up and refract.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.background),
        const Positioned(
          top: -140,
          left: -100,
          width: 380,
          height: 380,
          child: _Glow(AppColors.brandStart),
        ),
        const Positioned(
          bottom: -160,
          right: -120,
          width: 440,
          height: 440,
          child: _Glow(AppColors.brandEnd),
        ),
        child,
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}
