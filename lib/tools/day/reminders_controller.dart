import 'package:flutter/foundation.dart';

import '../../core/services/app_storage.dart';
import '../../core/services/notification_service.dart';
import '../../core/utils/date_time_format.dart';
import 'reminder.dart';

/// The user's day plan: saved across restarts, with timed items mirrored into
/// system notifications so they alert even when the app is closed.
class RemindersController extends ChangeNotifier {
  RemindersController({
    required this._storage,
    required this._notifications,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    _items = [
      for (final json in _storage.getJsonList(_key)) ?Reminder.fromJson(json),
    ];
  }

  final AppStorage _storage;
  final NotificationService _notifications;
  final DateTime Function() _now;

  static const _key = 'reminders.v1';
  static const _idBase = 2000000;

  late List<Reminder> _items;

  /// Items on [day]: open ones first (all-day, then by time), done ones last.
  List<Reminder> forDay(DateTime day) {
    final items = _items.where((r) => isSameDay(r.date, day)).toList();
    items.sort((a, b) {
      if (a.done != b.done) return a.done ? 1 : -1;
      final byTime = (a.minutes ?? -1) - (b.minutes ?? -1);
      return byTime != 0 ? byTime : a.id - b.id;
    });
    return items;
  }

  bool hasItems(DateTime day) => _items.any((r) => isSameDay(r.date, day));

  /// How many items on [day] are not done yet.
  int openCount(DateTime day) =>
      _items.where((r) => isSameDay(r.date, day) && !r.done).length;

  Reminder add({required String title, required DateTime date, int? minutes}) {
    final id = _items.fold<int>(0, (max, r) => r.id > max ? r.id : max) + 1;
    final item = Reminder(
      id: id,
      title: title,
      date: dateOnly(date),
      minutes: minutes,
    );
    _items = [..._items, item];
    _changed(item);
    return item;
  }

  void update(Reminder item) {
    _items = [for (final r in _items) r.id == item.id ? item : r];
    _changed(item);
  }

  void toggleDone(Reminder item) => update(item.copyWith(done: !item.done));

  void remove(Reminder item) {
    _items = _items.where((r) => r.id != item.id).toList();
    _notifications.cancel(_notificationId(item));
    _persist();
    notifyListeners();
  }

  /// Puts back an item that was just removed (the undo action).
  void restore(Reminder item) {
    if (_items.any((r) => r.id == item.id)) return;
    _items = [..._items, item];
    _changed(item);
  }

  /// Open timed items whose time fell in the window after [from] up to [to].
  List<Reminder> takeDue(DateTime from, DateTime to) => [
    for (final item in _items)
      if (!item.done && item.at != null)
        if (item.at!.isAfter(from) && !item.at!.isAfter(to)) item,
  ];

  /// Removes [item]'s system notification, because the app already alerted
  /// the user itself.
  void cancelNotification(Reminder item) =>
      _notifications.cancel(_notificationId(item));

  /// Re-creates every notification. Call at startup.
  Future<void> syncNotifications() async {
    for (final item in _items) {
      await _schedule(item);
    }
  }

  void _changed(Reminder item) {
    _persist();
    notifyListeners();
    if (item.at != null && !item.done) _notifications.requestPermission();
    _schedule(item);
  }

  int _notificationId(Reminder item) => _idBase + item.id;

  Future<void> _schedule(Reminder item) async {
    await _notifications.cancel(_notificationId(item));
    final at = item.at;
    if (item.done || at == null || !at.isAfter(_now())) return;
    await _notifications.schedule(
      id: _notificationId(item),
      at: at,
      title: item.title,
      body: 'Reminder',
    );
  }

  void _persist() =>
      _storage.setJson(_key, [for (final item in _items) item.toJson()]);
}
