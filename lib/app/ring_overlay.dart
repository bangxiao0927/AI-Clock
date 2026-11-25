import 'package:flutter/material.dart';

import '../core/di/provide.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/glass_container.dart';
import 'alerts_controller.dart';

/// Shows the ringing alert (alarm, timer or reminder) as a glass banner at the
/// top of the screen, above every route, so it is seen from anywhere in the
/// app, including a note being edited.
class RingOverlay extends StatelessWidget {
  const RingOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final alerts = context.maybeRead<AlertsController>();
    if (alerts == null) return child;

    return Stack(
      children: [
        child,
        ListenableBuilder(
          listenable: alerts,
          builder: (context, _) {
            final alert = alerts.current;
            return Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween(
                              begin: const Offset(0, -0.4),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: alert == null
                            ? const SizedBox.shrink(key: ValueKey('none'))
                            : _RingBanner(
                                key: ValueKey(alert),
                                alert: alert,
                                onDismiss: alerts.dismiss,
                                onSnooze: alerts.snooze,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _RingBanner extends StatelessWidget {
  const _RingBanner({
    super.key,
    required this.alert,
    required this.onDismiss,
    required this.onSnooze,
  });

  final RingingAlert alert;
  final VoidCallback onDismiss;
  final VoidCallback onSnooze;

  (IconData, Color) get _style => switch (alert.kind) {
    AlertKind.alarm => (Icons.alarm_rounded, AppColors.dayAccent),
    AlertKind.timer => (Icons.timer_rounded, AppColors.clockAccent),
    AlertKind.reminder => (
      Icons.notifications_active_rounded,
      AppColors.notesAccent,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (icon, color) = _style;

    return Material(
      type: MaterialType.transparency,
      child: Semantics(
        liveRegion: true,
        label: '${alert.title}, ${alert.subtitle}',
        child: GlassContainer(
          borderRadius: BorderRadius.circular(28),
          blur: 30,
          tint: 0.12,
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium,
                    ),
                    Text(
                      alert.subtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (alert.canSnooze)
                TextButton(onPressed: onSnooze, child: const Text('Snooze')),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: AppColors.background,
                ),
                onPressed: onDismiss,
                child: Text(alert.canSnooze ? 'Stop' : 'OK'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
