import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_time_format.dart';
import '../../../core/widgets/app_card.dart';
import '../../../tools/clock/clock_tool.dart';
import '../../../tools/clock/widgets/clock_face.dart';
import '../../../tools/clock/world/city.dart';
import '../../../tools/clock/world/world_clock_controller.dart';
import '../../../tools/clock/world/world_time_labels.dart';

/// A compact world-clock tile for the Home grid: small face, city, time, and
/// how it relates to the local time.
class HomeWorldClockTile extends StatelessWidget {
  const HomeWorldClockTile({
    super.key,
    required this.city,
    required this.now,
    required this.use24Hour,
    required this.onTap,
  });

  final City city;
  final DateTime now;
  final bool use24Hour;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final time = WorldClockController.timeIn(city, now);
    final offset = WorldClockController.offsetFromLocal(city, now);
    final day = isDaytime(time);

    return Semantics(
      button: true,
      label:
          '${city.name}, ${formatClockTime(time, use24Hour: use24Hour)}, '
          '${relativeDayLabel(time, now)}, ${offsetLabel(offset)}',
      excludeSemantics: true,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox.square(
                  dimension: 56,
                  child: ClockFace(
                    time: time,
                    accent: clockInfo.color,
                    compact: true,
                  ),
                ),
                const Spacer(),
                Icon(
                  day ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                  size: 18,
                  color: day ? AppColors.dayAccent : AppColors.textMuted,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              city.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 2),
            Text(
              formatClockTime(time, use24Hour: use24Hour),
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w400,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${relativeDayLabel(time, now)} · ${offsetLabel(offset)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
