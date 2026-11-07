import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Where the logo's gradient badge is drawn.
enum LogoBackground {
  /// Rounded-square badge (in-app logo, legacy Android icon).
  rounded,

  /// Full-bleed square (iOS app icon; the system applies the mask).
  square,

  /// No badge, glyph only (Android adaptive-icon foreground).
  none,
}

/// The app logo: a clock face whose 12 o'clock mark is an AI spark.
///
/// The widget fills the space it is given, so size it from the outside with a
/// [SizedBox]. [ring], [hands] and [spark] are 0..1 draw-in progress values
/// used by the splash animation; at 1 the logo is in its final, static pose.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.ring = 1,
    this.hands = 1,
    this.spark = 1,
    this.background = LogoBackground.rounded,
  });

  /// Shared [Hero] tag so the splash logo flies into the menu header.
  static const heroTag = 'app-logo';

  final double ring;
  final double hands;
  final double spark;
  final LogoBackground background;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'App logo',
      image: true,
      child: CustomPaint(
        size: Size.infinite,
        painter: LogoPainter(
          background: background,
          ring: ring,
          hands: hands,
          spark: spark,
        ),
      ),
    );
  }
}

/// Paints the logo. Also used by `tool/generate_icons.dart` to render the
/// launcher icons, so the in-app logo and the icons always match.
class LogoPainter extends CustomPainter {
  const LogoPainter({
    this.background = LogoBackground.rounded,
    this.ring = 1,
    this.hands = 1,
    this.spark = 1,
    this.glyphScale = 1,
  });

  final LogoBackground background;
  final double ring;
  final double hands;
  final double spark;

  /// Scales the glyph around the centre (used to fit the adaptive-icon safe zone).
  final double glyphScale;

  // Final pose is 10:10, as clockwise radians from 12 o'clock. The minute hand
  // adds a full extra turn while animating; the hour hand swings back to -55°.
  static const _minuteAngle = math.pi / 3;
  static const _hourAngle = -55 * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    canvas.save();
    canvas.translate((size.width - s) / 2, (size.height - s) / 2);
    _paintBackground(canvas, s);
    canvas.translate(s / 2, s / 2);
    canvas.scale(glyphScale);
    _paintGlyph(canvas, s);
    canvas.restore();
  }

  void _paintBackground(Canvas canvas, double s) {
    if (background == LogoBackground.none) return;
    final rect = Offset.zero & Size.square(s);
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.brandStart, AppColors.brandEnd],
      ).createShader(rect);
    if (background == LogoBackground.square) {
      canvas.drawRect(rect, paint);
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(s * 0.225)),
        paint,
      );
    }
  }

  /// Draws the glyph with the origin at the centre of the logo.
  void _paintGlyph(Canvas canvas, double s) {
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Ring, open at 12 o'clock to make room for the spark.
    const gap = 0.82;
    final sweep = (2 * math.pi - gap) * ring.clamp(0.0, 1.0);
    if (sweep > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: 0.30 * s),
        -math.pi / 2 + gap / 2,
        sweep,
        false,
        stroke..strokeWidth = 0.05 * s,
      );
    }

    // Hands: start together at 12 and open into the 10:10 pose.
    final t = hands.clamp(0.0, 1.0);
    void hand(double angle, double length) {
      final tip = Offset(math.sin(angle), -math.cos(angle)) * (length * s);
      canvas.drawLine(Offset.zero, tip, stroke..strokeWidth = 0.045 * s);
    }

    hand(_hourAngle * t, 0.135);
    hand((_minuteAngle + 2 * math.pi) * t, 0.20);
    canvas.drawCircle(Offset.zero, 0.034 * s, Paint()..color = Colors.white);

    // Four-point spark sitting in the gap of the ring.
    if (spark > 0) {
      final c = Offset(0, -0.30 * s);
      final r = 0.078 * s * spark;
      final k = r * 0.16;
      final path = Path()
        ..moveTo(c.dx, c.dy - r)
        ..quadraticBezierTo(c.dx + k, c.dy - k, c.dx + r, c.dy)
        ..quadraticBezierTo(c.dx + k, c.dy + k, c.dx, c.dy + r)
        ..quadraticBezierTo(c.dx - k, c.dy + k, c.dx - r, c.dy)
        ..quadraticBezierTo(c.dx - k, c.dy - k, c.dx, c.dy - r)
        ..close();
      canvas.drawPath(path, Paint()..color = AppColors.spark);
    }
  }

  @override
  bool shouldRepaint(LogoPainter old) =>
      old.background != background ||
      old.ring != ring ||
      old.hands != hands ||
      old.spark != spark ||
      old.glyphScale != glyphScale;
}
