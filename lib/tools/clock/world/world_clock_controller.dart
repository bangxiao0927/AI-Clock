import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/services/app_storage.dart';
import '../../../core/services/time_zones.dart';
import 'city.dart';

/// The user's chosen cities, saved across app restarts.
class WorldClockController extends ChangeNotifier {
  WorldClockController(this._storage) {
    ensureTimeZonesLoaded();
    _load();
  }

  final AppStorage _storage;

  static const _key = 'world.cityIds';

  List<City> _cities = const [];

  /// The chosen cities, in the order shown.
  List<City> get cities => List.unmodifiable(_cities);

  void _load() {
    final saved = _storage.getJson(_key);
    final ids = saved is List
        ? saved.whereType<String>().toList()
        : defaultCityIds;
    _cities = [for (final id in ids) ?cityById(id)];
  }

  bool contains(City city) => _cities.contains(city);

  void add(City city) {
    if (contains(city)) return;
    _cities = [..._cities, city];
    _save();
  }

  void remove(City city) {
    _cities = _cities.where((c) => c != city).toList();
    _save();
  }

  void _save() {
    _storage.setJson(_key, [for (final c in _cities) c.id]);
    notifyListeners();
  }

  /// The time in [city] at the instant [now].
  static tz.TZDateTime timeIn(City city, DateTime now) =>
      tz.TZDateTime.from(now, tz.getLocation(city.zone));

  /// How far ahead of (+) or behind (-) the device's clock [city] is at [now].
  static Duration offsetFromLocal(City city, DateTime now) =>
      timeIn(city, now).timeZoneOffset - now.timeZoneOffset;
}
