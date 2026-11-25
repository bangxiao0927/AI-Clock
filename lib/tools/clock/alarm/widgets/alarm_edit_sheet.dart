import 'package:flutter/material.dart';

import '../../../../core/di/provide.dart';
import '../../../../core/services/feedback_context.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_time_format.dart';
import '../alarm.dart';
import '../alarms_controller.dart';

/// Bottom sheet for creating an alarm, or editing [alarm] when given.
class AlarmEditSheet extends StatefulWidget {
  const AlarmEditSheet({super.key, this.alarm});

  final Alarm? alarm;

  @override
  State<AlarmEditSheet> createState() => _AlarmEditSheetState();
}

class _AlarmEditSheetState extends State<AlarmEditSheet> {
  late TimeOfDay _time = TimeOfDay(
    hour: widget.alarm?.hour ?? 7,
    minute: widget.alarm?.minute ?? 0,
  );
  late final Set<int> _days = {...?widget.alarm?.days};
  late final TextEditingController _label = TextEditingController(
    text: widget.alarm?.label ?? '',
  );

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool use24Hour) async {
    context.tapFeedback();
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: use24Hour),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _time = picked);
  }

  void _save() {
    final alarms = context.read<AlarmsController>();
    final label = _label.text.trim();
    final existing = widget.alarm;
    if (existing == null) {
      alarms.add(
        hour: _time.hour,
        minute: _time.minute,
        label: label,
        days: {..._days},
      );
    } else {
      // Editing an alarm switches it back on: the user just set its time.
      alarms.update(
        existing.copyWith(
          hour: _time.hour,
          minute: _time.minute,
          label: label,
          days: {..._days},
          enabled: true,
        ),
      );
    }
    context.confirmFeedback();
    Navigator.of(context).pop();
  }

  void _delete() {
    final existing = widget.alarm;
    if (existing == null) return;
    context.tapFeedback();
    context.read<AlarmsController>().remove(existing);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final use24Hour = context.read<AppSettings>().use24Hour(context);
    final shown = DateTime(2000, 1, 1, _time.hour, _time.minute);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: TextButton(
              onPressed: () => _pickTime(use24Hour),
              child: Text(
                formatClockTime(shown, use24Hour: use24Hour),
                style: textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w300,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              'Tap the time to change it',
              style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 20),
          Text('Repeat', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var weekday = 1; weekday <= 7; weekday++)
                FilterChip(
                  label: Text(shortWeekday(weekday)),
                  selected: _days.contains(weekday),
                  onSelected: (on) {
                    context.tapFeedback();
                    setState(
                      () => on ? _days.add(weekday) : _days.remove(weekday),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _days.isEmpty ? 'Rings once' : 'Rings every selected day',
            style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _label,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Label',
              hintText: 'Alarm',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (widget.alarm != null)
                // Icon only: with a text label, Delete + Cancel + Save do not
                // fit side by side on a 390pt-wide phone.
                IconButton(
                  tooltip: 'Delete alarm',
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
              FilledButton(onPressed: _save, child: const Text('Save')),
            ],
          ),
        ],
      ),
    );
  }
}
