import 'package:ai_clock_1/app/alerts_controller.dart';
import 'package:ai_clock_1/core/services/app_storage.dart';
import 'package:ai_clock_1/core/services/sound_service.dart';
import 'package:ai_clock_1/core/settings/app_settings.dart';
import 'package:ai_clock_1/tools/clock/alarm/alarms_controller.dart';
import 'package:ai_clock_1/tools/clock/stopwatch/stopwatch_controller.dart';
import 'package:ai_clock_1/tools/clock/timer/timer_controller.dart';
import 'package:ai_clock_1/tools/clock/world/city.dart';
import 'package:ai_clock_1/tools/clock/world/world_clock_controller.dart';
import 'package:ai_clock_1/tools/day/reminders_controller.dart';
import 'package:ai_clock_1/tools/notes/note.dart';
import 'package:ai_clock_1/tools/notes/notes_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_app.dart';

/// Makes the env and makes sure its timers are cancelled when the test ends.
Future<TestEnv> env_({
  Map<String, Object> prefs = const {},
  FakeClock? clock,
}) async {
  final env = await makeEnv(prefs: prefs, clock: clock);
  addTearDown(env.services.dispose);
  return env;
}

/// Lets queued asynchronous work (notification scheduling) finish.
Future<void> settle() => pumpEventQueue();

