import 'package:flutter/material.dart';

import '../../../core/di/provide.dart';
import '../../../core/services/feedback_context.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_time_format.dart';
import '../reminder.dart';
import '../reminders_controller.dart';

/// Bottom sheet for adding a reminder on [initialDate], or editing [reminder]
/// when given. A reminder with a time alerts the user; without one it is an
/// all-day to-do.
class ReminderEditSheet extends StatefulWidget {
  const ReminderEditSheet({
    super.key,
    required this.initialDate,
    this.reminder,
  });

  final DateTime initialDate;
  final Reminder? reminder;

  @override
  State<ReminderEditSheet> createState() => _ReminderEditSheetState();
}

class _ReminderEditSheetState extends State<ReminderEditSheet> {
  late DateTime _date = dateOnly(widget.reminder?.date ?? widget.initialDate);
  late TimeOfDay? _time = _initialTime();
  late final TextEditingController _title = TextEditingController(
    text: widget.reminder?.title ?? '',
  );

  TimeOfDay? _initialTime() {
    final minutes = widget.reminder?.minutes;
    return minutes == null
        ? null
        : TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }

  @override
  void initState() {
    super.initState();
    _title.addListener(() => setState(() {})); // Enables/disables Save.
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  bool get _canSave => _title.text.trim().isNotEmpty;

  Future<void> _pickDate() async {
    context.tapFeedback();
    final today = dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: today.subtract(const Duration(days: 365)),
      lastDate: today.add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _date = dateOnly(picked));
  }

  Future<void> _pickTime(bool use24Hour) async {
    context.tapFeedback();
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: use24Hour),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _time = picked);
  }

  void _save() {
    if (!_canSave) return;
    final reminders = context.read<RemindersController>();
    final time = _time;
    final minutes = time == null ? null : time.hour * 60 + time.minute;
    final existing = widget.reminder;
    if (existing == null) {
      reminders.add(title: _title.text.trim(), date: _date, minutes: minutes);
    } else {
      reminders.update(
        existing.copyWith(
          title: _title.text.trim(),
          date: _date,
          minutes: minutes,
        ),
      );
    }
    context.confirmFeedback();
    Navigator.of(context).pop();
  }

  void _delete() {
    final existing = widget.reminder;
    if (existing == null) return;
    context.tapFeedback();
    context.read<RemindersController>().remove(existing);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final use24Hour = context.read<AppSettings>().use24Hour(context);
    final time = _time;
    final muted = textTheme.bodyMedium?.copyWith(color: AppColors.textMuted);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _title,
            autofocus: widget.reminder == null,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            decoration: const InputDecoration(
              labelText: 'What is happening?',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_rounded),
            title: Text(
              '${relativeDayLabel(_date, DateTime.now())} · ${formatDayMonthYear(_date)}',
            ),
            onTap: _pickDate,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.notifications_none_rounded),
            title: const Text('Remind me at a time'),
            subtitle: Text(
              time == null ? 'All day, no alert' : 'Alerts you at that time',
              style: muted,
            ),
            value: time != null,
            onChanged: (on) {
              context.toggleFeedback(on: on);
              setState(
                () => _time = on ? const TimeOfDay(hour: 9, minute: 0) : null,
              );
            },
          ),
          if (time != null)
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => _pickTime(use24Hour),
                icon: const Icon(Icons.schedule_rounded),
                label: Text(
                  formatClockTime(
                    DateTime(2000, 1, 1, time.hour, time.minute),
                    use24Hour: use24Hour,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (widget.reminder != null)
                // Icon only: with a text label, Delete + Cancel + Save do not
                // fit side by side on a 390pt-wide phone.
                IconButton(
                  tooltip: 'Delete reminder',
                  onPressed: _delete,
                  color: Colors.redAccent,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              const Spacer(),
              TextButton(
                onPressed: context.tapped(() => Navigator.of(context).pop()),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _canSave ? _save : null,
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
