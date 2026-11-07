import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// A minimal analog clock face showing [time].
class ClockFace extends StatelessWidget {
  const ClockFace({super.key, required this.time, required this.accent});

  final DateTime time;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(painter: _ClockFacePainter(time, accent)),
    );
  }
}

class _ClockFacePainter extends CustomPainter {
  const _ClockFacePainter(this.time, this.accent);

  final DateTime time;
  final Color accent;

  static Offset _direction(double degrees) {
    final radians = degrees * math.pi / 180;
    return Offset(math.sin(radians), -math.cos(radians));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    // Dial.
    canvas.drawCircle(center, radius, Paint()..color = AppColors.surfaceHigh);
    canvas.drawCircle(
      center,
      radius - 0.5,
      Paint()
        ..color = AppColors.outline
        ..style = PaintingStyle.stroke,
    );

    // Minute and hour ticks.
    final tick = Paint()..strokeCap = StrokeCap.round;
    for (var i = 0; i < 60; i++) {
      final isHour = i % 5 == 0;
      final dir = _direction(i * 6.0);
      final outer = radius * 0.92;
      final inner = outer - radius * (isHour ? 0.09 : 0.035);
      canvas.drawLine(
        center + dir * inner,
        center + dir * outer,
        tick
          ..strokeWidth = isHour ? 2.5 : 1
          ..color = isHour
              ? AppColors.textPrimary
              : AppColors.textMuted.withValues(alpha: 0.5),
      );
    }

    // Hands.
    final second = time.second.toDouble();
    final minute = time.minute + second / 60;
    final hour = (time.hour % 12) + minute / 60;

    void hand(double degrees, double length, double width, Color color) {
      canvas.drawLine(
        center,
        center + _direction(degrees) * (radius * length),
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }

    hand(hour * 30, 0.5, radius * 0.045, AppColors.textPrimary);
    hand(minute * 6, 0.74, radius * 0.03, AppColors.textPrimary);
    hand(second * 6, 0.82, 1.5, accent);
    canvas.drawCircle(center, radius * 0.045, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(_ClockFacePainter old) =>
      old.time != time || old.accent != accent;
}
