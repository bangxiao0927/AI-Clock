import 'package:ai_clock_1/core/services/sound_service.dart';
import 'package:ai_clock_1/core/settings/app_settings.dart';
import 'package:ai_clock_1/core/widgets/glass_tab_bar.dart';
import 'package:ai_clock_1/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_app.dart';

Finder tabLabel(String label) =>
    find.descendant(of: find.byType(GlassTabBar), matching: find.text(label));

Future<void> openOptions(WidgetTester tester, TestEnv env) async {
  await pumpApp(tester, env);
  await tester.tap(tabLabel('Options'));
  await tester.pumpAndSettle();
  env.player.played.clear(); // Ignore the sound of opening the tab.
}

/// Scrolls the Options list until [finder] exists and is on screen. The list
/// builds its rows lazily, so rows far down do not exist until scrolled to.
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find
        .descendant(
          of: find.byType(SettingsScreen),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

/// Scrolls [finder] into view and taps it.
Future<void> tapScrolled(WidgetTester tester, Finder finder) async {
  await scrollTo(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Switch switchAt(WidgetTester tester, int index) =>
    tester.widget<Switch>(find.byType(Switch).at(index));

void main() {
  testWidgets('shows every setting', (tester) async {
    final env = await makeEnv();
    await openOptions(tester, env);

    expect(find.text('Sound effects'), findsOneWidget);
    expect(find.text('Alarm & timer sounds'), findsOneWidget);
    expect(find.text('Haptics'), findsOneWidget);
    expect(find.text('Background'), findsOneWidget);
    for (final style in BackgroundStyle.values) {
      expect(find.text(style.label), findsOneWidget, reason: style.label);
    }
    expect(find.text('Time format'), findsOneWidget);

    await scrollTo(tester, find.text('Alerts when closed'));
    expect(find.text('Alerts when closed'), findsOneWidget);
    await scrollTo(tester, find.text('Reset to defaults'));
    expect(find.text('Reset to defaults'), findsOneWidget);
  });

  testWidgets('switching sound effects off saves it and clicks once', (
    tester,
  ) async {
    final env = await makeEnv();
    await openOptions(tester, env);
    expect(switchAt(tester, 0).value, isTrue);

    await tester.tap(find.text('Sound effects'));
    await tester.pumpAndSettle();

    expect(switchAt(tester, 0).value, isFalse);
    expect(env.services.settings.soundEffects, isFalse);
    expect(env.storage.getBool('settings.soundEffects'), isFalse);
    // The "off" click is heard once, then it goes quiet.
    expect(env.player.played, [Sfx.toggleOff]);

    await tester.tap(find.text('Haptics'));
    await tester.pumpAndSettle();
    expect(env.player.played, [Sfx.toggleOff]); // Nothing more.
  });

  testWidgets('switching sound effects back on is audible', (tester) async {
    final env = await makeEnv(prefs: {'settings.soundEffects': false});
    await openOptions(tester, env);
    expect(switchAt(tester, 0).value, isFalse);

    await tester.tap(find.text('Sound effects'));
    await tester.pumpAndSettle();

    expect(env.services.settings.soundEffects, isTrue);
    expect(env.player.played, [Sfx.toggleOn]);
  });

  testWidgets('the switch itself works as well as the row', (tester) async {
    final env = await makeEnv();
    await openOptions(tester, env);

    await tester.tap(find.byType(Switch).at(1));
    await tester.pumpAndSettle();
    expect(env.services.settings.alarmSounds, isFalse);
    expect(env.storage.getBool('settings.alarmSounds'), isFalse);

    await tester.tap(find.byType(Switch).at(2));
    await tester.pumpAndSettle();
    expect(env.services.settings.haptics, isFalse);
    expect(env.storage.getBool('settings.haptics'), isFalse);
  });

  testWidgets('choosing a background saves it', (tester) async {
    final env = await makeEnv();
    await openOptions(tester, env);

    await tapScrolled(tester, find.text('Ocean'));

    expect(env.services.settings.background, BackgroundStyle.ocean);
    expect(env.storage.getString('settings.background'), 'ocean');
    expect(env.player.played, [Sfx.tap]);

    await tapScrolled(tester, find.text('Plain'));
    expect(env.services.settings.background, BackgroundStyle.plain);
  });

  testWidgets('the time format changes how alarm times are shown', (
    tester,
  ) async {
    final env = await makeEnv();
    env.services.alarms.add(hour: 14, minute: 30);
    await openOptions(tester, env);

    // The test device defaults to 12-hour time.
    await tester.tap(tabLabel('Home'));
    await tester.pumpAndSettle();
    expect(find.textContaining('2:30 PM'), findsOneWidget);

    await tester.tap(tabLabel('Options'));
    await tester.pumpAndSettle();
    await tapScrolled(tester, find.text('24-hour'));
    expect(env.storage.getString('settings.timeFormat'), 'h24');

    await tester.tap(tabLabel('Home'));
    await tester.pumpAndSettle();
    expect(find.textContaining('14:30'), findsOneWidget);
    expect(find.textContaining('2:30 PM'), findsNothing);
  });

  testWidgets('settings are remembered after the app is fully closed', (
    tester,
  ) async {
    final first = await makeEnv();
    await openOptions(tester, first);
    await tester.tap(find.text('Sound effects'));
    await tester.pumpAndSettle();
    await tapScrolled(tester, find.text('Ember'));
    await tapScrolled(tester, find.text('24-hour'));

    // Everything that was saved, as the next launch would find it on disk.
    final prefs = await SharedPreferences.getInstance();
    final saved = <String, Object>{
      for (final key in prefs.getKeys()) key: prefs.get(key)!,
    };

    // Close the app completely...
    await tester.pumpWidget(const SizedBox());

    // ...and start it again from what was saved.
    final second = await makeEnv(prefs: saved);
    await openOptions(tester, second);

    expect(second.services.settings.soundEffects, isFalse);
    expect(second.services.settings.background, BackgroundStyle.ember);
    expect(second.services.settings.timeFormat, TimeFormat.h24);
    expect(switchAt(tester, 0).value, isFalse); // The switch shows it too.
  });

  testWidgets('reset to defaults restores everything', (tester) async {
    final env = await makeEnv(
      prefs: {
        'settings.soundEffects': false,
        'settings.haptics': false,
        'settings.background': 'plain',
      },
    );
    await openOptions(tester, env);

    await tapScrolled(tester, find.text('Reset to defaults'));

    expect(env.services.settings.soundEffects, isTrue);
    expect(env.services.settings.haptics, isTrue);
    expect(env.services.settings.background, BackgroundStyle.aurora);
    expect(switchAt(tester, 0).value, isTrue);
  });

  group('notifications card', () {
    testWidgets('offers to allow notifications when they are off', (
      tester,
    ) async {
      final env = await makeEnv(notificationsPermitted: false);
      await openOptions(tester, env);

      await scrollTo(tester, find.text('Alerts when closed'));
      expect(find.text('Allow'), findsOneWidget);

      env.notifications.permitted = true; // The user says yes in the dialog.
      await tester.tap(find.text('Allow'));
      await tester.pumpAndSettle();

      expect(env.notifications.permissionRequests, 1);
      expect(find.text('Allow'), findsNothing);
      expect(
        find.textContaining('even when the app is closed'),
        findsOneWidget,
      );
    });

    testWidgets('has no button when notifications are already allowed', (
      tester,
    ) async {
      final env = await makeEnv();
      await openOptions(tester, env);

      await scrollTo(tester, find.text('Alerts when closed'));
      expect(find.text('Allow'), findsNothing);
      expect(
        find.textContaining('even when the app is closed'),
        findsOneWidget,
      );
    });
  });
}