void main() {
  // Haptic feedback goes through a platform channel.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Settings', () {
    test('start with sensible defaults', () async {
      final settings = (await env_()).services.settings;
      expect(settings.soundEffects, isTrue);
      expect(settings.alarmSounds, isTrue);
      expect(settings.haptics, isTrue);
      expect(settings.background, BackgroundStyle.aurora);
      expect(settings.timeFormat, TimeFormat.system);
    });

    test('are saved and come back after a restart', () async {
      final env = await env_();
      env.services.settings
        ..setSoundEffects(false)
        ..setAlarmSounds(false)
        ..setHaptics(false)
        ..setBackground(BackgroundStyle.ember)
        ..setTimeFormat(TimeFormat.h24);

      // A restart: brand-new settings reading whatever was saved.
      final reopened = AppSettings(await AppStorage.open());
      expect(reopened.soundEffects, isFalse);
      expect(reopened.alarmSounds, isFalse);
      expect(reopened.haptics, isFalse);
      expect(reopened.background, BackgroundStyle.ember);
      expect(reopened.timeFormat, TimeFormat.h24);
    });

    test('load values saved by an earlier run', () async {
      final env = await env_(
        prefs: {
          'settings.soundEffects': false,
          'settings.background': 'ocean',
          'settings.timeFormat': 'h12',
        },
      );
      expect(env.services.settings.soundEffects, isFalse);
      expect(env.services.settings.background, BackgroundStyle.ocean);
      expect(env.services.settings.timeFormat, TimeFormat.h12);
    });

    test('fall back to the default for an unknown saved choice', () async {
      final env = await env_(prefs: {'settings.background': 'nonsense'});
      expect(env.services.settings.background, BackgroundStyle.aurora);
    });

    test('notify listeners only when something changes', () async {
      final settings = (await env_()).services.settings;
      var calls = 0;
      settings.addListener(() => calls++);
      settings.setSoundEffects(true); // Already true.
      expect(calls, 0);
      settings.setSoundEffects(false);
      expect(calls, 1);
    });

    test('reset restores the defaults', () async {
      final settings = (await env_()).services.settings
        ..setSoundEffects(false)
        ..setBackground(BackgroundStyle.plain);
      settings.resetToDefaults();
      expect(settings.soundEffects, isTrue);
      expect(settings.background, BackgroundStyle.aurora);
    });
  });

  group('Sound and feedback', () {
    test('sound effects play only while enabled', () async {
      final env = await env_();
      env.services.sound.play(Sfx.tap);
      expect(env.player.played, [Sfx.tap]);

      env.services.settings.setSoundEffects(false);
      env.services.sound.play(Sfx.tap);
      expect(env.player.played, [Sfx.tap]); // Nothing new.
    });

    test(
      'the alert loop follows its own setting, not the effects one',
      () async {
        final env = await env_();
        env.services.settings.setSoundEffects(false);
        env.services.sound.startAlert(Sfx.alarm);
        expect(env.player.loops, [Sfx.alarm]);

        env.services.settings.setAlarmSounds(false);
        env.services.sound.startAlert(Sfx.alarm);
        expect(env.player.loops, [Sfx.alarm]); // Nothing new.
      },
    );

    test('feedback picks the right sound for each kind of tap', () async {
      final env = await env_();
      env.services.feedback
        ..tap()
        ..toggle(on: true)
        ..toggle(on: false)
        ..confirm();
      expect(env.player.played, [
        Sfx.tap,
        Sfx.toggleOn,
        Sfx.toggleOff,
        Sfx.confirm,
      ]);
    });

    test('a failing sound never throws', () async {
      final env = await env_();
      final broken = SoundService(
        player: _ThrowingPlayer(),
        settings: env.services.settings,
      );
      expect(() => broken.play(Sfx.tap), returnsNormally);
      expect(() => broken.startAlert(Sfx.alarm), returnsNormally);
      await Future<void>.delayed(Duration.zero); // Let the error be swallowed.
    });
  });

  group('World clocks', () {
    test('start with the default cities', () async {
      final world = (await env_()).services.worldClocks;
      expect([for (final c in world.cities) c.id], defaultCityIds);
    });

    test('adding and removing is saved', () async {
      final env = await env_();
      final world = env.services.worldClocks;
      final paris = cityById('paris')!;
      world.add(paris);
      world.add(paris); // Duplicate is ignored.
      world.remove(cityById('tokyo')!);

      final reopened = WorldClockController(await AppStorage.open());
      expect(reopened.cities.contains(paris), isTrue);
      expect(reopened.cities.where((c) => c == paris), hasLength(1));
      expect(reopened.cities.map((c) => c.id), isNot(contains('tokyo')));
    });

    test('ignore saved cities that no longer exist', () async {
      final env = await env_(prefs: {'world.cityIds': '["paris","atlantis"]'});
      expect(
        [for (final c in env.services.worldClocks.cities) c.id],
        ['paris'],
      );
    });
  });

  group('Alarms', () {
    // The fake clock starts on Saturday 7 Nov 2026, 09:00.
    test(
      'adding one saves it, schedules a notification and asks permission',
      () async {
        final env = await env_();
        final alarm = env.services.alarms.add(
          hour: 10,
          minute: 0,
          label: 'Tea',
        );
        await settle();

        final scheduled = env
            .notifications
            .scheduled[AlarmsController.notificationId(alarm, 0)];
        expect(scheduled, isNotNull);
        expect(scheduled!.at, DateTime(2026, 11, 7, 10, 0));
        expect(scheduled.title, 'Tea');
        expect(scheduled.repeatsWeekly, isFalse);
        expect(env.notifications.permissionRequests, 1);
      },
    );

    test(
      'a repeating alarm schedules one weekly notification per day',
      () async {
        final env = await env_();
        final alarm = env.services.alarms.add(hour: 7, minute: 0, days: {1, 3});
        await settle();

        final monday = env
            .notifications
            .scheduled[AlarmsController.notificationId(alarm, 1)]!;
        final wednesday = env
            .notifications
            .scheduled[AlarmsController.notificationId(alarm, 3)]!;
        expect(monday.at, DateTime(2026, 11, 9, 7, 0));
        expect(monday.repeatsWeekly, isTrue);
        expect(wednesday.at, DateTime(2026, 11, 11, 7, 0));
        expect(
          env.notifications.scheduled.containsKey(
            AlarmsController.notificationId(alarm, 0),
          ),
          isFalse,
        );
      },
    );

    test('switching an alarm off removes its notifications', () async {
      final env = await env_();
      final alarm = env.services.alarms.add(hour: 10, minute: 0);
      await settle();
      expect(env.notifications.scheduled, isNotEmpty);

      env.services.alarms.setEnabled(alarm, false);
      await settle();
      expect(env.notifications.scheduled, isEmpty);

      env.services.alarms.setEnabled(alarm, true);
      await settle();
      expect(env.notifications.scheduled, isNotEmpty);
    });

    test(
      'deleting an alarm removes its notifications; restore brings it back',
      () async {
        final env = await env_();
        final alarm = env.services.alarms.add(hour: 10, minute: 0);
        await settle();
        expect(env.notifications.scheduled, isNotEmpty);

        env.services.alarms.remove(alarm);
        await settle();
        expect(env.services.alarms.alarms, isEmpty);
        expect(env.notifications.scheduled, isEmpty);

        env.services.alarms.restore(alarm);
        await settle();
        expect(env.services.alarms.alarms, hasLength(1));
        expect(env.notifications.scheduled, isNotEmpty);
      },
    );

    test('are saved and come back after a restart', () async {
      final env = await env_();
      env.services.alarms.add(hour: 6, minute: 30, label: 'Gym', days: {2});

      final reopened = AlarmsController(
        storage: await AppStorage.open(),
        notifications: env.notifications,
        now: env.clock.call,
      );
      expect(reopened.alarms, hasLength(1));
      expect(reopened.alarms.single.label, 'Gym');
      expect(reopened.alarms.single.days, {2});
    });

    test('are listed in time-of-day order', () async {
      final alarms = (await env_()).services.alarms;
      alarms.add(hour: 22, minute: 0);
      alarms.add(hour: 6, minute: 15);
      alarms.add(hour: 6, minute: 5);
      expect(
        [for (final a in alarms.alarms) (a.hour, a.minute)],
        [(6, 5), (6, 15), (22, 0)],
      );
    });

    test('next is the soonest alarm that is switched on', () async {
      final alarms = (await env_()).services.alarms;
      expect(alarms.next, isNull);
      alarms.add(hour: 12, minute: 0);
      final soon = alarms.add(hour: 9, minute: 30);
      final off = alarms.add(hour: 9, minute: 10);
      alarms.setEnabled(off, false);
      expect(alarms.next!.alarm.id, soon.id);
      expect(alarms.next!.at, DateTime(2026, 11, 7, 9, 30));
    });

    test(
      'takeDue returns alarms in the window and switches one-offs off',
      () async {
        final env = await env_();
        final alarms = env.services.alarms;
        final once = alarms.add(hour: 9, minute: 30);
        final daily = alarms.add(
          hour: 9,
          minute: 30,
          days: {1, 2, 3, 4, 5, 6, 7},
        );

        final due = alarms.takeDue(
          DateTime(2026, 11, 7, 9, 0),
          DateTime(2026, 11, 7, 9, 31),
        );
        expect({for (final a in due) a.id}, {once.id, daily.id});
        expect(alarms.byId(once.id)!.enabled, isFalse); // One-off is done.
        expect(alarms.byId(daily.id)!.enabled, isTrue); // Repeating stays on.

        // Nothing is due in a later window.
        expect(
          alarms.takeDue(
            DateTime(2026, 11, 7, 9, 31),
            DateTime(2026, 11, 7, 9, 32),
          ),
          isEmpty,
        );
      },
    );
  });

  group('Timer', () {
    test('starting schedules a notification for the end', () async {
      final env = await env_();
      final timer = env.services.timer;
      timer.setDuration(const Duration(minutes: 5));
      timer.start();

      expect(timer.phase, TimerPhase.running);
      expect(
        env.notifications.scheduled[TimerController.notificationId]!.at,
        DateTime(2026, 11, 7, 9, 5),
      );
    });

    test('counts down and reports progress', () async {
      final env = await env_();
      final timer = env.services.timer
        ..setDuration(const Duration(minutes: 5))
        ..start();
      env.clock.advance(const Duration(minutes: 2));
      expect(timer.remaining, const Duration(minutes: 3));
      expect(timer.progress, closeTo(0.4, 0.001));
    });

    test('pausing freezes the time and removes the notification', () async {
      final env = await env_();
      final timer = env.services.timer
        ..setDuration(const Duration(minutes: 5))
        ..start();
      env.clock.advance(const Duration(minutes: 1));
      timer.pause();
      env.clock.advance(const Duration(minutes: 10));

      expect(timer.phase, TimerPhase.paused);
      expect(timer.remaining, const Duration(minutes: 4));
      expect(env.notifications.scheduled, isEmpty);

      timer.resume();
      expect(
        env.notifications.scheduled[TimerController.notificationId]!.at,
        env.clock().add(const Duration(minutes: 4)),
      );
    });

    test('finishes exactly once when its time is up', () async {
      final env = await env_();
      final timer = env.services.timer
        ..setDuration(const Duration(minutes: 1))
        ..start();

      env.clock.advance(const Duration(seconds: 59));
      expect(timer.takeFinished(env.clock()), isFalse);
      env.clock.advance(const Duration(seconds: 2));
      expect(timer.takeFinished(env.clock()), isTrue);
      expect(timer.phase, TimerPhase.finished);
      expect(timer.takeFinished(env.clock()), isFalse);

      timer.acknowledgeFinished();
      expect(timer.phase, TimerPhase.idle);
      expect(
        timer.remaining,
        const Duration(minutes: 1),
      ); // Back to set length.
    });

    test('"+1 min" extends a running timer', () async {
      final env = await env_();
      final timer = env.services.timer
        ..setDuration(const Duration(minutes: 1))
        ..start()
        ..addMinute();
      expect(timer.remaining, const Duration(minutes: 2));
      expect(timer.total, const Duration(minutes: 2));
    });

    test('cancel returns to idle and removes the notification', () async {
      final env = await env_();
      final timer = env.services.timer
        ..setDuration(const Duration(minutes: 1))
        ..start()
        ..cancel();
      expect(timer.phase, TimerPhase.idle);
      expect(env.notifications.scheduled, isEmpty);
    });

    test('ignores a zero length and changes while running', () async {
      final env = await env_();
      final timer = env.services.timer;
      timer.setDuration(Duration.zero); // Ignored: a timer needs some time.
      expect(timer.total, TimerController.defaultDuration);

      timer.setDuration(const Duration(minutes: 2));
      expect(timer.total, const Duration(minutes: 2));
      timer.start();
      timer.setDuration(const Duration(minutes: 9)); // Ignored while running.
      expect(timer.total, const Duration(minutes: 2));
    });

    test('keeps running after a restart', () async {
      final env = await env_();
      env.services.timer
        ..setDuration(const Duration(minutes: 10))
        ..start();
      env.clock.advance(const Duration(minutes: 3));

      final reopened = TimerController(
        storage: await AppStorage.open(),
        notifications: env.notifications,
        now: env.clock.call,
      );
      expect(reopened.phase, TimerPhase.running);
      expect(reopened.remaining, const Duration(minutes: 7));
    });

    test(
      'a timer that ran out while the app was closed comes back idle',
      () async {
        final env = await env_();
        env.services.timer
          ..setDuration(const Duration(minutes: 1))
          ..start();
        env.clock.advance(const Duration(minutes: 5));

        final reopened = TimerController(
          storage: await AppStorage.open(),
          notifications: env.notifications,
          now: env.clock.call,
        );
        expect(reopened.phase, TimerPhase.idle);
      },
    );

    test('a paused timer is restored too', () async {
      final env = await env_();
      env.services.timer
        ..setDuration(const Duration(minutes: 10))
        ..start();
      env.clock.advance(const Duration(minutes: 4));
      env.services.timer.pause();

      final reopened = TimerController(
        storage: await AppStorage.open(),
        notifications: env.notifications,
        now: env.clock.call,
      );
      expect(reopened.phase, TimerPhase.paused);
      expect(reopened.remaining, const Duration(minutes: 6));
    });
  });

  group('Stopwatch', () {
    test('measures time while running and stops cleanly', () {
      final clock = FakeClock();
      final sw = StopwatchController(now: clock.call);
      expect(sw.elapsed, Duration.zero);

      sw.start();
      clock.advance(const Duration(milliseconds: 1500));
      expect(sw.elapsed, const Duration(milliseconds: 1500));

      sw.stop();
      clock.advance(const Duration(seconds: 30));
      expect(sw.elapsed, const Duration(milliseconds: 1500));

      sw.start(); // Resumes where it left off.
      clock.advance(const Duration(seconds: 1));
      expect(sw.elapsed, const Duration(milliseconds: 2500));
    });

    test('records laps with their own time and the running total', () {
      final clock = FakeClock();
      final sw = StopwatchController(now: clock.call)..start();
      clock.advance(const Duration(seconds: 3));
      sw.lap();
      clock.advance(const Duration(seconds: 5));
      sw.lap();

      final laps = sw.laps; // Newest first.
      expect(laps.map((l) => l.number), [2, 1]);
      expect(laps[0].lapTime, const Duration(seconds: 5));
      expect(laps[0].total, const Duration(seconds: 8));
      expect(laps[1].lapTime, const Duration(seconds: 3));
    });

    test('picks the fastest and slowest lap once there are two', () {
      final clock = FakeClock();
      final sw = StopwatchController(now: clock.call)..start();
      clock.advance(const Duration(seconds: 3));
      sw.lap();
      expect(sw.extremes, isNull);
      clock.advance(const Duration(seconds: 5));
      sw.lap();
      clock.advance(const Duration(seconds: 4));
      sw.lap();

      expect(sw.extremes!.fastest.number, 1);
      expect(sw.extremes!.slowest.number, 2);
    });

    test('ignores a lap while stopped, and reset clears everything', () {
      final clock = FakeClock();
      final sw = StopwatchController(now: clock.call);
      sw.lap();
      expect(sw.laps, isEmpty);

      sw.start();
      clock.advance(const Duration(seconds: 2));
      sw.lap();
      sw.stop();
      expect(sw.hasTime, isTrue);

      sw.reset();
      expect(sw.elapsed, Duration.zero);
      expect(sw.laps, isEmpty);
      expect(sw.hasTime, isFalse);
      expect(sw.running, isFalse);
    });
  });

  group('Reminders', () {
    final today = DateTime(2026, 11, 7);

    test('a timed item in the future schedules a notification', () async {
      final env = await env_();
      final item = env.services.reminders.add(
        title: 'Call mum',
        date: today,
        minutes: 15 * 60,
      );
      await settle();
      final scheduled = env.notifications.scheduled.values.single;
      expect(scheduled.title, 'Call mum');
      expect(scheduled.at, DateTime(2026, 11, 7, 15, 0));
      expect(item.at, scheduled.at);
    });

    test('all-day and already-past items schedule nothing', () async {
      final env = await env_();
      env.services.reminders.add(title: 'Pay rent', date: today);
      env.services.reminders.add(
        title: 'Earlier',
        date: today,
        minutes: 8 * 60,
      );
      await settle();
      expect(env.notifications.scheduled, isEmpty);
    });

    test('ticking an item off removes its notification', () async {
      final env = await env_();
      final item = env.services.reminders.add(
        title: 'Call',
        date: today,
        minutes: 15 * 60,
      );
      await settle();
      expect(env.notifications.scheduled, hasLength(1)); // It was scheduled...

      env.services.reminders.toggleDone(item);
      await settle();
      expect(env.notifications.scheduled, isEmpty); // ...and is now gone.
    });

    test(
      'lists a day with open items first, then all-day, then by time',
      () async {
        final reminders = (await env_()).services.reminders;
        final late = reminders.add(
          title: 'Late',
          date: today,
          minutes: 20 * 60,
        );
        final early = reminders.add(
          title: 'Early',
          date: today,
          minutes: 8 * 60,
        );
        final allDay = reminders.add(title: 'All day', date: today);
        final done = reminders.add(title: 'Done', date: today, minutes: 7 * 60);
        reminders.toggleDone(done);
        reminders.add(title: 'Tomorrow', date: DateTime(2026, 11, 8));

        expect(
          [for (final r in reminders.forDay(today)) r.id],
          [allDay.id, early.id, late.id, done.id],
        );
        expect(reminders.openCount(today), 3);
        expect(reminders.hasItems(DateTime(2026, 11, 8)), isTrue);
        expect(reminders.hasItems(DateTime(2026, 11, 9)), isFalse);
      },
    );

    test('takeDue finds open timed items in the window only', () async {
      final reminders = (await env_()).services.reminders;
      final due = reminders.add(
        title: 'Soon',
        date: today,
        minutes: 9 * 60 + 10,
      );
      final later = reminders.add(
        title: 'Later',
        date: today,
        minutes: 18 * 60,
      );
      final done = reminders.add(
        title: 'Done',
        date: today,
        minutes: 9 * 60 + 5,
      );
      reminders.toggleDone(done);

      final found = reminders.takeDue(
        DateTime(2026, 11, 7, 9, 0),
        DateTime(2026, 11, 7, 9, 30),
      );
      expect(found.map((r) => r.id), [due.id]);
      expect(found.map((r) => r.id), isNot(contains(later.id)));
    });

    test('are saved, and deleting can be undone', () async {
      final env = await env_();
      final item = env.services.reminders.add(title: 'Dentist', date: today);

      final reopened = RemindersController(
        storage: await AppStorage.open(),
        notifications: env.notifications,
        now: env.clock.call,
      );
      expect(reopened.forDay(today).single.title, 'Dentist');

      env.services.reminders.remove(item);
      expect(env.services.reminders.forDay(today), isEmpty);
      env.services.reminders.restore(item);
      expect(env.services.reminders.forDay(today), hasLength(1));
    });
  });

  group('Notes', () {
    test('a new draft is not stored until it has text', () async {
      final notes = (await env_()).services.notes;
      final draft = notes.createDraft();
      expect(notes.notes, isEmpty);

      notes.save(draft); // Still empty.
      expect(notes.notes, isEmpty);

      notes.save(draft.copyWith(body: 'Buy milk'));
      expect(notes.notes, hasLength(1));
    });

    test('saving an emptied note removes it', () async {
      final notes = (await env_()).services.notes;
      final stored = notes.save(notes.createDraft().copyWith(title: 'Idea'));
      notes.save(stored.copyWith(title: '', body: ''));
      expect(notes.notes, isEmpty);
    });

    test('are saved and come back after a restart', () async {
      final env = await env_();
      env.services.notes.save(
        env.services.notes.createDraft().copyWith(
          title: 'Plan',
          body: 'Ship it',
        ),
      );

      final reopened = NotesController(storage: await AppStorage.open());
      expect(reopened.notes.single.title, 'Plan');
      expect(reopened.notes.single.body, 'Ship it');
    });

    test('puts pinned notes first, then the most recently edited', () async {
      final env = await env_();
      final notes = env.services.notes;
      Note add(String title) =>
          notes.save(notes.createDraft().copyWith(title: title));

      final first = add('First');
      env.clock.advance(const Duration(minutes: 1));
      final second = add('Second');
      env.clock.advance(const Duration(minutes: 1));
      final third = add('Third');
      expect(
        [for (final n in notes.notes) n.title],
        ['Third', 'Second', 'First'],
      );

      notes.togglePin(first);
      expect(notes.notes.first.title, 'First');
      expect(second.id, isNot(third.id));
    });

    test('search matches the title or text, ignoring case', () async {
      final notes = (await env_()).services.notes;
      notes.save(
        notes.createDraft().copyWith(title: 'Groceries', body: 'milk'),
      );
      notes.save(
        notes.createDraft().copyWith(title: 'Work', body: 'Send REPORT'),
      );

      expect(notes.search('GROCER').map((n) => n.title), ['Groceries']);
      expect(notes.search('report').map((n) => n.title), ['Work']);
      expect(notes.search('nothing'), isEmpty);
      expect(notes.search('  ').length, 2); // Blank query shows everything.
    });

    test('deleting can be undone', () async {
      final notes = (await env_()).services.notes;
      final note = notes.save(notes.createDraft().copyWith(title: 'Keep me'));
      notes.delete(note);
      expect(notes.notes, isEmpty);
      notes.restore(note);
      expect(notes.notes.single.title, 'Keep me');
    });

    test('re-saving unchanged text keeps the edit time', () async {
      final env = await env_();
      final notes = env.services.notes;
      final stored = notes.save(notes.createDraft().copyWith(title: 'Same'));
      env.clock.advance(const Duration(hours: 1));
      final again = notes.save(stored);
      expect(again.updatedAt, stored.updatedAt);
    });
  });

  group('Alerts', () {
    // The fake clock starts on Saturday 7 Nov 2026, 09:00.
    test(
      'an alarm rings when due: banner, looping sound, one-off switches off',
      () async {
        final env = await env_();
        final alarm = env.services.alarms.add(
          hour: 9,
          minute: 30,
          label: 'Tea',
        );
        env.clock.advance(const Duration(minutes: 31));
        env.services.alerts.tick();

        final current = env.services.alerts.current!;
        expect(current.kind, AlertKind.alarm);
        expect(current.title, 'Tea');
        expect(env.player.loops, [Sfx.alarm]);
        expect(env.services.alarms.byId(alarm.id)!.enabled, isFalse);
        // The app rang it itself, so the system notification is dropped.
        expect(
          env.notifications.scheduled.containsKey(
            AlarmsController.notificationId(alarm, 0),
          ),
          isFalse,
        );
      },
    );

    test(
      'a repeating alarm gets its weekly notification back after ringing',
      () async {
        final env = await env_();
        // 09:30 every day. Saturday's notification is dropped when it rings...
        final alarm = env.services.alarms.add(
          hour: 9,
          minute: 30,
          days: {1, 2, 3, 4, 5, 6, 7},
        );
        env.clock.advance(const Duration(minutes: 31));
        env.services.alerts.tick();
        await Future<void>.delayed(Duration.zero);

        // ...and is scheduled again for next Saturday (still repeating weekly).
        final saturday = env
            .notifications
            .scheduled[AlarmsController.notificationId(alarm, 6)]!;
        expect(saturday.repeatsWeekly, isTrue);
        expect(saturday.at, DateTime(2026, 11, 14, 9, 30));
      },
    );

    test('dismissing stops the sound and clears the banner', () async {
      final env = await env_();
      env.services.alarms.add(hour: 9, minute: 30);
      env.clock.advance(const Duration(minutes: 31));
      env.services.alerts.tick();
      expect(env.services.alerts.current, isNotNull);

      env.services.alerts.dismiss();
      expect(env.services.alerts.current, isNull);
      expect(env.player.stopLoopCalls, greaterThan(0));
    });

    test('snoozing rings the alarm again five minutes later', () async {
      final env = await env_();
      final alarm = env.services.alarms.add(hour: 9, minute: 30);
      env.clock.advance(const Duration(minutes: 31)); // 09:31
      env.services.alerts.tick();
      env.services.alerts.snooze();

      expect(env.services.alerts.current, isNull);
      final snoozeAt = env
          .notifications
          .scheduled[AlarmsController.snoozeNotificationId(alarm)]!
          .at;
      expect(snoozeAt, DateTime(2026, 11, 7, 9, 36));

      env.clock.advance(const Duration(minutes: 4)); // 09:35
      env.services.alerts.tick();
      expect(env.services.alerts.current, isNull);

      env.clock.advance(const Duration(minutes: 2)); // 09:37
      env.services.alerts.tick();
      expect(env.services.alerts.current?.kind, AlertKind.alarm);
      expect(
        env.notifications.scheduled.containsKey(
          AlarmsController.snoozeNotificationId(alarm),
        ),
        isFalse,
      );
    });

    test(
      'a finished timer rings, and acknowledging it clears the banner',
      () async {
        final env = await env_();
        env.services.timer
          ..setDuration(const Duration(minutes: 1))
          ..start();
        env.clock.advance(const Duration(seconds: 61));
        env.services.alerts.tick();

        expect(env.services.alerts.current?.kind, AlertKind.timer);
        expect(env.player.loops, [Sfx.timerDone]);

        // The timer page's "Done" button only touches the timer.
        env.services.timer.acknowledgeFinished();
        expect(env.services.alerts.current, isNull);
        expect(env.services.timer.phase, TimerPhase.idle);
        expect(env.player.stopLoopCalls, greaterThan(0));
      },
    );

    test('alerts that arrive together are shown one at a time', () async {
      final env = await env_();
      env.services.alarms.add(hour: 9, minute: 30);
      env.services.timer
        ..setDuration(const Duration(minutes: 1))
        ..start();
      env.clock.advance(const Duration(minutes: 31));
      env.services.alerts.tick();

      expect(env.services.alerts.current?.kind, AlertKind.alarm);
      env.services.alerts.dismiss();
      expect(env.services.alerts.current?.kind, AlertKind.timer);
      env.services.alerts.dismiss();
      expect(env.services.alerts.current, isNull);
      expect(env.services.timer.phase, TimerPhase.idle);
    });

    test('a due reminder shows a banner with a soft sound', () async {
      final env = await env_();
      env.services.reminders.add(
        title: 'Stand up',
        date: DateTime(2026, 11, 7),
        minutes: 9 * 60 + 10,
      );
      env.clock.advance(const Duration(minutes: 11));
      env.services.alerts.tick();

      expect(env.services.alerts.current?.kind, AlertKind.reminder);
      expect(env.services.alerts.current?.title, 'Stand up');
      expect(env.player.played, contains(Sfx.confirm));
      expect(env.notifications.scheduled, isEmpty);
    });

    test('the banner still shows when alarm sounds are off', () async {
      final env = await env_();
      env.services.settings.setAlarmSounds(false);
      env.services.alarms.add(hour: 9, minute: 30);
      env.clock.advance(const Duration(minutes: 31));
      env.services.alerts.tick();

      expect(env.services.alerts.current, isNotNull);
      expect(env.player.loops, isEmpty);
    });

    test(
      'alarms that passed while the app was away do not ring late',
      () async {
        final env = await env_();
        env.services.alarms.add(hour: 9, minute: 30);
        env.clock.advance(
          const Duration(hours: 2),
        ); // The app was in the background.
        env.services.alerts.didChangeAppLifecycleState(
          AppLifecycleState.resumed,
        );
        env.services.alerts.tick();

        expect(env.services.alerts.current, isNull);
      },
    );

    test('an alarm is not rung twice for the same minute', () async {
      final env = await env_();
      env.services.alarms.add(hour: 9, minute: 30, days: {1, 2, 3, 4, 5, 6, 7});
      env.clock.advance(const Duration(minutes: 31));
      env.services.alerts.tick();
      env.services.alerts.dismiss();
      env.services.alerts.tick();
      env.clock.advance(const Duration(seconds: 1));
      env.services.alerts.tick();

      expect(env.services.alerts.current, isNull);
      expect(env.player.loops, hasLength(1));
    });
  });
}

class _ThrowingPlayer implements SoundPlayer {
  @override
  Future<void> play(Sfx sfx) => Future.error('boom');

  @override
  Future<void> startLoop(Sfx sfx) => Future.error('boom');

  @override
  Future<void> stopLoop() async {}

  @override
  Future<void> dispose() async {}
}
