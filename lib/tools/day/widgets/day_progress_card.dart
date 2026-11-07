import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_time_format.dart';

/// The Day tool's main card: weekday, date and how much of today has passed.
class DayProgressCard extends StatelessWidget {
  const DayProgressCard({super.key, required this.now, required this.accent});

  final DateTime now;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final secondsIntoDay = now.hour * 3600 + now.minute * 60 + now.second;
    final progress = secondsIntoDay / Duration.secondsPerDay;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(weekdayName(now), style: textTheme.displaySmall),
        const SizedBox(height: 2),
        Text(
          formatDayMonthYear(now),
          style: textTheme.titleMedium?.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Day progress',
              style: textTheme.labelLarge?.copyWith(color: AppColors.textMuted),
            ),
            Text(
              '${(progress * 100).floor()}%',
              style: textTheme.titleMedium?.copyWith(color: accent),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ProgressBar(value: progress, color: accent),
      ],
    );
  }
}

/// A slim progress bar that eases to [value] whenever it changes.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) {
        return SizedBox(
          height: 10,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: AppColors.surfaceHigh),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: animated.clamp(0.0, 1.0),
                    heightFactor: 1,
                    child: ColoredBox(color: color),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
