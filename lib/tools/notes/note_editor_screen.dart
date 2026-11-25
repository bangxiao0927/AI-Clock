import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/di/provide.dart';
import '../../core/services/feedback_context.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ambient_background.dart';
import 'note.dart';
import 'notes_controller.dart';
import 'notes_tool.dart';

/// Edits one note. It saves by itself a moment after each change and again
/// when the screen closes; a note left empty is not kept.
class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({super.key, required this.note});

  final Note note;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  static const _saveDelay = Duration(milliseconds: 400);

  // Looked up in initState: dispose() saves one last time, and by then the
  // context can no longer be used to find it.
  late final NotesController _notes;
  late Note _note = widget.note;
  late final TextEditingController _title = TextEditingController(
    text: widget.note.title,
  );
  late final TextEditingController _body = TextEditingController(
    text: widget.note.body,
  );
  Timer? _saveTimer;
  bool _deleted = false;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _notes = context.read<NotesController>();
    _title.addListener(_scheduleSave);
    _body.addListener(_scheduleSave);
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDelay, _save);
  }

  void _save() {
    if (_deleted) return;
    _note = _notes.save(_note.copyWith(title: _title.text, body: _body.text));
    if (!_closing && mounted) setState(() {}); // Refreshes the pin icon.
  }

  void _togglePin() {
    context.tapFeedback();
    setState(() => _note = _note.copyWith(pinned: !_note.pinned));
    _save();
  }

  void _delete() {
    context.confirmFeedback();
    _deleted = true;
    final note = _note.copyWith(title: _title.text, body: _body.text);
    _notes.delete(note);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Note deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => _notes.restore(note),
          ),
        ),
      );
  }

  @override
  void dispose() {
    _closing = true;
    _saveTimer?.cancel();
    if (!_deleted) {
      // Save one last time, but not right now: the framework is tearing the
      // widget tree down, and saving notifies the notes list, which cannot
      // rebuild while the tree is locked. A microtask runs just after.
      final note = _note.copyWith(title: _title.text, body: _body.text);
      final notes = _notes;
      Future.microtask(() => notes.save(note));
    }
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          actions: [
            IconButton(
              tooltip: _note.pinned ? 'Unpin note' : 'Pin note',
              onPressed: _togglePin,
              icon: Icon(
                _note.pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                color: _note.pinned ? notesInfo.color : null,
              ),
            ),
            IconButton(
              tooltip: 'Delete note',
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Column(
              children: [
                TextField(
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  style: textTheme.headlineSmall,
                  decoration: const InputDecoration(
                    hintText: 'Title',
                    border: InputBorder.none,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _body,
                    autofocus: widget.note.isEmpty,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    textCapitalization: TextCapitalization.sentences,
                    style: textTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'Start typing…',
                      hintStyle: textTheme.bodyLarge?.copyWith(
                        color: AppColors.textMuted,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
