import 'package:ai_clock_1/app/app.dart';
import 'package:ai_clock_1/app/app_services.dart';
import 'package:ai_clock_1/core/services/app_storage.dart';
import 'package:ai_clock_1/core/services/notification_service.dart';
import 'package:ai_clock_1/core/services/sound_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records what would have been played instead of making any noise.
class RecordingSoundPlayer implements SoundPlayer {
  final List<Sfx> played = [];
  final List<Sfx> loops = [];
  int stopLoopCalls = 0;

  @override
  Future<void> play(Sfx sfx) async => played.add(sfx);

  @override
  Future<void> startLoop(Sfx sfx) async => loops.add(sfx);

  @override
  Future<void> stopLoop() async => stopLoopCalls++;

  @override
  Future<void> dispose() async {}
}

/// A clock the test moves by hand, so time-based code needs no waiting.
class FakeClock {
  FakeClock([DateTime? start]) : _now = start ?? DateTime(2026, 11, 7, 9, 0);

  DateTime _now;

  DateTime call() => _now;

  void advance(Duration duration) => _now = _now.add(duration);

  void set(DateTime time) => _now = time;
}

/// Everything a test needs: the services plus the fakes behind them.
class TestEnv {
  TestEnv({
    required this.services,
    required this.player,
    required this.notifications,
    required this.clock,
    required this.storage,
  });

  final AppServices services;
  final RecordingSoundPlayer player;
  final InMemoryNotificationService notifications;
  final FakeClock clock;
  final AppStorage storage;
}

/// Builds the services on top of fake storage, audio and notifications.
///
/// [prefs] is what "was saved before": pass it to simulate a relaunch.
Future<TestEnv> makeEnv({
  Map<String, Object> prefs = const {},
  FakeClock? clock,
  bool notificationsPermitted = true,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final storage = await AppStorage.open();
  final player = RecordingSoundPlayer();
  final notifications = InMemoryNotificationService(
    permitted: notificationsPermitted,
  );
  final fakeClock = clock ?? FakeClock();
  final services = AppServices.build(
    storage: storage,
    notifications: notifications,
    player: player,
    now: fakeClock.call,
  );
  return TestEnv(
    services: services,
    player: player,
    notifications: notifications,
    clock: fakeClock,
    storage: storage,
  );
}

/// Pumps the whole app on a phone-sized screen and waits out the splash.
Future<void> pumpApp(WidgetTester tester, TestEnv env) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(AiClockApp(services: env.services));
  await tester.pump(const Duration(milliseconds: 2700));
  await tester.pumpAndSettle();
}
