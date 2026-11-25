import 'package:flutter/material.dart';

import '../../core/di/provide.dart';
import '../../core/services/feedback_context.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_time_format.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/ticking_builder.dart';
import '../tool_scaffold.dart';
import 'day_tool.dart';
import 'reminder.dart';
import 'reminders_controller.dart';
import 'widgets/date_strip.dart';
import 'widgets/day_progress_card.dart';
import 'widgets/reminder_edit_sheet.dart';
import 'widgets/reminder_tile.dart';

/// Day: today's progress, a strip of days, and the plan for the selected day.
class DayScreen extends StatefulWidget {
  const DayScreen({super.key});

  @override
  State<DayScreen> createState() => _DayScreenState();
}

class _DayScreenState extends State<DayScreen> {
  DateTime _selected = dateOnly(DateTime.now());

  void _edit({Reminder? reminder}) {
    showAppSheet<void>(
      context,
      builder: (_) =>
          ReminderEditSheet(initialDate: _selected, reminder: reminder),
    );
  }

  void _delete(RemindersController reminders, Reminder item) {
    context.tapFeedback();
    reminders.remove(item);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Deleted "${item.title}"'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => reminders.restore(item),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final reminders = context.read<RemindersController>();
    final settings = context.read<AppSettings>();
    final textTheme = Theme.of(context).textTheme;
    final accent = dayInfo.color;
    final muted = textTheme.bodyMedium?.copyWith(color: AppColors.textMuted);

    return ToolScaffold(
      info: dayInfo,
      children: [
        AppCard(
          child: TickingBuilder(
            interval: const Duration(minutes: 1),
            builder: (context, now) =>
                DayProgressCard(now: now, accent: accent),
          ),
        ),
        ListenableBuilder(
          listenable: reminders,
          builder: (context, _) => TickingBuilder(
            interval: const Duration(minutes: 1),
            builder: (context, now) => DateStrip(
              today: dateOnly(now),
              selected: _selected,
              onSelected: (day) => setState(() => _selected = day),
              hasItems: reminders.hasItems,
              accent: accent,
            ),
          ),
        ),
        ListenableBuilder(
          listenable: Listenable.merge([reminders, settings]),
          builder: (context, _) {
            final items = reminders.forDay(_selected);
            final open = reminders.openCount(_selected);
            final use24Hour = settings.use24Hour(context);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        relativeDayLabel(_selected, DateTime.now()),
                        style: textTheme.titleLarge,
                      ),
                    ),
                    Text(
                      items.isEmpty
                          ? ''
                          : open == 0
                          ? 'All done'
                          : '$open to do',
                      style: muted,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  AppCard(
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        'Nothing planned. Add a reminder or a to-do for this day.',
                        textAlign: TextAlign.center,
                        style: muted,
                      ),
                    ),
                  ),
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Dismissible(
                      key: ValueKey(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                        ),
                      ),
                      onDismissed: (_) => _delete(reminders, item),
                      child: ReminderTile(
                        reminder: item,
                        use24Hour: use24Hour,
                        accent: accent,
                        onTap: () => _edit(reminder: item),
                        onToggle: () => reminders.toggleDone(item),
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                Center(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: AppColors.background,
                    ),
                    onPressed: context.tapped(_edit),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add to this day'),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
