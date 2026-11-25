import 'package:ai_clock_1/core/services/sound_service.dart';
import 'package:ai_clock_1/core/widgets/glass_tab_bar.dart';
import 'package:ai_clock_1/core/widgets/pill_segments.dart';
import 'package:ai_clock_1/tools/clock/alarm/alarms_controller.dart';
import 'package:ai_clock_1/tools/clock/clock_screen.dart';
import 'package:ai_clock_1/tools/clock/timer/timer_controller.dart';
import 'package:ai_clock_1/tools/clock/widgets/clock_card.dart';
import 'package:ai_clock_1/tools/clock/world/city.dart';
import 'package:ai_clock_1/tools/clock/world/widgets/city_picker_sheet.dart';
import 'package:flutter/cupertino.dart' show CupertinoTimerPicker;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_app.dart';

Finder tabLabel(String label) =>
    find.descendant(of: find.byType(GlassTabBar), matching: find.text(label));

/// A section button of the Clock tool (World, Alarm, Stopwatch, Timer).
Finder segment(String label) => find.descendant(
  of: find.byType(PillSegments<ClockSection>),
  matching: find.text(label),
);

/// Text inside the Clock screen only (Home shows the same city names).
Finder inClock(Finder matching) =>
    find.descendant(of: find.byType(ClockScreen), matching: matching);

/// Text inside the city picker sheet only.
Finder inPicker(Finder matching) =>
    find.descendant(of: find.byType(CityPickerSheet), matching: matching);

/// Scrolls the Clock screen until [finder] is on screen, and lets the scroll
/// settle (tapping while it is still flinging would miss).
Future<void> scrollClockTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: inClock(find.byType(Scrollable)).first,
  );
  await tester.pumpAndSettle();
}

Future<void> openClock(WidgetTester tester, TestEnv env) async {
  await pumpApp(tester, env);
  await tester.tap(tabLabel('Clock'));
  await tester.pumpAndSettle();
}

Future<void> openSection(WidgetTester tester, String label) async {
  await tester.tap(segment(label));
  await tester.pumpAndSettle();
}

