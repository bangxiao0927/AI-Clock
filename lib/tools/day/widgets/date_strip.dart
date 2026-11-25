import 'package:flutter/material.dart';

import '../../../core/services/feedback_context.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_time_format.dart';

/// A horizontal row of days around today. The selected day is filled, today
/// is outlined, and a dot marks days that have something planned.
class DateStrip extends StatefulWidget {
  const DateStrip({
    super.key,
    required this.today,
    required this.selected,
    required this.onSelected,
    required this.hasItems,
    required this.accent,
  });

  final DateTime today;
  final DateTime selected;
  final ValueChanged<DateTime> onSelected;
  final bool Function(DateTime day) hasItems;
  final Color accent;

  /// Days shown before and after today.
  static const daysBefore = 7;
  static const daysAfter = 21;

  @override
  State<DateStrip> createState() => _DateStripState();
}

class _DateStripState extends State<DateStrip> {
  static const _itemWidth = 56.0;
  static const _gap = 8.0;

  // Start with today at the left edge, so the coming days are in view.
  late final ScrollController _scroll = ScrollController(
    initialScrollOffset: DateStrip.daysBefore * (_itemWidth + _gap),
  );

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final count = DateStrip.daysBefore + 1 + DateStrip.daysAfter;

    return SizedBox(
      height: 84,
      child: ListView.separated(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(width: _gap),
        itemBuilder: (context, index) {
          final day = DateTime(
            widget.today.year,
            widget.today.month,
            widget.today.day + index - DateStrip.daysBefore,
          );
          final isSelected = isSameDay(day, widget.selected);
          final isToday = isSameDay(day, widget.today);

          return Semantics(
            button: true,
            selected: isSelected,
            label:
                '${weekdayName(day)} ${formatDayMonthYear(day)}'
                '${isToday ? ', today' : ''}',
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (isSelected) return;
                context.tapFeedback();
                widget.onSelected(day);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: _itemWidth,
                decoration: BoxDecoration(
                  color: isSelected
                      ? widget.accent.withValues(alpha: 0.22)
                      : AppColors.glassFill,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? widget.accent
                        : isToday
                        ? AppColors.textMuted
                        : AppColors.glassBorder,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      shortWeekday(day.weekday),
                      style: textTheme.labelSmall?.copyWith(
                        color: isSelected ? widget.accent : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${day.day}',
                      style: textTheme.titleMedium?.copyWith(
                        color: isSelected ? widget.accent : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.hasItems(day)
                            ? (isSelected ? widget.accent : AppColors.textMuted)
                            : Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
