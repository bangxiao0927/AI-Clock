import 'package:flutter/material.dart';

import '../../../core/di/provide.dart';
import '../../../core/services/feedback_context.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_sheet.dart';
import 'alarm.dart';
import 'alarms_controller.dart';
import 'widgets/alarm_edit_sheet.dart';
import 'widgets/alarm_tile.dart';

/// Alarm section: the list of alarms with an on/off switch each. Tap one to
/// edit it, swipe it away to delete it (with undo).
class AlarmPage extends StatelessWidget {
  const AlarmPage({super.key});

  void _edit(BuildContext context, [Alarm? alarm]) {
    showAppSheet<void>(context, builder: (_) => AlarmEditSheet(alarm: alarm));
  }

  void _delete(BuildContext context, AlarmsController alarms, Alarm alarm) {
    context.tapFeedback();
    alarms.remove(alarm);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Alarm deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => alarms.restore(alarm),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final alarms = context.read<AlarmsController>();
    final settings = context.read<AppSettings>();
    final textTheme = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: Listenable.merge([alarms, settings]),
      builder: (context, _) {
        final use24Hour = settings.use24Hour(context);
        final list = alarms.alarms;
        return Column(
          children: [
            if (list.isEmpty)
              AppCard(
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 24,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      const Icon(
                        Icons.alarm_add_rounded,
                        size: 40,
                        color: AppColors.dayAccent,
                      ),
                      const SizedBox(height: 12),
                      Text('No alarms yet', style: textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Add one and it will ring at the time you pick.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            for (final alarm in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Dismissible(
                  key: ValueKey(alarm.id),
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
                  onDismissed: (_) => _delete(context, alarms, alarm),
                  child: AlarmTile(
                    alarm: alarm,
                    use24Hour: use24Hour,
                    onTap: () => _edit(context, alarm),
                    onToggle: (on) {
                      context.toggleFeedback(on: on);
                      alarms.setEnabled(alarm, on);
                    },
                  ),
                ),
              ),
            const SizedBox(height: 4),
            FilledButton.icon(
              onPressed: context.tapped(() => _edit(context)),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add alarm'),
            ),
          ],
        );
      },
    );
  }
}
