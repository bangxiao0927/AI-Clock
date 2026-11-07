import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// A frosted-glass surface in the spirit of Apple's translucent materials:
/// whatever is behind it is blurred, a faint white tint lifts it off the
/// background, and a thin gradient edge catches the "light" at the top-left.
///
/// Only use it where content really scrolls or sits behind it (the tab bar):
/// every glass surface costs a backdrop blur per frame.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
    this.blur = 24,
    this.tint = 0.08,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final BorderRadius borderRadius;

  /// Blur strength (Gaussian sigma) applied to what is behind the glass.
  final double blur;

  /// Opacity of the white tint at the bottom edge; the top is slightly brighter.
  final double tint;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: CustomPaint(
          foregroundPainter: _GlassEdgePainter(borderRadius),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: tint + 0.06),
                  Colors.white.withValues(alpha: tint),
                ],
              ),
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// A 1px edge that is bright at the top-left, fades through the middle and
/// picks up a faint reflection at the bottom-right.
class _GlassEdgePainter extends CustomPainter {
  const _GlassEdgePainter(this.borderRadius);

  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      borderRadius.toRRect(rect).deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.50),
            Colors.white.withValues(alpha: 0.10),
            Colors.white.withValues(alpha: 0.04),
            Colors.white.withValues(alpha: 0.22),
          ],
          stops: const [0, 0.35, 0.7, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_GlassEdgePainter old) => old.borderRadius != borderRadius;
}
