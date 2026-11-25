import 'package:flutter/widgets.dart';

import '../core/di/provide.dart';
import '../core/services/app_storage.dart';
import '../core/services/feedback_service.dart';
import '../core/services/local_notification_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/sound_service.dart';
import '../core/settings/app_settings.dart';
import '../tools/clock/alarm/alarms_controller.dart';
import '../tools/clock/stopwatch/stopwatch_controller.dart';
import '../tools/clock/timer/timer_controller.dart';
import '../tools/clock/world/world_clock_controller.dart';
import '../tools/day/reminders_controller.dart';
import '../tools/notes/notes_controller.dart';
import 'alerts_controller.dart';

/// Every service and controller the app uses, built in one place.
///
/// [create] wires the real platform implementations; [AppServices.build]
/// takes the platform parts as arguments, so tests can pass fakes.
class AppServices {
  AppServices._({
    required this.storage,
    required this.notifications,
    required this.settings,
    required this.sound,
    required this.feedback,
    required this.worldClocks,
    required this.alarms,
    required this.stopwatch,
    required this.timer,
    required this.reminders,
    required this.notes,
    required this.alerts,
  });

  final AppStorage storage;
  final NotificationService notifications;
  final AppSettings settings;
  final SoundService sound;
  final FeedbackService feedback;
  final WorldClockController worldClocks;
  final AlarmsController alarms;
  final StopwatchController stopwatch;
  final TimerController timer;
  final RemindersController reminders;
  final NotesController notes;
  final AlertsController alerts;

  /// The real thing: saved data, system notifications and audio.
  static Future<AppServices> create() async {
    final storage = await AppStorage.open();
    final notifications = LocalNotificationService();
    await notifications.init();
    return AppServices.build(
      storage: storage,
      notifications: notifications,
      player: AudioplayersSoundPlayer(),
    );
  }

  factory AppServices.build({
    required AppStorage storage,
    required NotificationService notifications,
    required SoundPlayer player,
    DateTime Function()? now,
  }) {
    final settings = AppSettings(storage);
    final sound = SoundService(player: player, settings: settings);
    final alarms = AlarmsController(
      storage: storage,
      notifications: notifications,
      now: now,
    );
    final timer = TimerController(
      storage: storage,
      notifications: notifications,
      now: now,
    );
    final reminders = RemindersController(
      storage: storage,
      notifications: notifications,
      now: now,
    );
    return AppServices._(
      storage: storage,
      notifications: notifications,
      settings: settings,
      sound: sound,
      feedback: FeedbackService(settings: settings, sound: sound),
      worldClocks: WorldClockController(storage),
      alarms: alarms,
      stopwatch: StopwatchController(now: now),
      timer: timer,
      reminders: reminders,
      notes: NotesController(storage: storage, now: now),
      alerts: AlertsController(
        alarms: alarms,
        timer: timer,
        reminders: reminders,
        sound: sound,
        notifications: notifications,
        now: now,
      ),
    );
  }

  /// Starts the background work: re-arming notifications and watching for
  /// anything that is due while the app is open.
  void start({bool observeLifecycle = true}) {
    alarms.syncNotifications();
    reminders.syncNotifications();
    alerts.start(observeLifecycle: observeLifecycle);
  }

  void dispose() {
    alerts.dispose();
    sound.dispose();
  }
}

/// Makes every service available below it with `context.read<T>()`.
class AppProviders extends StatelessWidget {
  const AppProviders({super.key, required this.services, required this.child});

  final AppServices services;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final wrappers = <Widget Function(Widget)>[
      (c) => Provide<AppSettings>(value: services.settings, child: c),
      (c) => Provide<SoundService>(value: services.sound, child: c),
      (c) => Provide<FeedbackService>(value: services.feedback, child: c),
      (c) =>
          Provide<NotificationService>(value: services.notifications, child: c),
      (c) =>
          Provide<WorldClockController>(value: services.worldClocks, child: c),
      (c) => Provide<AlarmsController>(value: services.alarms, child: c),
      (c) => Provide<StopwatchController>(value: services.stopwatch, child: c),
      (c) => Provide<TimerController>(value: services.timer, child: c),
      (c) => Provide<RemindersController>(value: services.reminders, child: c),
      (c) => Provide<NotesController>(value: services.notes, child: c),
      (c) => Provide<AlertsController>(value: services.alerts, child: c),
    ];
    return wrappers.reversed.fold(child, (inner, wrap) => wrap(inner));
  }
}
