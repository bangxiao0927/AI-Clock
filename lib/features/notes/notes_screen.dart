import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../app_feature.dart';
import '../feature_scaffold.dart';

/// Notes: an empty state for now. The editor comes in a later iteration.
class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accent = AppFeature.notes.color;

    return FeatureScaffold(
      feature: AppFeature.notes,
      children: [
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                Icon(Icons.sticky_note_2_outlined, size: 44, color: accent),
                const SizedBox(height: 16),
                Text('No notes yet', style: textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  'Capture quick thoughts here. Your notes will appear in this space.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: AppColors.background,
                  ),
                  onPressed: () => ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text('The note editor is coming soon.'),
                      ),
                    ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('New note'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
