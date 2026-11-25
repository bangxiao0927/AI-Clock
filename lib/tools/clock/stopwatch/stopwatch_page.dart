import 'package:flutter/material.dart';

import '../../../core/di/provide.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_time_format.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/ticking_builder.dart';
import '../widgets/round_action_button.dart';
import 'stopwatch_controller.dart';

/// Stopwatch section: start, stop, lap and reset. The time keeps running while
/// the user is on another tab.
class StopwatchPage extends StatelessWidget {
  const StopwatchPage({super.key});

  static const _green = Color(0xFF4ADE80);
  static const _red = Color(0xFFF87171);

  @override
  Widget build(BuildContext context) {
    final stopwatch = context.read<StopwatchController>();
    final textTheme = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: stopwatch,
      builder: (context, _) {
        final laps = stopwatch.laps;
        final extremes = stopwatch.extremes;
        return Column(
          children: [
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              child: Column(
                children: [
                  // Redraw about 30 times a second while visible.
                  TickingBuilder(
                    interval: const Duration(milliseconds: 33),
                    builder: (context, _) => FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Semantics(
                        label:
                            'Stopwatch ${formatStopwatch(stopwatch.elapsed)}',
                        excludeSemantics: true,
                        child: Text(
                          formatStopwatch(stopwatch.elapsed),
                          style: textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.w200,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RoundActionButton(
                        label: stopwatch.running ? 'Lap' : 'Reset',
                        color: AppColors.textPrimary,
                        onPressed: stopwatch.running
                            ? stopwatch.lap
                            : stopwatch.hasTime
                            ? stopwatch.reset
                            : null,
                      ),
                      RoundActionButton(
                        label: stopwatch.running ? 'Stop' : 'Start',
                        color: stopwatch.running ? _red : _green,
                        onPressed: stopwatch.toggle,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (laps.isNotEmpty) ...[
              const SizedBox(height: 16),
              AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    for (final lap in laps)
                      _LapRow(
                        lap: lap,
                        color: extremes == null
                            ? null
                            : lap.number == extremes.fastest.number
                            ? _green
                            : lap.number == extremes.slowest.number
                            ? _red
                            : null,
                      ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _LapRow extends StatelessWidget {
  const _LapRow({required this.lap, required this.color});

  final Lap lap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = textTheme.bodyLarge?.copyWith(
      color: color ?? AppColors.textPrimary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Text('Lap ${lap.number}', style: style)),
          Text(formatStopwatch(lap.lapTime), style: style),
          const SizedBox(width: 20),
          Text(
            formatStopwatch(lap.total),
            style: style?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
