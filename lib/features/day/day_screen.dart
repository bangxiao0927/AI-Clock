import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_time_format.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/placeholder_card.dart';
import '../app_feature.dart';
import '../feature_scaffold.dart';

/// Day: today's date and how much of the day has passed.
class DayScreen extends StatelessWidget {
  const DayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final secondsIntoDay = now.hour * 3600 + now.minute * 60 + now.second;
    final progress = secondsIntoDay / Duration.secondsPerDay;
    final accent = AppFeature.day.color;

    return FeatureScaffold(
      feature: AppFeature.day,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(weekdayName(now), style: textTheme.displaySmall),
              const SizedBox(height: 2),
              Text(
                formatDayMonthYear(now),
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Day progress',
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.textMuted,
                    ),
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
          ),
        ),
        const PlaceholderCard(
          icon: Icons.checklist_rounded,
          title: "Today's plan",
          message: 'Your schedule and reminders for the day will appear here.',
        ),
      ],
    );
  }
}

/// A slim progress bar that eases from empty to [value] when first shown.
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
