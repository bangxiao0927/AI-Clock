import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../settings/app_settings.dart';

/// Every sound the app can play. [asset] is relative to `assets/`.
enum Sfx {
  tap('sounds/tap.wav'),
  toggleOn('sounds/toggle_on.wav'),
  toggleOff('sounds/toggle_off.wav'),
  confirm('sounds/confirm.wav'),
  alarm('sounds/alarm.wav'),
  timerDone('sounds/timer_done.wav');

  const Sfx(this.asset);
  final String asset;
}

/// The part of audio playback the app depends on. Swapped for a fake in tests.
abstract class SoundPlayer {
  /// Plays [sfx] once. Short UI sounds only.
  Future<void> play(Sfx sfx);

  /// Plays [sfx] again and again until [stopLoop].
  Future<void> startLoop(Sfx sfx);

  Future<void> stopLoop();

  Future<void> dispose();
}

/// Plays sounds with the `audioplayers` package.
class AudioplayersSoundPlayer implements SoundPlayer {
  AudioPlayer? _ui;
  AudioPlayer? _loop;

  // UI sounds should mix with the user's music, respect the silent switch on
  // iOS and not steal audio focus on Android.
  static final _uiContext = AudioContext(
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
    android: const AudioContextAndroid(
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.assistanceSonification,
      audioFocus: AndroidAudioFocus.none,
    ),
  );

  // Alarms must be heard even with the silent switch on, and as an alarm.
  static final _alertContext = AudioContext(
    iOS: AudioContextIOS(category: AVAudioSessionCategory.playback),
    android: const AudioContextAndroid(
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.alarm,
      audioFocus: AndroidAudioFocus.gainTransientMayDuck,
    ),
  );

  Future<AudioPlayer> _uiPlayer() async {
    final existing = _ui;
    if (existing != null) return existing;
    final player = AudioPlayer();
    await player.setPlayerMode(PlayerMode.lowLatency);
    await player.setAudioContext(_uiContext);
    await player.setReleaseMode(ReleaseMode.stop);
    return _ui = player;
  }

  @override
  Future<void> play(Sfx sfx) async {
    final player = await _uiPlayer();
    await player.stop();
    await player.play(AssetSource(sfx.asset));
  }

  @override
  Future<void> startLoop(Sfx sfx) async {
    final player = _loop ??= AudioPlayer();
    await player.setAudioContext(_alertContext);
    await player.setReleaseMode(ReleaseMode.loop);
    await player.play(AssetSource(sfx.asset));
  }

  @override
  Future<void> stopLoop() async {
    await _loop?.stop();
  }

  @override
  Future<void> dispose() async {
    await _ui?.dispose();
    await _loop?.dispose();
  }
}

/// Plays nothing. Used where there is no audio (tests, unsupported platforms).
class SilentSoundPlayer implements SoundPlayer {
  @override
  Future<void> play(Sfx sfx) async {}

  @override
  Future<void> startLoop(Sfx sfx) async {}

  @override
  Future<void> stopLoop() async {}

  @override
  Future<void> dispose() async {}
}

/// Plays app sounds, honouring the user's sound settings. It never throws:
/// a missing sound must not break the screen that asked for it.
class SoundService {
  SoundService({required this._player, required this._settings});

  final SoundPlayer _player;
  final AppSettings _settings;

  /// A click, toggle or confirmation sound. Skipped when sound effects are off.
  void play(Sfx sfx) {
    if (!_settings.soundEffects) return;
    _guard(() => _player.play(sfx));
  }

  /// Starts the looping alarm or timer sound. Skipped when alarm sounds are off.
  void startAlert(Sfx sfx) {
    if (!_settings.alarmSounds) return;
    _guard(() => _player.startLoop(sfx));
  }

  void stopAlert() => _guard(_player.stopLoop);

  void _guard(Future<void> Function() action) {
    action().catchError((Object error) {
      // Audio can fail (no output device, platform hiccup); never surface it.
      debugPrint('Sound failed: $error');
    });
  }

  Future<void> dispose() => _player.dispose();
}
