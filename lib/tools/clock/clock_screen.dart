import 'package:flutter/material.dart';

import '../../core/widgets/app_card.dart';
import '../../core/widgets/placeholder_card.dart';
import '../../core/widgets/ticking_builder.dart';
import '../tool_scaffold.dart';
import 'clock_tool.dart';
import 'widgets/clock_card.dart';

/// Clock: the current time, live, on an analog face and as digits.
class ClockScreen extends StatelessWidget {
  const ClockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      info: clockInfo,
      children: [
        AppCard(
          child: TickingBuilder(
            builder: (context, now) =>
                ClockCard(time: now, accent: clockInfo.color),
          ),
        ),
        const PlaceholderCard(
          icon: Icons.alarm_rounded,
          title: 'Alarms & timers',
          message: 'Alarms, timers and world clocks will live here.',
        ),
      ],
    );
  }
}
