import 'package:flutter/foundation.dart';

import '../../../core/utils/date_time_format.dart';

/// One alarm: a time of day, an optional label, and the weekdays it repeats.
@immutable
class Alarm {
  const Alarm({
    required this.id,
    required this.hour,
    required this.minute,
    this.label = '',
    this.days = const {},
    this.enabled = true,
  });

  final int id;
  final int hour;
  final int minute;
  final String label;

  /// Weekdays the alarm repeats on, 1 (Monday) to 7 (Sunday).
  /// Empty means it rings once, at the next occurrence of the time.
  final Set<int> days;

  final bool enabled;

  bool get repeats => days.isNotEmpty;

  Alarm copyWith({
    int? hour,
    int? minute,
    String? label,
    Set<int>? days,
    bool? enabled,
  }) => Alarm(
    id: id,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    label: label ?? this.label,
    days: days ?? this.days,
    enabled: enabled ?? this.enabled,
  );

  /// The first moment strictly after [from] at which this alarm rings, or null
  /// when it is switched off.
  DateTime? nextFire(DateTime from) {
    if (!enabled) return null;
    return _firstOccurrence(from, days.isEmpty ? null : days);
  }

  /// The first time after [from] that falls on [weekday] at this alarm's time.
  DateTime nextOnWeekday(DateTime from, int weekday) =>
      _firstOccurrence(from, {weekday})!;

  DateTime? _firstOccurrence(DateTime from, Set<int>? allowedDays) {
    for (var offset = 0; offset <= 7; offset++) {
      final candidate = DateTime(
        from.year,
        from.month,
        from.day + offset,
        hour,
        minute,
      );
      final allowed =
          allowedDays == null || allowedDays.contains(candidate.weekday);
      if (allowed && candidate.isAfter(from)) return candidate;
    }
    return null;
  }

  /// "Once", "Every day", "Weekdays", "Weekends" or "Mon, Wed, Fri".
  String get repeatSummary {
    if (days.isEmpty) return 'Once';
    if (days.length == 7) return 'Every day';
    if (_sameDays(const {1, 2, 3, 4, 5})) return 'Weekdays';
    if (_sameDays(const {6, 7})) return 'Weekends';
    final sorted = days.toList()..sort();
    return sorted.map(shortWeekday).join(', ');
  }

  bool _sameDays(Set<int> other) =>
      days.length == other.length && days.containsAll(other);

  Map<String, dynamic> toJson() => {
    'id': id,
    'hour': hour,
    'minute': minute,
    'label': label,
    'days': days.toList()..sort(),
    'enabled': enabled,
  };

  /// Reads a saved alarm, or returns null if the data is unusable.
  static Alarm? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final hour = json['hour'];
    final minute = json['minute'];
    if (id is! int || hour is! int || minute is! int) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    final rawDays = json['days'];
    return Alarm(
      id: id,
      hour: hour,
      minute: minute,
      label: json['label'] is String ? json['label'] as String : '',
      days: rawDays is List
          ? rawDays.whereType<int>().where((d) => d >= 1 && d <= 7).toSet()
          : const {},
      enabled: json['enabled'] is bool ? json['enabled'] as bool : true,
    );
  }
}
