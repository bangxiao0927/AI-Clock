import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_time_format.dart';
import '../../../../core/widgets/app_card.dart';
import '../alarm.dart';

/// One row in the alarm list: the time, what it is called and when it repeats,
/// and an on/off switch. Dimmed while the alarm is off.
class AlarmTile extends StatelessWidget {
  const AlarmTile({
    super.key,
    required this.alarm,
    required this.use24Hour,
    required this.onTap,
    required this.onToggle,
  });

  final Alarm alarm;
  final bool use24Hour;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final time = DateTime(2000, 1, 1, alarm.hour, alarm.minute);
    final hoursMinutes = formatHoursMinutes(time, use24Hour: use24Hour);
    final subtitle = alarm.label.isEmpty
        ? alarm.repeatSummary
        : '${alarm.label} · ${alarm.repeatSummary}';

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
      child: Opacity(
        opacity: alarm.enabled ? 1 : 0.5,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      text: hoursMinutes,
                      children: [
                        if (!use24Hour)
                          TextSpan(
                            text: ' ${meridiem(time)}',
                            style: textTheme.titleMedium?.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                    style: textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w300,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Switch(value: alarm.enabled, onChanged: onToggle),
          ],
        ),
      ),
    );
  }
}
