import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// A circular countdown: a faint track with a coloured arc that shrinks as
/// time runs out. [remaining] goes from 1 (just started) to 0 (done).
class TimerRing extends StatelessWidget {
  const TimerRing({
    super.key,
    required this.remaining,
    required this.color,
    required this.child,
    this.size = 240,
  });

  final double remaining;
  final Color color;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _RingPainter(remaining.clamp(0.0, 1.0), color),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.remaining, this.color);

  final double remaining;
  final Color color;

  static const _stroke = 10.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(_stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      arcRect,
      0,
      2 * math.pi,
      false,
      paint..color = AppColors.surfaceHigh,
    );
    if (remaining > 0) {
      canvas.drawArc(
        arcRect,
        -math.pi / 2,
        2 * math.pi * remaining,
        false,
        paint..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.remaining != remaining || old.color != color;
}
