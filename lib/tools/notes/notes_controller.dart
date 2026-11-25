import 'package:flutter/foundation.dart';

import '../../core/services/app_storage.dart';
import 'note.dart';

/// The user's notes, saved across restarts.
class NotesController extends ChangeNotifier {
  NotesController({required this._storage, DateTime Function()? now})
    : _now = now ?? DateTime.now {
    _notes = [
      for (final json in _storage.getJsonList(_key)) ?Note.fromJson(json),
    ];
  }

  final AppStorage _storage;
  final DateTime Function() _now;

  static const _key = 'notes.v1';

  late List<Note> _notes;

  /// Pinned notes first, then the most recently edited.
  List<Note> get notes {
    final sorted = [..._notes]
      ..sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
    return sorted;
  }

  /// Notes whose title or text contains [query] (ignoring case).
  List<Note> search(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return notes;
    return [
      for (final note in notes)
        if (note.title.toLowerCase().contains(needle) ||
            note.body.toLowerCase().contains(needle))
          note,
    ];
  }

  Note? byId(int id) {
    for (final note in _notes) {
      if (note.id == id) return note;
    }
    return null;
  }

  /// A new, empty note. It is not stored until [save] is given some text.
  Note createDraft() {
    final id = _notes.fold<int>(0, (max, n) => n.id > max ? n.id : max) + 1;
    final now = _now();
    return Note(id: id, title: '', body: '', createdAt: now, updatedAt: now);
  }

  /// Stores [note], or removes it if it is empty. Returns the stored note.
  Note save(Note note) {
    final existing = byId(note.id);
    if (note.isEmpty) {
      if (existing != null) delete(note);
      return note;
    }
    final changed =
        existing == null ||
        existing.title != note.title ||
        existing.body != note.body ||
        existing.pinned != note.pinned;
    final stored = changed ? note.copyWith(updatedAt: _now()) : note;
    _notes = existing == null
        ? [..._notes, stored]
        : [for (final n in _notes) n.id == note.id ? stored : n];
    _persist();
    notifyListeners();
    return stored;
  }

  void delete(Note note) {
    _notes = _notes.where((n) => n.id != note.id).toList();
    _persist();
    notifyListeners();
  }

  /// Puts back a note that was just deleted (the undo action).
  void restore(Note note) {
    if (byId(note.id) != null) return;
    _notes = [..._notes, note];
    _persist();
    notifyListeners();
  }

  void togglePin(Note note) => save(note.copyWith(pinned: !note.pinned));

  void _persist() =>
      _storage.setJson(_key, [for (final note in _notes) note.toJson()]);
}
