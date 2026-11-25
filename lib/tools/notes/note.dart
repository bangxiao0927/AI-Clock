import 'package:flutter/foundation.dart';

/// A note. Either field may be empty, but not both (an empty note is never
/// kept).
@immutable
class Note {
  const Note({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.pinned = false,
  });

  final int id;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool pinned;

  bool get isEmpty => title.trim().isEmpty && body.trim().isEmpty;

  /// The title, or the first line of the body when there is no title.
  String get displayTitle {
    if (title.trim().isNotEmpty) return title.trim();
    for (final line in body.split('\n')) {
      if (line.trim().isNotEmpty) return line.trim();
    }
    return 'Untitled';
  }

  /// A short preview of the body. When the title is missing, the first body
  /// line is already used as the title, so the preview starts after it.
  String get snippet {
    final lines = body
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (title.trim().isEmpty && lines.isNotEmpty) lines.removeAt(0);
    return lines.join(' ');
  }

  Note copyWith({
    String? title,
    String? body,
    DateTime? updatedAt,
    bool? pinned,
  }) => Note(
    id: id,
    title: title ?? this.title,
    body: body ?? this.body,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    pinned: pinned ?? this.pinned,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
    'pinned': pinned,
  };

  /// Reads a saved note, or returns null if the data is unusable.
  static Note? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    final body = json['body'];
    final created = json['createdAt'];
    final updated = json['updatedAt'];
    if (id is! int || title is! String || body is! String) return null;
    if (created is! int || updated is! int) return null;
    return Note(
      id: id,
      title: title,
      body: body,
      createdAt: DateTime.fromMillisecondsSinceEpoch(created),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updated),
      pinned: json['pinned'] is bool ? json['pinned'] as bool : false,
    );
  }
}
