import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_time_format.dart';
import 'clock_face.dart';

/// The Clock tool's local-time card: analog face, digital time and the date.
class ClockCard extends StatelessWidget {
  const ClockCard({
    super.key,
    required this.time,
    required this.accent,
    required this.use24Hour,
  });

  final DateTime time;
  final Color accent;
  final bool use24Hour;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hoursMinutes = formatHoursMinutes(time, use24Hour: use24Hour);
    const tabular = [FontFeature.tabularFigures()];

    return Semantics(
      // Announce the time once instead of every second.
      label: 'Current time ${formatClockTime(time, use24Hour: use24Hour)}',
      excludeSemantics: true,
      child: Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: ClockFace(time: time, accent: accent),
          ),
          const SizedBox(height: 20),
          Text.rich(
            TextSpan(
              text: hoursMinutes,
              children: [
                TextSpan(
                  text: ':${twoDigits(time.second)}',
                  style: textTheme.headlineSmall?.copyWith(
                    color: AppColors.textMuted,
                    fontFeatures: tabular,
                  ),
                ),
                if (!use24Hour)
                  TextSpan(
                    text: ' ${meridiem(time)}',
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
            formatFullDate(time),
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
