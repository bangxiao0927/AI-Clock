import 'package:flutter/material.dart';

/// Fades a child in while it rises a few pixels into place.
///
/// Used with increasing [delay]s to stagger lists. Skips the animation when
/// the system asks for reduced motion.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 500),
    this.offset = 14,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Vertical distance, in logical pixels, travelled while fading in.
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  // One controller covers delay + animation, so no timers are needed.
  late final Duration _total = widget.delay + widget.duration;
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _total,
  );
  late final Interval _interval = Interval(
    widget.delay.inMicroseconds / _total.inMicroseconds,
    1,
    curve: Curves.easeOutCubic,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _interval.transform(_controller.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, widget.offset * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}
