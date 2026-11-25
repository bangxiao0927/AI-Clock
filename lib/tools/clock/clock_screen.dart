import 'package:flutter/material.dart';

import '../../core/widgets/pill_segments.dart';
import '../tool_scaffold.dart';
import 'alarm/alarm_page.dart';
import 'clock_tool.dart';
import 'stopwatch/stopwatch_page.dart';
import 'timer/timer_page.dart';
import 'world/world_clock_page.dart';

/// The four sections of the Clock tool.
enum ClockSection {
  world('World'),
  alarm('Alarm'),
  stopwatch('Stopwatch'),
  timer('Timer');

  const ClockSection(this.label);
  final String label;
}

/// Clock: world clocks, alarms, a stopwatch and a timer. Each section is its
/// own page in its own folder.
class ClockScreen extends StatefulWidget {
  const ClockScreen({super.key});

  @override
  State<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen> {
  ClockSection _section = ClockSection.world;

  Widget _page() => switch (_section) {
    ClockSection.world => const WorldClockPage(),
    ClockSection.alarm => const AlarmPage(),
    ClockSection.stopwatch => const StopwatchPage(),
    ClockSection.timer => const TimerPage(),
  };

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      info: clockInfo,
      children: [
        PillSegments<ClockSection>(
          accent: clockInfo.color,
          selected: _section,
          onChanged: (section) => setState(() => _section = section),
          segments: [
            for (final section in ClockSection.values)
              PillSegment(value: section, label: section.label),
          ],
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          // Keep the old page from jumping while the new one fades in.
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.topCenter,
            children: [...previous, ?current],
          ),
          child: KeyedSubtree(key: ValueKey(_section), child: _page()),
        ),
      ],
    );
  }
}
