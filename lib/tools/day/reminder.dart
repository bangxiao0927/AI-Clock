import 'package:flutter/foundation.dart';

import '../../core/utils/date_time_format.dart';

/// One item on the user's day: a title on a date, optionally at a time.
/// With a time it alerts the user; without one it is just a to-do for the day.
@immutable
class Reminder {
  const Reminder({
    required this.id,
    required this.title,
    required this.date,
    this.minutes,
    this.done = false,
  });

  final int id;
  final String title;

  /// The day it belongs to (time of day is ignored).
  final DateTime date;

  /// Minutes after midnight, or null for an all-day item.
  final int? minutes;

  final bool done;

  /// The moment it alerts, or null for an all-day item.
  DateTime? get at => minutes == null
      ? null
      : DateTime(
          date.year,
          date.month,
          date.day,
          minutes! ~/ 60,
          minutes! % 60,
        );

  Reminder copyWith({
    String? title,
    DateTime? date,
    Object? minutes = _keep,
    bool? done,
  }) => Reminder(
    id: id,
    title: title ?? this.title,
    date: date ?? this.date,
    minutes: identical(minutes, _keep) ? this.minutes : minutes as int?,
    done: done ?? this.done,
  );

  static const _keep = Object();

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': '${date.year}-${twoDigits(date.month)}-${twoDigits(date.day)}',
    'minutes': minutes,
    'done': done,
  };

  /// Reads a saved reminder, or returns null if the data is unusable.
  static Reminder? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    final rawDate = json['date'];
    if (id is! int || title is! String || rawDate is! String) return null;
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) return null;
    final minutes = json['minutes'];
    return Reminder(
      id: id,
      title: title,
      date: dateOnly(parsed),
      minutes: minutes is int && minutes >= 0 && minutes < 1440
          ? minutes
          : null,
      done: json['done'] is bool ? json['done'] as bool : false,
    );
  }
}
