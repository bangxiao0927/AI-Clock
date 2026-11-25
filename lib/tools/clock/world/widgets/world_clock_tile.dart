import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_time_format.dart';
import '../../../../core/widgets/app_card.dart';
import '../../clock_tool.dart';
import '../../widgets/clock_face.dart';
import '../city.dart';
import '../world_clock_controller.dart';
import '../world_time_labels.dart';

/// One city on the world clock: small face, name, day and offset, and the time.
class WorldClockTile extends StatelessWidget {
  const WorldClockTile({
    super.key,
    required this.city,
    required this.now,
    required this.use24Hour,
  });

  final City city;
  final DateTime now;
  final bool use24Hour;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final time = WorldClockController.timeIn(city, now);
    final offset = WorldClockController.offsetFromLocal(city, now);
    final day = isDaytime(time);
    final timeText = formatClockTime(time, use24Hour: use24Hour);
    final detail = '${relativeDayLabel(time, now)} · ${offsetLabel(offset)}';

    return Semantics(
      label: '${city.name}, $timeText, $detail',
      excludeSemantics: true,
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 60,
              child: ClockFace(
                time: time,
                accent: clockInfo.color,
                compact: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    city.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeText,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w400,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Icon(
                  day ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                  size: 16,
                  color: day ? AppColors.dayAccent : AppColors.textMuted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
