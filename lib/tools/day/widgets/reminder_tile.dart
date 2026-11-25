import 'package:flutter/material.dart';

import '../../../core/services/feedback_context.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_time_format.dart';
import '../../../core/widgets/app_card.dart';
import '../reminder.dart';

/// One item in the day's plan: a round check, the title, and its time (or
/// "All day"). Tap the row to edit; tap the circle to tick it off.
class ReminderTile extends StatelessWidget {
  const ReminderTile({
    super.key,
    required this.reminder,
    required this.use24Hour,
    required this.accent,
    required this.onTap,
    required this.onToggle,
  });

  final Reminder reminder;
  final bool use24Hour;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final at = reminder.at;
    final when = at == null
        ? 'All day'
        : formatClockTime(at, use24Hour: use24Hour);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
      child: Row(
        children: [
          Semantics(
            // Its own node, so a screen reader can tick the item off without
            // opening it (otherwise it merges into the row's single node).
            container: true,
            button: true,
            checked: reminder.done,
            label:
                'Mark ${reminder.title} ${reminder.done ? 'not done' : 'done'}',
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                context.toggleFeedback(on: !reminder.done);
                onToggle();
              },
              // A generous touch target around a small circle.
              child: SizedBox.square(
                dimension: 48,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: reminder.done ? accent : Colors.transparent,
                      border: Border.all(
                        color: reminder.done ? accent : AppColors.textMuted,
                        width: 2,
                      ),
                    ),
                    child: reminder.done
                        ? const Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: AppColors.background,
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: (textTheme.titleMedium ?? const TextStyle()).copyWith(
                    decoration: reminder.done
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    color: reminder.done
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                  ),
                  child: Text(
                    reminder.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      at == null
                          ? Icons.wb_twilight_rounded
                          : Icons.notifications_none_rounded,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      when,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
