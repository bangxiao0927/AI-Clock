import 'package:flutter/cupertino.dart'
    show CupertinoTimerPicker, CupertinoTimerPickerMode;
import 'package:flutter/material.dart';

import '../../../core/di/provide.dart';
import '../../../core/services/feedback_context.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_time_format.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/ticking_builder.dart';
import '../clock_tool.dart';
import '../widgets/round_action_button.dart';
import 'timer_controller.dart';
import 'widgets/timer_ring.dart';

/// Timer section: pick a length and start; then a countdown ring with pause,
/// cancel and "+1 min".
class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  static const _presets = [
    Duration(minutes: 1),
    Duration(minutes: 5),
    Duration(minutes: 10),
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(hours: 1),
  ];

  late Duration _picked = context.read<TimerController>().total;

  // The wheel picker only reads its initial value once, so changing the value
  // from a preset needs a fresh picker: bumping the key creates one.
  int _pickerKey = 0;

  void _usePreset(Duration duration) {
    setState(() {
      _picked = duration;
      _pickerKey++;
    });
  }

  static String _presetLabel(Duration d) =>
      d.inHours >= 1 ? '${d.inHours} h' : '${d.inMinutes} min';

  @override
  Widget build(BuildContext context) {
    final timer = context.read<TimerController>();

    return ListenableBuilder(
      listenable: timer,
      builder: (context, _) => timer.phase == TimerPhase.idle
          ? _buildSetup(context, timer)
          : _buildRunning(context, timer),
    );
  }

  Widget _buildSetup(BuildContext context, TimerController timer) {
    return AppCard(
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: CupertinoTimerPicker(
              key: ValueKey(_pickerKey),
              mode: CupertinoTimerPickerMode.hms,
              initialTimerDuration: _picked,
              onTimerDurationChanged: (value) =>
                  setState(() => _picked = value),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final preset in _presets)
                ActionChip(
                  label: Text(_presetLabel(preset)),
                  onPressed: context.tapped(() => _usePreset(preset)),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _picked <= Duration.zero
                  ? null
                  : context.tapped(() {
                      timer.setDuration(_picked);
                      timer.start();
                    }),
              child: const Text('Start'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunning(BuildContext context, TimerController timer) {
    final textTheme = Theme.of(context).textTheme;
    final finished = timer.phase == TimerPhase.finished;
    final paused = timer.phase == TimerPhase.paused;

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(
        children: [
          // Redraw several times a second while visible.
          TickingBuilder(
            interval: const Duration(milliseconds: 200),
            builder: (context, _) {
              final remaining = timer.remaining;
              return TimerRing(
                remaining: 1 - timer.progress,
                color: finished ? AppColors.dayAccent : clockInfo.color,
                child: Semantics(
                  label: finished
                      ? "Time's up"
                      : 'Time left ${formatHms(remaining)}',
                  excludeSemantics: true,
                  child: Text(
                    finished ? "Time's up" : formatHms(_roundUp(remaining)),
                    style: textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w300,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 28),
          if (finished)
            FilledButton(
              // The ring banner clears itself when the timer is acknowledged.
              onPressed: context.tapped(timer.acknowledgeFinished),
              child: const Text('Done'),
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RoundActionButton(
                  label: 'Cancel',
                  color: AppColors.textPrimary,
                  onPressed: timer.cancel,
                ),
                RoundActionButton(
                  label: paused ? 'Resume' : 'Pause',
                  color: paused ? clockInfo.color : AppColors.dayAccent,
                  onPressed: paused ? timer.resume : timer.pause,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: context.tapped(timer.addMinute),
              icon: const Icon(Icons.add_rounded),
              label: const Text('1 min'),
            ),
          ],
        ],
      ),
    );
  }

  /// Shows the second that is still in progress (0:00.4 left reads 0:01),
  /// like a physical timer, so it hits 0:00 exactly when it rings.
  static Duration _roundUp(Duration d) =>
      Duration(seconds: (d.inMilliseconds / 1000).ceil());
}
