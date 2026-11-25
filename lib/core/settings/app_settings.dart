import 'package:flutter/material.dart';

import '../services/app_storage.dart';
import '../theme/app_theme.dart';

/// The selectable app backgrounds. [plain] turns the glow off.
enum BackgroundStyle {
  aurora('Aurora', AppColors.brandStart, AppColors.brandEnd),
  ocean('Ocean', Color(0xFF22D3EE), Color(0xFF3B82F6)),
  ember('Ember', Color(0xFFFB923C), Color(0xFFF43F5E)),
  plain('Plain', null, null);

  const BackgroundStyle(this.label, this.glowA, this.glowB);

  final String label;

  /// The two glow colours (top-left, bottom-right); null for no glow.
  final Color? glowA;
  final Color? glowB;
}

enum TimeFormat {
  system('System'),
  h12('12-hour'),
  h24('24-hour');

  const TimeFormat(this.label);
  final String label;
}

/// User preferences. Every change is saved immediately, so the settings come
/// back after the app has been closed completely.
class AppSettings extends ChangeNotifier {
  AppSettings(this._storage) {
    _load();
  }

  final AppStorage _storage;

  static const _soundEffectsKey = 'settings.soundEffects';
  static const _alarmSoundsKey = 'settings.alarmSounds';
  static const _hapticsKey = 'settings.haptics';
  static const _backgroundKey = 'settings.background';
  static const _timeFormatKey = 'settings.timeFormat';

  bool _soundEffects = true;
  bool _alarmSounds = true;
  bool _haptics = true;
  BackgroundStyle _background = BackgroundStyle.aurora;
  TimeFormat _timeFormat = TimeFormat.system;

  /// Click and toggle sounds.
  bool get soundEffects => _soundEffects;

  /// The looping sound while an alarm or timer is ringing in the app.
  bool get alarmSounds => _alarmSounds;

  bool get haptics => _haptics;
  BackgroundStyle get background => _background;
  TimeFormat get timeFormat => _timeFormat;

  void _load() {
    _soundEffects = _storage.getBool(_soundEffectsKey) ?? true;
    _alarmSounds = _storage.getBool(_alarmSoundsKey) ?? true;
    _haptics = _storage.getBool(_hapticsKey) ?? true;
    _background = _byName(
      BackgroundStyle.values,
      _storage.getString(_backgroundKey),
      BackgroundStyle.aurora,
    );
    _timeFormat = _byName(
      TimeFormat.values,
      _storage.getString(_timeFormatKey),
      TimeFormat.system,
    );
  }

  static T _byName<T extends Enum>(List<T> values, String? name, T fallback) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }

  void setSoundEffects(bool value) {
    if (value == _soundEffects) return;
    _soundEffects = value;
    _storage.setBool(_soundEffectsKey, value);
    notifyListeners();
  }

  void setAlarmSounds(bool value) {
    if (value == _alarmSounds) return;
    _alarmSounds = value;
    _storage.setBool(_alarmSoundsKey, value);
    notifyListeners();
  }

  void setHaptics(bool value) {
    if (value == _haptics) return;
    _haptics = value;
    _storage.setBool(_hapticsKey, value);
    notifyListeners();
  }

  void setBackground(BackgroundStyle value) {
    if (value == _background) return;
    _background = value;
    _storage.setString(_backgroundKey, value.name);
    notifyListeners();
  }

  void setTimeFormat(TimeFormat value) {
    if (value == _timeFormat) return;
    _timeFormat = value;
    _storage.setString(_timeFormatKey, value.name);
    notifyListeners();
  }

  /// Whether to show 24-hour times, given the device's own preference.
  bool use24Hour(BuildContext context) => switch (_timeFormat) {
    TimeFormat.system => MediaQuery.alwaysUse24HourFormatOf(context),
    TimeFormat.h12 => false,
    TimeFormat.h24 => true,
  };

  /// Restores every setting to its default.
  void resetToDefaults() {
    setSoundEffects(true);
    setAlarmSounds(true);
    setHaptics(true);
    setBackground(BackgroundStyle.aurora);
    setTimeFormat(TimeFormat.system);
  }
}
