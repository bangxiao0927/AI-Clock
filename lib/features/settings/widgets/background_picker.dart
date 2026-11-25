import 'package:flutter/material.dart';

import '../../../core/services/feedback_context.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';

/// A row of small previews, one per [BackgroundStyle]; the chosen one is
/// outlined.
class BackgroundPicker extends StatelessWidget {
  const BackgroundPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final BackgroundStyle selected;
  final ValueChanged<BackgroundStyle> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final style in BackgroundStyle.values)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: style == BackgroundStyle.values.last ? 0 : 10,
              ),
              child: _Swatch(
                style: style,
                selected: style == selected,
                onTap: () {
                  if (style == selected) return;
                  context.tapFeedback();
                  onChanged(style);
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final BackgroundStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final a = style.glowA;
    final b = style.glowB;

    return Semantics(
      button: true,
      selected: selected,
      label: '${style.label} background',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: AppColors.background,
                gradient: a == null || b == null
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          a.withValues(alpha: 0.7),
                          b.withValues(alpha: 0.7),
                        ],
                      ),
                border: Border.all(
                  width: selected ? 2 : 1,
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.glassBorder,
                ),
              ),
              child: selected
                  ? const Center(
                      child: Icon(
                        Icons.check_rounded,
                        color: AppColors.textPrimary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 6),
            Text(
              style.label,
              maxLines: 1,
              style: textTheme.labelSmall?.copyWith(
                color: selected ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
