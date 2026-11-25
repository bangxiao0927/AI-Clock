import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/di/provide.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_time_format.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/ticking_builder.dart';
import '../../tools/clock/alarm/alarms_controller.dart';
import '../../tools/clock/world/world_clock_controller.dart';
import 'widgets/local_clock_card.dart';
import 'widgets/world_clock_tile.dart';

/// Home tab: the app name, a greeting, the local clock and the user's world
/// clocks. Tapping any clock calls [onOpenClock] (the shell opens the Clock
/// tab); the other tools are one tap away in the tab bar.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenClock});

  final VoidCallback onOpenClock;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodyMedium?.copyWith(color: AppColors.textMuted);
    final settings = context.read<AppSettings>();
    final world = context.read<WorldClockController>();
    final alarms = context.read<AlarmsController>();
    // Includes the height of the tab bar, because the shell extends the body
    // behind it.
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    Widget sectionLabel(String text) => Text(
      text,
      style: textTheme.labelMedium?.copyWith(
        color: AppColors.textMuted,
        letterSpacing: 1.4,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset + 24),
              children: [
                Row(
                  children: [
                    SizedBox.square(
                      dimension: 56,
                      child: Hero(tag: AppLogo.heroTag, child: const AppLogo()),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FadeSlideIn(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                AppInfo.name,
                                style: textTheme.headlineMedium,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(AppInfo.tagline, style: muted),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 100),
                  child: TickingBuilder(
                    interval: const Duration(minutes: 1),
                    builder: (context, now) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(greeting(now), style: textTheme.headlineLarge),
                        const SizedBox(height: 4),
                        Text(formatFullDate(now), style: muted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 160),
                  child: sectionLabel('CLOCKS'),
                ),
                const SizedBox(height: 12),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 220),
                  child: ListenableBuilder(
                    listenable: Listenable.merge([settings, alarms]),
                    builder: (context, _) => TickingBuilder(
                      builder: (context, now) => LocalClockCard(
                        now: now,
                        use24Hour: settings.use24Hour(context),
                        nextAlarm: alarms.next,
                        onTap: onOpenClock,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 280),
                  child: sectionLabel('WORLD CLOCKS'),
                ),
                const SizedBox(height: 12),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 340),
                  child: ListenableBuilder(
                    listenable: Listenable.merge([settings, world]),
                    builder: (context, _) {
                      if (world.cities.isEmpty) {
                        return AppCard(
                          onTap: onOpenClock,
                          child: Text(
                            'No world clocks yet. Tap to add cities in Clock.',
                            style: muted,
                          ),
                        );
                      }
                      return TickingBuilder(
                        builder: (context, now) => _WorldGrid(
                          children: [
                            for (final city in world.cities)
                              HomeWorldClockTile(
                                city: city,
                                now: now,
                                use24Hour: settings.use24Hour(context),
                                onTap: onOpenClock,
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lays tiles out two to a row.
class _WorldGrid extends StatelessWidget {
  const _WorldGrid({required this.children});

  final List<Widget> children;

  static const _gap = 12.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - _gap) / 2;
        return Wrap(
          spacing: _gap,
          runSpacing: _gap,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}