/// Lets the alerts controller's once-a-second check run, and the banner
/// animate in or out.
Future<void> tickAlerts(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  group('World', () {
    testWidgets('shows the local clock and the chosen cities', (tester) async {
      final env = await makeEnv();
      await openClock(tester, env);

      expect(find.byType(ClockCard), findsOneWidget);
      for (final city in ['New York', 'London', 'Tokyo', 'Sydney']) {
        expect(inClock(find.text(city)), findsOneWidget, reason: city);
      }
    });

    testWidgets('adds a city from the picker and saves it', (tester) async {
      final env = await makeEnv();
      await openClock(tester, env);

      await scrollClockTo(tester, find.text('Add city'));
      await tester.tap(find.text('Add city'));
      await tester.pumpAndSettle();

      expect(find.text('Search cities'), findsOneWidget);
      // A city that is already on the world clock is not offered again.
      await tester.enterText(find.byType(TextField), 'lon');
      await tester.pumpAndSettle();
      expect(inPicker(find.text('London')), findsNothing);
      expect(find.textContaining('No cities match'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'par');
      await tester.pumpAndSettle();
      expect(inPicker(find.text('Paris')), findsOneWidget);
      expect(inPicker(find.text('Berlin')), findsNothing);

      await tester.tap(inPicker(find.text('Paris')));
      await tester.pumpAndSettle();

      expect(env.services.worldClocks.contains(cityById('paris')!), isTrue);
      expect(env.storage.getString('world.cityIds'), contains('paris'));
      expect(inClock(find.text('Paris')), findsOneWidget);
    });

    testWidgets('the picker says so when nothing matches', (tester) async {
      final env = await makeEnv();
      await openClock(tester, env);
      await scrollClockTo(tester, find.text('Add city'));
      await tester.tap(find.text('Add city'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'zzzz');
      await tester.pumpAndSettle();
      expect(find.textContaining('No cities match'), findsOneWidget);
    });

    testWidgets('swiping a city away removes it, and Undo brings it back', (
      tester,
    ) async {
      final env = await makeEnv();
      await openClock(tester, env);

      // Bring it fully above the glass tab bar first, or the swipe lands on
      // the bar.
      await scrollClockTo(tester, inClock(find.text('London')));
      await tester.drag(inClock(find.text('London')), const Offset(-600, 0));
      await tester.pumpAndSettle();

      expect(env.services.worldClocks.contains(cityById('london')!), isFalse);
      expect(inClock(find.text('London')), findsNothing);
      expect(find.text('Removed London'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(env.services.worldClocks.contains(cityById('london')!), isTrue);
      expect(inClock(find.text('London')), findsOneWidget);
    });
  });

  group('Alarm', () {
    testWidgets('starts empty, then an alarm can be added', (tester) async {
      final env = await makeEnv();
      await openClock(tester, env);
      await openSection(tester, 'Alarm');

      expect(find.text('No alarms yet'), findsOneWidget);

      await tester.tap(find.text('Add alarm'));
      await tester.pumpAndSettle();
      expect(find.text('7:00 AM'), findsOneWidget); // The default time.

      await tester.tap(find.text('Mon'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Gym');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final alarm = env.services.alarms.alarms.single;
      expect((alarm.hour, alarm.minute), (7, 0));
      expect(alarm.days, {1});
      expect(alarm.label, 'Gym');
      expect(find.text('No alarms yet'), findsNothing);
      expect(inClock(find.textContaining('7:00')), findsOneWidget);
      expect(find.text('Gym · Mon'), findsOneWidget);
      expect(env.player.played, contains(Sfx.confirm));
    });

    testWidgets('the switch turns an alarm off and on', (tester) async {
      final env = await makeEnv();
      env.services.alarms.add(hour: 10, minute: 0);
      await openClock(tester, env);
      await openSection(tester, 'Alarm');
      await tester.pump(); // Let the notification scheduling finish.

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(env.services.alarms.alarms.single.enabled, isFalse);
      expect(env.notifications.scheduled, isEmpty);
      expect(env.player.played, contains(Sfx.toggleOff));

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(env.services.alarms.alarms.single.enabled, isTrue);
      expect(env.player.played, contains(Sfx.toggleOn));
    });

    testWidgets('tapping an alarm edits it, and it can be deleted', (
      tester,
    ) async {
      final env = await makeEnv();
      env.services.alarms.add(hour: 6, minute: 30, label: 'Run');
      await openClock(tester, env);
      await openSection(tester, 'Alarm');

      await tester.tap(inClock(find.textContaining('6:30')));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Delete alarm'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Run',
      );

      await tester.tap(find.byTooltip('Delete alarm'));
      await tester.pumpAndSettle();
      expect(env.services.alarms.alarms, isEmpty);
      expect(find.text('No alarms yet'), findsOneWidget);
    });

    testWidgets('swiping an alarm away can be undone', (tester) async {
      final env = await makeEnv();
      env.services.alarms.add(hour: 6, minute: 30);
      await openClock(tester, env);
      await openSection(tester, 'Alarm');

      await tester.drag(
        inClock(find.textContaining('6:30')),
        const Offset(-600, 0),
      );
      await tester.pumpAndSettle();
      expect(env.services.alarms.alarms, isEmpty);
      expect(find.text('Alarm deleted'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(env.services.alarms.alarms, hasLength(1));
    });

    testWidgets('rings in the app, can be snoozed, then stopped', (
      tester,
    ) async {
      final env = await makeEnv();
      env.services.alarms.add(hour: 9, minute: 5, label: 'Tea');
      await pumpApp(tester, env);

      env.clock.advance(const Duration(minutes: 6)); // 09:06
      await tickAlerts(tester);

      expect(find.text('Tea'), findsOneWidget);
      expect(find.text('Snooze'), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);
      expect(env.player.loops, [Sfx.alarm]);

      await tester.tap(find.text('Snooze'));
      await tester.pumpAndSettle();
      expect(find.text('Tea'), findsNothing);
      expect(
        env.notifications.scheduled.keys,
        contains(
          AlarmsController.snoozeNotificationId(
            env.services.alarms.alarms.single,
          ),
        ),
      );

      env.clock.advance(const Duration(minutes: 6)); // 09:12, past the snooze.
      await tickAlerts(tester);
      expect(find.text('Tea'), findsOneWidget);

      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();
      expect(find.text('Tea'), findsNothing);
      expect(env.player.stopLoopCalls, greaterThan(0));
    });
  });

  group('Stopwatch', () {
    testWidgets('starts, laps, stops and resets', (tester) async {
      final env = await makeEnv();
      await openClock(tester, env);
      await openSection(tester, 'Stopwatch');

      expect(find.text('00:00.00'), findsOneWidget);
      // Nothing to reset yet, so that button is inert.
      expect(find.text('Reset'), findsOneWidget);

      await tester.tap(find.text('Start'));
      await tester.pump();
      env.clock.advance(const Duration(seconds: 65, milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('01:05.25'), findsOneWidget);

      await tester.tap(find.text('Lap'));
      await tester.pump();
      env.clock.advance(const Duration(seconds: 10));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Lap'));
      await tester.pump();
      expect(find.text('Lap 1'), findsOneWidget);
      expect(find.text('Lap 2'), findsOneWidget);

      await tester.tap(find.text('Stop'));
      await tester.pump();
      final frozen = env.services.stopwatch.elapsed;
      env.clock.advance(const Duration(minutes: 5));
      await tester.pump(const Duration(milliseconds: 100));
      expect(env.services.stopwatch.elapsed, frozen);
      expect(find.text('Start'), findsOneWidget);

      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(find.text('00:00.00'), findsOneWidget);
      expect(find.text('Lap 1'), findsNothing);
    });

    testWidgets('keeps running while another tab is open', (tester) async {
      final env = await makeEnv();
      await openClock(tester, env);
      await openSection(tester, 'Stopwatch');
      await tester.tap(find.text('Start'));
      await tester.pump();

      await tester.tap(tabLabel('Day'));
      await tester.pumpAndSettle();
      env.clock.advance(const Duration(seconds: 90));

      await tester.tap(tabLabel('Clock'));
      await tester.pumpAndSettle();
      expect(find.text('01:30.00'), findsOneWidget);
    });
  });

  group('Timer', () {
    testWidgets('shows a picker with presets and starts the chosen time', (
      tester,
    ) async {
      final env = await makeEnv();
      await openClock(tester, env);
      await openSection(tester, 'Timer');

      expect(find.byType(CupertinoTimerPicker), findsOneWidget);
      await tester.tap(find.text('10 min'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();

      final timer = env.services.timer;
      expect(timer.phase, TimerPhase.running);
      expect(timer.total, const Duration(minutes: 10));
      expect(find.text('10:00'), findsOneWidget);
      expect(find.byType(CupertinoTimerPicker), findsNothing);
    });

    testWidgets('pauses, resumes, adds a minute and cancels', (tester) async {
      final env = await makeEnv();
      await openClock(tester, env);
      await openSection(tester, 'Timer');
      await tester.tap(find.text('10 min'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();

      env.clock.advance(const Duration(minutes: 1));
      await tester.tap(find.text('Pause'));
      await tester.pumpAndSettle();
      expect(env.services.timer.phase, TimerPhase.paused);

      env.clock.advance(const Duration(minutes: 3));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('09:00'), findsOneWidget); // Frozen at 9 minutes.

      await tester.tap(find.text('Resume'));
      await tester.pumpAndSettle();
      expect(env.services.timer.phase, TimerPhase.running);

      await tester.tap(find.text('1 min'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(env.services.timer.total, const Duration(minutes: 11));
      expect(find.text('10:00'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(env.services.timer.phase, TimerPhase.idle);
      expect(find.byType(CupertinoTimerPicker), findsOneWidget);
    });

    testWidgets('rings when finished, and the banner clears with the timer', (
      tester,
    ) async {
      final env = await makeEnv();
      await openClock(tester, env);
      await openSection(tester, 'Timer');
      await tester.tap(find.text('1 min'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();

      env.clock.advance(const Duration(seconds: 61));
      await tickAlerts(tester);

      expect(find.text('Timer finished'), findsOneWidget); // The banner.
      expect(find.text("Time's up"), findsWidgets);
      expect(env.player.loops, [Sfx.timerDone]);

      // The page's own Done button is enough: the banner follows.
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Timer finished'), findsNothing);
      expect(env.services.timer.phase, TimerPhase.idle);
      expect(env.player.stopLoopCalls, greaterThan(0));
    });

    testWidgets('the banner\'s OK button also finishes the timer', (
      tester,
    ) async {
      final env = await makeEnv();
      await openClock(tester, env);
      await openSection(tester, 'Timer');
      await tester.tap(find.text('1 min'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();

      env.clock.advance(const Duration(seconds: 61));
      await tickAlerts(tester);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('Timer finished'), findsNothing);
      expect(env.services.timer.phase, TimerPhase.idle);
    });
  });
}
