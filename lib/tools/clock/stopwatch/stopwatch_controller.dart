import 'package:flutter/foundation.dart';

/// One recorded lap.
@immutable
class Lap {
  const Lap({required this.number, required this.lapTime, required this.total});

  final int number;

  /// Time since the previous lap (or the start).
  final Duration lapTime;

  /// Total stopwatch time when the lap was recorded.
  final Duration total;
}

/// A stopwatch with laps. It keeps running while the user visits other tabs.
///
/// Time is measured against an injectable clock so it can be tested without
/// waiting.
class StopwatchController extends ChangeNotifier {
  StopwatchController({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  Duration _accumulated = Duration.zero;
  DateTime? _startedAt;
  final List<Lap> _laps = [];

  bool get running => _startedAt != null;

  /// Total time on the stopwatch right now.
  Duration get elapsed {
    final startedAt = _startedAt;
    return startedAt == null
        ? _accumulated
        : _accumulated + _now().difference(startedAt);
  }

  /// Laps, newest first.
  List<Lap> get laps => _laps.reversed.toList();

  /// Whether there is anything to reset.
  bool get hasTime => running || _accumulated > Duration.zero;

  /// The quickest and slowest lap, once there are at least two laps.
  ({Lap fastest, Lap slowest})? get extremes {
    if (_laps.length < 2) return null;
    var fastest = _laps.first;
    var slowest = _laps.first;
    for (final lap in _laps) {
      if (lap.lapTime < fastest.lapTime) fastest = lap;
      if (lap.lapTime > slowest.lapTime) slowest = lap;
    }
    return (fastest: fastest, slowest: slowest);
  }

  void start() {
    if (running) return;
    _startedAt = _now();
    notifyListeners();
  }

  void stop() {
    final startedAt = _startedAt;
    if (startedAt == null) return;
    _accumulated += _now().difference(startedAt);
    _startedAt = null;
    notifyListeners();
  }

  void toggle() => running ? stop() : start();

  /// Records a lap. Only while running.
  void lap() {
    if (!running) return;
    final total = elapsed;
    final previous = _laps.isEmpty ? Duration.zero : _laps.last.total;
    _laps.add(
      Lap(number: _laps.length + 1, lapTime: total - previous, total: total),
    );
    notifyListeners();
  }

  void reset() {
    _accumulated = Duration.zero;
    _startedAt = null;
    _laps.clear();
    notifyListeners();
  }
}
