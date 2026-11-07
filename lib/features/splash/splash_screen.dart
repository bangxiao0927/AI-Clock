import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_logo.dart';

/// Animated splash: the logo draws itself in (badge, ring, hands, spark), the
/// name fades up beneath it, then the app cross-fades into the main screen
/// while the logo flies up into the Home header.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 2600);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _duration,
  )..addStatusListener(_onStatus);

  bool _started = false;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_started) return;
    _started = true;
    if (_reduceMotion) {
      // Show the finished splash for a moment instead of animating it.
      _controller.value = 0.9;
      _controller.animateTo(1, duration: const Duration(milliseconds: 500));
    } else {
      _controller.forward();
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.shell,
      arguments: ShellRouteArgs(instant: _reduceMotion),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Progress (0..1) of the part of the timeline between [begin] and [end].
  double _stage(
    double begin,
    double end, [
    Curve curve = Curves.easeOutCubic,
  ]) => Interval(begin, end, curve: curve).transform(_controller.value);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final badge = _stage(0, 0.30);
          final title = _stage(0.55, 0.80);
          final tagline = _stage(0.68, 0.90);
          return Stack(
            children: [
              // Soft glow behind the logo.
              Positioned.fill(
                child: Opacity(
                  opacity: badge,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0, -0.15),
                        radius: 0.85,
                        colors: [Color(0xFF1A2236), AppColors.background],
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Opacity(
                      opacity: badge,
                      child: Transform.scale(
                        scale: 0.86 + 0.14 * badge,
                        child: SizedBox.square(
                          dimension: 128,
                          child: Hero(
                            tag: AppLogo.heroTag,
                            child: AppLogo(
                              ring: _stage(0.10, 0.50, Curves.easeInOutCubic),
                              hands: _stage(0.25, 0.70),
                              spark: _stage(0.50, 0.70, Curves.easeOutBack),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Opacity(
                      opacity: title,
                      child: Transform.translate(
                        offset: Offset(0, 12 * (1 - title)),
                        child: Text(
                          AppInfo.name,
                          style: textTheme.headlineLarge,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Opacity(
                      opacity: tagline,
                      child: Text(
                        AppInfo.tagline,
                        style: textTheme.bodyLarge?.copyWith(
                          color: AppColors.textMuted,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
