import 'package:flutter/foundation.dart';

import '../../../core/services/app_storage.dart';
import '../../../core/services/notification_service.dart';

enum TimerPhase { idle, running, paused, finished }

/// A countdown timer. Saved across restarts and mirrored into one system
/// notification, so it alerts the user even when the app is closed.
class TimerController extends ChangeNotifier {
  TimerController({
    required this._storage,
    required this._notifications,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    _load();
  }

  final AppStorage _storage;
  final NotificationService _notifications;
  final DateTime Function() _now;

  static const _key = 'timer.v1';
  static const notificationId = 1;
  static const defaultDuration = Duration(minutes: 5);

  Duration _total = defaultDuration;
  TimerPhase _phase = TimerPhase.idle;
  DateTime? _endsAt;
  Duration _pausedRemaining = Duration.zero;

  TimerPhase get phase => _phase;

  /// The length the timer was set to.
  Duration get total => _total;

  /// Time left. While idle this is the full length.
  Duration get remaining {
    switch (_phase) {
      case TimerPhase.idle:
        return _total;
      case TimerPhase.running:
        final left = _endsAt!.difference(_now());
        return left.isNegative ? Duration.zero : left;
      case TimerPhase.paused:
        return _pausedRemaining;
      case TimerPhase.finished:
        return Duration.zero;
    }
  }

  /// 0 when just started, 1 when done.
  double get progress {
    if (_total <= Duration.zero) return 0;
    final done = 1 - remaining.inMilliseconds / _total.inMilliseconds;
    return done.clamp(0.0, 1.0);
  }

  void _load() {
    final saved = _storage.getJson(_key);
    if (saved is! Map) return;
    final totalMs = saved['totalMs'];
    if (totalMs is int && totalMs > 0) _total = Duration(milliseconds: totalMs);

    final phase = saved['phase'];
    final endsAtMs = saved['endsAtMs'];
    final pausedMs = saved['pausedMs'];
    if (phase == TimerPhase.running.name && endsAtMs is int) {
      final endsAt = DateTime.fromMillisecondsSinceEpoch(endsAtMs);
      // If it ran out while the app was closed, the notification already
      // told the user; just return to idle rather than ringing late.
      if (endsAt.isAfter(_now())) {
        _phase = TimerPhase.running;
        _endsAt = endsAt;
      }
    } else if (phase == TimerPhase.paused.name &&
        pausedMs is int &&
        pausedMs > 0) {
      _phase = TimerPhase.paused;
      _pausedRemaining = Duration(milliseconds: pausedMs);
    }
  }

  /// Sets the length. Only while idle.
  void setDuration(Duration duration) {
    if (_phase != TimerPhase.idle || duration <= Duration.zero) return;
    _total = duration;
    _persist();
    notifyListeners();
  }

  void start() {
    if (_phase != TimerPhase.idle || _total <= Duration.zero) return;
    _run(_total);
  }

  void pause() {
    if (_phase != TimerPhase.running) return;
    _pausedRemaining = remaining;
    _phase = TimerPhase.paused;
    _endsAt = null;
    _notifications.cancel(notificationId);
    _persist();
    notifyListeners();
  }

  void resume() {
    if (_phase != TimerPhase.paused) return;
    _run(_pausedRemaining);
  }

  /// Adds a minute to a running or paused timer.
  void addMinute() {
    const extra = Duration(minutes: 1);
    if (_phase == TimerPhase.running) {
      _total += extra;
      _run(remaining + extra);
    } else if (_phase == TimerPhase.paused) {
      _total += extra;
      _pausedRemaining += extra;
      _persist();
      notifyListeners();
    }
  }

  /// Stops the timer and returns to the set length.
  void cancel() {
    _phase = TimerPhase.idle;
    _endsAt = null;
    _notifications.cancel(notificationId);
    _persist();
    notifyListeners();
  }

  /// Marks a running timer as finished if its time is up. Returns true once,
  /// when it finishes, so the caller can ring.
  bool takeFinished(DateTime now) {
    if (_phase != TimerPhase.running) return false;
    if (_endsAt!.isAfter(now)) return false;
    _phase = TimerPhase.finished;
    _endsAt = null;
    _notifications.cancel(notificationId);
    _persist();
    notifyListeners();
    return true;
  }

  /// Dismisses a finished timer, back to the set length.
  void acknowledgeFinished() {
    if (_phase != TimerPhase.finished) return;
    _phase = TimerPhase.idle;
    _persist();
    notifyListeners();
  }

  void _run(Duration duration) {
    _phase = TimerPhase.running;
    _endsAt = _now().add(duration);
    _notifications.requestPermission();
    _notifications.schedule(
      id: notificationId,
      at: _endsAt!,
      title: 'Timer finished',
      body: "Time's up.",
    );
    _persist();
    notifyListeners();
  }

  void _persist() => _storage.setJson(_key, {
    'totalMs': _total.inMilliseconds,
    'phase': _phase.name,
    'endsAtMs': _endsAt?.millisecondsSinceEpoch,
    'pausedMs': _pausedRemaining.inMilliseconds,
  });
}
