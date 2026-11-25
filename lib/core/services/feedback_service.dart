import 'package:flutter/services.dart';

import '../settings/app_settings.dart';
import 'sound_service.dart';

/// The one place that decides how the app answers a tap: a sound and a small
/// vibration, each following its own setting.
class FeedbackService {
  FeedbackService({required this._settings, required this._sound});

  final AppSettings _settings;
  final SoundService _sound;

  /// Selecting something: tabs, cards, list rows, segments.
  void tap() {
    _sound.play(Sfx.tap);
    _haptic(HapticFeedback.selectionClick);
  }

  /// Flipping a switch.
  void toggle({required bool on}) {
    _sound.play(on ? Sfx.toggleOn : Sfx.toggleOff);
    _haptic(HapticFeedback.lightImpact);
  }

  /// Saving or finishing something.
  void confirm() {
    _sound.play(Sfx.confirm);
    _haptic(HapticFeedback.mediumImpact);
  }

  void _haptic(Future<void> Function() vibrate) {
    if (!_settings.haptics) return;
    vibrate();
  }
}
