import 'package:flutter/material.dart';

import '../services/feedback_context.dart';
import '../theme/app_theme.dart';

/// One option in [PillSegments].
@immutable
class PillSegment<T> {
  const PillSegment({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// A segmented control with a tinted capsule that slides to the selection,
/// matching the glass tab bar. Plays tap feedback when the selection changes.
class PillSegments<T> extends StatelessWidget {
  const PillSegments({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.accent = AppColors.brandStart,
  });

  final List<PillSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final Color accent;

  static const _height = 44.0;
  static const _slide = Duration(milliseconds: 260);

  @override
  Widget build(BuildContext context) {
    final count = segments.length;
    final selectedIndex = segments.indexWhere((s) => s.value == selected);
    final alignmentX = count < 2 || selectedIndex < 0
        ? -1.0
        : -1 + 2 * selectedIndex / (count - 1);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: _height + 8,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: _slide,
            curve: Curves.easeOutCubic,
            alignment: Alignment(alignmentX, 0),
            child: FractionallySizedBox(
              widthFactor: 1 / count,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final segment in segments)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: segment.value == selected,
                    label: segment.label,
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (segment.value == selected) return;
                        context.tapFeedback();
                        onChanged(segment.value);
                      },
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: _slide,
                          style: (textTheme.labelLarge ?? const TextStyle())
                              .copyWith(
                                color: segment.value == selected
                                    ? accent
                                    : AppColors.textMuted,
                                fontWeight: segment.value == selected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                          child: Text(segment.label, maxLines: 1),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
