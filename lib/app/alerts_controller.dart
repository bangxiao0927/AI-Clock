import 'dart:async';

import 'package:flutter/widgets.dart';

import '../core/services/notification_service.dart';
import '../core/services/sound_service.dart';
import '../core/utils/date_time_format.dart';
import '../tools/clock/alarm/alarm.dart';
import '../tools/clock/alarm/alarms_controller.dart';
import '../tools/clock/timer/timer_controller.dart';
import '../tools/day/reminder.dart';
import '../tools/day/reminders_controller.dart';

enum AlertKind { alarm, timer, reminder }

/// Something that is ringing right now, shown by the ring banner.
@immutable
class RingingAlert {
  const RingingAlert._(this.kind, this.title, this.subtitle, {this.alarm});

  RingingAlert.alarm(Alarm alarm)
    : this._(
        AlertKind.alarm,
        alarm.label.isEmpty ? 'Alarm' : alarm.label,
        formatHoursMinutes(
          DateTime(2000, 1, 1, alarm.hour, alarm.minute),
          use24Hour: true,
        ),
        alarm: alarm,
      );

  const RingingAlert.timer()
    : this._(AlertKind.timer, 'Timer finished', "Time's up");

  RingingAlert.reminder(Reminder reminder)
    : this._(
        AlertKind.reminder,
        reminder.title,
        'Reminder${reminder.at == null ? '' : ' · ${formatHoursMinutes(reminder.at!, use24Hour: true)}'}',
      );

  final AlertKind kind;
  final String title;
  final String subtitle;

  /// Set for alarms, so they can be snoozed.
  final Alarm? alarm;

  bool get canSnooze => kind == AlertKind.alarm;
}

/// Watches alarms, the timer and reminders while the app is open, and rings
/// when one is due: a looping sound plus a banner on screen. When the app is
/// closed, system notifications (scheduled by the same controllers) take over.
class AlertsController extends ChangeNotifier with WidgetsBindingObserver {
  AlertsController({
    required this._alarms,
    required this._timer,
    required this._reminders,
    required this._sound,
    required this._notifications,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    _lastTick = _now();
    _timer.addListener(_onTimerChanged);
  }

  final AlarmsController _alarms;
  final TimerController _timer;
  final RemindersController _reminders;
  final SoundService _sound;
  final NotificationService _notifications;
  final DateTime Function() _now;

  static const snoozeLength = Duration(minutes: 5);
  static const _ringLimit = Duration(minutes: 2);

  late DateTime _lastTick;
  Timer? _ticker;
  Timer? _autoStop;
  bool _observing = false;

  final List<RingingAlert> _queue = [];
  final Map<int, DateTime> _snoozes = {};
  RingingAlert? _current;

  /// The alert on screen, or null.
  RingingAlert? get current => _current;

  /// Starts checking once a second. Call once at startup.
  void start({bool observeLifecycle = true}) {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => tick());
    if (observeLifecycle && !_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // While the app was away the system notifications did the alerting, so
    // alarms and reminders from that window are skipped. A timer that ended
    // in the meantime still shows its finished state.
    _lastTick = _now();
    if (_timer.takeFinished(_lastTick)) _enqueue(const RingingAlert.timer());
  }

  /// Checks everything that could be due. Called every second by [start];
  /// public so tests can drive it.
  void tick() {
    final now = _now();
    final from = _lastTick;
    _lastTick = now;

    for (final alarm in _alarms.takeDue(from, now)) {
      // The app rings it itself; drop the system notification so the user is
      // not alerted twice, then re-arm repeating alarms for next time.
      _notifications.cancel(
        AlarmsController.notificationId(alarm, alarm.repeats ? now.weekday : 0),
      );
      _alarms.syncNotifications();
      _enqueue(RingingAlert.alarm(alarm));
    }

    for (final entry in _snoozes.entries.toList()) {
      if (entry.value.isAfter(now)) continue;
      _snoozes.remove(entry.key);
      final alarm = _alarms.byId(entry.key);
      if (alarm == null) continue;
      _notifications.cancel(AlarmsController.snoozeNotificationId(alarm));
      _enqueue(RingingAlert.alarm(alarm));
    }

    if (_timer.takeFinished(now)) _enqueue(const RingingAlert.timer());

    for (final item in _reminders.takeDue(from, now)) {
      _reminders.cancelNotification(item);
      _enqueue(RingingAlert.reminder(item));
    }
  }

  void _enqueue(RingingAlert alert) {
    if (_current == null) {
      _show(alert);
    } else {
      _queue.add(alert);
    }
  }

  void _show(RingingAlert alert) {
    _current = alert;
    switch (alert.kind) {
      case AlertKind.alarm:
        _sound.startAlert(Sfx.alarm);
      case AlertKind.timer:
        _sound.startAlert(Sfx.timerDone);
      case AlertKind.reminder:
        _sound.play(Sfx.confirm);
    }
    _autoStop?.cancel();
    _autoStop = Timer(_ringLimit, dismiss);
    notifyListeners();
  }

  /// Stops the current alert and shows the next queued one, if any.
  void dismiss() {
    final alert = _current;
    if (alert == null) return;
    // Clear it first: acknowledging the timer notifies _onTimerChanged, which
    // must not find this alert still current and dismiss it a second time.
    _current = null;
    _autoStop?.cancel();
    _sound.stopAlert();
    if (alert.kind == AlertKind.timer) _timer.acknowledgeFinished();
    if (_queue.isNotEmpty) {
      _show(_queue.removeAt(0));
    } else {
      notifyListeners();
    }
  }

  /// The timer page can acknowledge a finished timer itself; when it does, its
  /// alert (on screen or queued) is no longer needed.
  void _onTimerChanged() {
    if (_timer.phase == TimerPhase.finished) return;
    _queue.removeWhere((a) => a.kind == AlertKind.timer);
    if (_current?.kind == AlertKind.timer) dismiss();
  }

  /// Silences the current alarm and rings it again in [snoozeLength].
  void snooze() {
    final alarm = _current?.alarm;
    if (alarm == null) return;
    final at = _now().add(snoozeLength);
    _snoozes[alarm.id] = at;
    _notifications.schedule(
      id: AlarmsController.snoozeNotificationId(alarm),
      at: at,
      title: alarm.label.isEmpty ? 'Alarm' : alarm.label,
      body: 'Snoozed',
    );
    dismiss();
  }

  @override
  void dispose() {
    _timer.removeListener(_onTimerChanged);
    _ticker?.cancel();
    _autoStop?.cancel();
    if (_observing) WidgetsBinding.instance.removeObserver(this);
    _sound.stopAlert();
    super.dispose();
  }
}
