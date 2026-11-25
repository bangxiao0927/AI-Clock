import 'package:flutter/foundation.dart';

import '../../../core/services/app_storage.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/date_time_format.dart';
import 'alarm.dart';

/// The user's alarms: saved across restarts, mirrored into system
/// notifications so they ring when the app is closed.
class AlarmsController extends ChangeNotifier {
  AlarmsController({
    required this._storage,
    required this._notifications,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    _alarms = [
      for (final json in _storage.getJsonList(_key)) ?Alarm.fromJson(json),
    ];
  }

  final AppStorage _storage;
  final NotificationService _notifications;
  final DateTime Function() _now;

  static const _key = 'alarms.v1';

  late List<Alarm> _alarms;

  /// Alarms ordered by time of day.
  List<Alarm> get alarms {
    final sorted = [..._alarms]
      ..sort((a, b) => (a.hour * 60 + a.minute) - (b.hour * 60 + b.minute));
    return sorted;
  }

  Alarm? byId(int id) {
    for (final alarm in _alarms) {
      if (alarm.id == id) return alarm;
    }
    return null;
  }

  /// The next alarm to ring, or null if none is switched on.
  ({Alarm alarm, DateTime at})? get next {
    final now = _now();
    ({Alarm alarm, DateTime at})? best;
    for (final alarm in _alarms) {
      final at = alarm.nextFire(now);
      if (at != null && (best == null || at.isBefore(best.at))) {
        best = (alarm: alarm, at: at);
      }
    }
    return best;
  }

  // Notification ids: 1,000,000 + alarm id * 10 + slot. Slots 1-7 are the
  // weekdays of a repeating alarm, 0 is a one-off alarm and 8 is its snooze.
  static const _idBase = 1000000;
  static int notificationId(Alarm alarm, int slot) =>
      _idBase + alarm.id * 10 + slot;

  /// The notification id used for [alarm]'s snooze.
  static int snoozeNotificationId(Alarm alarm) => notificationId(alarm, 8);

  Alarm add({
    required int hour,
    required int minute,
    String label = '',
    Set<int> days = const {},
  }) {
    final id = _alarms.fold<int>(0, (max, a) => a.id > max ? a.id : max) + 1;
    final alarm = Alarm(
      id: id,
      hour: hour,
      minute: minute,
      label: label,
      days: days,
    );
    _alarms = [..._alarms, alarm];
    _changed(alarm);
    return alarm;
  }

  void update(Alarm alarm) {
    _alarms = [for (final a in _alarms) a.id == alarm.id ? alarm : a];
    _changed(alarm);
  }

  /// Puts back an alarm that was just removed (the undo action).
  void restore(Alarm alarm) {
    if (byId(alarm.id) != null) return;
    _alarms = [..._alarms, alarm];
    _changed(alarm);
  }

  void setEnabled(Alarm alarm, bool enabled) =>
      update(alarm.copyWith(enabled: enabled));

  void remove(Alarm alarm) {
    _alarms = _alarms.where((a) => a.id != alarm.id).toList();
    _cancel(alarm);
    _notifications.cancel(snoozeNotificationId(alarm));
    _persist();
    notifyListeners();
  }

  /// Returns the alarms that were due in the window after [from] up to [to],
  /// and switches one-off alarms off now that they have rung.
  List<Alarm> takeDue(DateTime from, DateTime to) {
    final due = <Alarm>[];
    for (final alarm in _alarms) {
      final at = alarm.nextFire(from);
      if (at != null && !at.isAfter(to)) due.add(alarm);
    }
    var changed = false;
    for (final alarm in due) {
      if (!alarm.repeats) {
        _alarms = [
          for (final a in _alarms)
            a.id == alarm.id ? a.copyWith(enabled: false) : a,
        ];
        changed = true;
      }
    }
    if (changed) {
      _persist();
      notifyListeners();
    }
    return due;
  }

  /// Re-creates every alarm's notifications. Call at startup, so changes in
  /// the device's time zone or clock are picked up.
  Future<void> syncNotifications() async {
    for (final alarm in _alarms) {
      await _schedule(alarm);
    }
  }

  void _changed(Alarm alarm) {
    _persist();
    notifyListeners();
    if (alarm.enabled) _notifications.requestPermission();
    _schedule(alarm);
  }

  Future<void> _schedule(Alarm alarm) async {
    await _cancel(alarm);
    if (!alarm.enabled) return;
    final now = _now();
    final title = alarm.label.isEmpty ? 'Alarm' : alarm.label;
    final body = formatHoursMinutes(
      DateTime(now.year, now.month, now.day, alarm.hour, alarm.minute),
      use24Hour: true,
    );
    if (alarm.repeats) {
      for (final weekday in alarm.days) {
        await _notifications.schedule(
          id: notificationId(alarm, weekday),
          at: alarm.nextOnWeekday(now, weekday),
          title: title,
          body: body,
          repeatsWeekly: true,
        );
      }
    } else {
      final at = alarm.nextFire(now);
      if (at != null) {
        await _notifications.schedule(
          id: notificationId(alarm, 0),
          at: at,
          title: title,
          body: body,
        );
      }
    }
  }

  Future<void> _cancel(Alarm alarm) async {
    for (var slot = 0; slot <= 7; slot++) {
      await _notifications.cancel(notificationId(alarm, slot));
    }
  }

  void _persist() =>
      _storage.setJson(_key, [for (final alarm in _alarms) alarm.toJson()]);
}
