import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
// The "all" database, not the compact one: it also knows link names such as
// Europe/Amsterdam or the legacy Asia/Calcutta. A phone may report either, and
// an unknown name would silently fall back to UTC.
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

bool _loaded = false;

/// Loads the time-zone database once. Needed before any `tz.getLocation`.
void ensureTimeZonesLoaded() {
  if (_loaded) return;
  tz_data.initializeTimeZones();
  _loaded = true;
}

/// Loads the database and points `tz.local` at the device's own time zone.
/// Falls back to UTC if the device zone cannot be read.
Future<void> initLocalTimeZone() async {
  ensureTimeZonesLoaded();
  try {
    final info = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(info.identifier));
  } catch (error) {
    debugPrint('Could not read the device time zone, using UTC: $error');
  }
}
