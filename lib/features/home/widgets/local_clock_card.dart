import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_time_format.dart';
import '../../../core/widgets/app_card.dart';
import '../../../tools/clock/alarm/alarm.dart';
import '../../../tools/clock/clock_tool.dart';
import '../../../tools/clock/widgets/clock_face.dart';

/// The big local clock on Home: analog face, digital time, date, and the next
/// alarm if one is set.
class LocalClockCard extends StatelessWidget {
  const LocalClockCard({
    super.key,
    required this.now,
    required this.use24Hour,
    required this.nextAlarm,
    required this.onTap,
  });

  final DateTime now;
  final bool use24Hour;
  final ({Alarm alarm, DateTime at})? nextAlarm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodyMedium?.copyWith(color: AppColors.textMuted);
    final alarm = nextAlarm;
    const tabular = [FontFeature.tabularFigures()];

    return Semantics(
      button: true,
      label:
          'Local time ${formatClockTime(now, use24Hour: use24Hour)}. Open clock.',
      excludeSemantics: true,
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            SizedBox.square(
              dimension: 112,
              child: ClockFace(time: now, accent: clockInfo.color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Local time', style: muted),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatClockTime(now, use24Hour: use24Hour),
                      style: textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w300,
                        fontFeatures: tabular,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${shortWeekday(now.weekday)}, ${formatDayMonthYear(now)}',
                    style: muted,
                  ),
                  if (alarm != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.alarm_rounded,
                          size: 16,
                          color: AppColors.dayAccent,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${formatClockTime(alarm.at, use24Hour: use24Hour)} · '
                            '${relativeDayLabel(alarm.at, now)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelMedium?.copyWith(
                              color: AppColors.dayAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
