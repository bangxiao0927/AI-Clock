import 'package:flutter/material.dart';

import '../di/provide.dart';
import '../settings/app_settings.dart';
import '../theme/app_theme.dart';

/// The app background: the base colour with two soft glows whose colours come
/// from the user's [BackgroundStyle] setting. The glows give the glass tab bar
/// something to pick up and refract; the "plain" style has none.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final settings = context.maybeRead<AppSettings>();
    if (settings == null) {
      return _Ambient(style: BackgroundStyle.aurora, child: child);
    }
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) =>
          _Ambient(style: settings.background, child: child),
    );
  }
}

class _Ambient extends StatelessWidget {
  const _Ambient({required this.style, required this.child});

  final BackgroundStyle style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.background),
        Positioned(
          top: -140,
          left: -100,
          width: 380,
          height: 380,
          child: _Glow(style.glowA),
        ),
        Positioned(
          bottom: -160,
          right: -120,
          width: 440,
          height: 440,
          child: _Glow(style.glowB),
        ),
        child,
      ],
    );
  }
}

/// A radial glow that fades smoothly when its colour changes.
class _Glow extends StatelessWidget {
  const _Glow(this.color);

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final base = color ?? Colors.transparent;
    final centre = color == null ? base : base.withValues(alpha: 0.22);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [centre, base.withValues(alpha: 0)]),
      ),
    );
  }
}
