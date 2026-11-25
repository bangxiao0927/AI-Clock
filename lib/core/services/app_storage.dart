import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Small key-value store that survives a full app shutdown.
///
/// Wraps `shared_preferences` so the rest of the app never touches the plugin
/// directly, and so structured data (alarms, notes, ...) is saved as JSON.
class AppStorage {
  AppStorage(this._prefs);

  final SharedPreferences _prefs;

  static Future<AppStorage> open() async =>
      AppStorage(await SharedPreferences.getInstance());

  bool? getBool(String key) => _prefs.getBool(key);
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  String? getString(String key) => _prefs.getString(key);
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  int? getInt(String key) => _prefs.getInt(key);
  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);

  /// Decoded JSON for [key], or null when missing or unreadable.
  Object? getJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null; // Corrupt data: behave as if nothing was saved.
    }
  }

  Future<void> setJson(String key, Object value) =>
      _prefs.setString(key, jsonEncode(value));

  /// A saved JSON list of objects; entries of the wrong shape are skipped.
  List<Map<String, dynamic>> getJsonList(String key) {
    final decoded = getJson(key);
    if (decoded is! List) return const [];
    return [
      for (final item in decoded)
        if (item is Map<String, dynamic>) item,
    ];
  }

  Future<void> remove(String key) => _prefs.remove(key);
}
