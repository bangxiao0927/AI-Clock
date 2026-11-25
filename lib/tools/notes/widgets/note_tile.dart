import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_time_format.dart';
import '../../../core/widgets/app_card.dart';
import '../note.dart';

/// One note in the list: title, a two-line preview and when it was edited.
class NoteTile extends StatelessWidget {
  const NoteTile({
    super.key,
    required this.note,
    required this.now,
    required this.accent,
    required this.onTap,
  });

  final Note note;
  final DateTime now;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final snippet = note.snippet;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  note.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium,
                ),
              ),
              if (note.pinned)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(Icons.push_pin_rounded, size: 16, color: accent),
                ),
            ],
          ),
          if (snippet.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              snippet,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            relativeDayLabel(note.updatedAt, now),
            style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
