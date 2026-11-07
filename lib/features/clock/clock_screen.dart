import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_time_format.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/placeholder_card.dart';
import '../app_feature.dart';
import '../feature_scaffold.dart';
import 'clock_face.dart';

/// Clock: the current time, live, on an analog face and as digits.
class ClockScreen extends StatefulWidget {
  const ClockScreen({super.key});

  @override
  State<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen> {
  late final Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _now = DateTime.now()),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final use24Hour = MediaQuery.alwaysUse24HourFormatOf(context);
    final hoursMinutes = formatHoursMinutes(_now, use24Hour: use24Hour);
    const tabular = [FontFeature.tabularFigures()];

    return FeatureScaffold(
      feature: AppFeature.clock,
      children: [
        AppCard(
          // Announce the time once instead of every second.
          child: Semantics(
            label:
                'Current time $hoursMinutes ${use24Hour ? '' : meridiem(_now)}',
            excludeSemantics: true,
            child: Column(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: ClockFace(time: _now, accent: AppFeature.clock.color),
                ),
                const SizedBox(height: 24),
                Text.rich(
                  TextSpan(
                    text: hoursMinutes,
                    children: [
                      TextSpan(
                        text: ':${twoDigits(_now.second)}',
                        style: textTheme.headlineSmall?.copyWith(
                          color: AppColors.textMuted,
                          fontFeatures: tabular,
                        ),
                      ),
                      if (!use24Hour)
                        TextSpan(
                          text: ' ${meridiem(_now)}',
                          style: textTheme.titleMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                  style: textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w300,
                    fontFeatures: tabular,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatFullDate(_now),
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        const PlaceholderCard(
          icon: Icons.alarm_rounded,
          title: 'Alarms & timers',
          message: 'Alarms, timers and world clocks will live here.',
        ),
      ],
    );
  }
}
