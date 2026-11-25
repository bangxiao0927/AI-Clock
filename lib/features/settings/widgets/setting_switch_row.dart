import 'package:flutter/material.dart';

import '../../../core/services/feedback_context.dart';
import '../../../core/theme/app_theme.dart';

/// One on/off setting: icon, title, hint and a switch. Tapping anywhere on the
/// row flips it, with a toggle sound.
class SettingSwitchRow extends StatelessWidget {
  const SettingSwitchRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  void _flip(BuildContext context, bool next) {
    // Order matters for the sound settings themselves: turning sound on must
    // be applied first so its click is heard, and turning it off must click
    // first so the "off" is heard once before it goes quiet.
    if (next) {
      onChanged(next);
      context.toggleFeedback(on: true);
    } else {
      context.toggleFeedback(on: false);
      onChanged(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return MergeSemantics(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _flip(context, !value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: AppColors.textMuted),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleMedium),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(value: value, onChanged: (next) => _flip(context, next)),
            ],
          ),
        ),
      ),
    );
  }
}
