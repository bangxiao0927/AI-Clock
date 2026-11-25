import 'package:flutter/material.dart';

import '../../../core/services/feedback_context.dart';
import '../../../core/theme/app_theme.dart';

/// A large round button with a text label, used by the stopwatch and timer.
/// Greyed out and inert when [onPressed] is null.
class RoundActionButton extends StatelessWidget {
  const RoundActionButton({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final tint = enabled ? color : AppColors.textMuted.withValues(alpha: 0.5);

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: tint.withValues(alpha: 0.18),
        shape: CircleBorder(
          side: BorderSide(color: tint.withValues(alpha: 0.5), width: 1.5),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed == null ? null : context.tapped(onPressed!),
          child: SizedBox.square(
            dimension: 84,
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: tint),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
