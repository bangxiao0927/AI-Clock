import 'package:flutter/material.dart';

import '../../core/widgets/app_card.dart';
import '../../core/widgets/placeholder_card.dart';
import '../../core/widgets/ticking_builder.dart';
import '../tool_scaffold.dart';
import 'day_tool.dart';
import 'widgets/day_progress_card.dart';

/// Day: today's date and how much of the day has passed.
class DayScreen extends StatelessWidget {
  const DayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      info: dayInfo,
      children: [
        AppCard(
          child: TickingBuilder(
            interval: const Duration(minutes: 1),
            builder: (context, now) =>
                DayProgressCard(now: now, accent: dayInfo.color),
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
