import 'package:flutter/material.dart';

import '../../../core/services/feedback_context.dart';
import '../../../core/theme/app_theme.dart';

/// Shown by the Notes tool until there are notes to list.
class NotesEmptyState extends StatelessWidget {
  const NotesEmptyState({
    super.key,
    required this.accent,
    required this.onNewNote,
  });

  final Color accent;
  final VoidCallback onNewNote;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          Icon(Icons.sticky_note_2_outlined, size: 44, color: accent),
          const SizedBox(height: 16),
          Text('No notes yet', style: textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Capture quick thoughts here. Your notes are saved on this device.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: AppColors.background,
            ),
            onPressed: context.tapped(onNewNote),
            icon: const Icon(Icons.add_rounded),
            label: const Text('New note'),
          ),
        ],
      ),
    );
  }
}
