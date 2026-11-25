import 'package:flutter/material.dart';

import '../../core/di/provide.dart';
import '../../core/services/feedback_context.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../tool_scaffold.dart';
import 'note.dart';
import 'note_editor_screen.dart';
import 'notes_controller.dart';
import 'notes_tool.dart';
import 'widgets/note_tile.dart';
import 'widgets/notes_empty_state.dart';

/// Notes: a searchable list. Tap a note to edit it, swipe to delete (with
/// undo), and use the button for a new one.
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _open(Note note) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => NoteEditorScreen(note: note)),
    );
  }

  void _create() => _open(context.read<NotesController>().createDraft());

  void _delete(NotesController notes, Note note) {
    context.tapFeedback();
    notes.delete(note);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Note deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => notes.restore(note),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final notes = context.read<NotesController>();
    final textTheme = Theme.of(context).textTheme;
    final accent = notesInfo.color;
    final muted = textTheme.bodyMedium?.copyWith(color: AppColors.textMuted);

    return ToolScaffold(
      info: notesInfo,
      children: [
        ListenableBuilder(
          listenable: notes,
          builder: (context, _) {
            if (notes.notes.isEmpty) {
              return AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 36,
                ),
                child: NotesEmptyState(accent: accent, onNewNote: _create),
              );
            }
            final results = notes.search(_search.text);
            final now = DateTime.now();
            return Column(
              children: [
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search notes',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _search.clear();
                              setState(() {});
                            },
                          ),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (results.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No notes match "${_search.text}".',
                      style: muted,
                    ),
                  ),
                for (final note in results)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Dismissible(
                      key: ValueKey(note.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                        ),
                      ),
                      onDismissed: (_) => _delete(notes, note),
                      child: NoteTile(
                        note: note,
                        now: now,
                        accent: accent,
                        onTap: () => _open(note),
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: AppColors.background,
                  ),
                  onPressed: context.tapped(_create),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('New note'),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
