import 'package:ai_clock_1/app/app.dart';
import 'package:ai_clock_1/app/app_shell.dart';
import 'package:ai_clock_1/core/constants.dart';
import 'package:ai_clock_1/core/services/sound_service.dart';
import 'package:ai_clock_1/core/widgets/glass_tab_bar.dart';
import 'package:ai_clock_1/features/home/home_screen.dart';
import 'package:ai_clock_1/features/settings/settings_screen.dart';
import 'package:ai_clock_1/features/splash/splash_screen.dart';
import 'package:ai_clock_1/tools/clock/clock_screen.dart';
import 'package:ai_clock_1/tools/day/day_screen.dart';
import 'package:ai_clock_1/tools/notes/notes_screen.dart';
import 'package:ai_clock_1/tools/tool_registry.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_app.dart';

/// A label inside the glass tab bar (Home also shows some of the same words).
Finder tabLabel(String label) =>
    find.descendant(of: find.byType(GlassTabBar), matching: find.text(label));

int selectedTab(WidgetTester tester) =>
    tester.widget<GlassTabBar>(find.byType(GlassTabBar)).currentIndex;

void main() {
  test('app name is exactly "AI clock 1"', () {
    expect(AppInfo.name, 'AI clock 1');
  });

  test('the tool registry has the three tools with unique ids', () {
    final ids = appTools.map((tool) => tool.info.id).toList();
    expect(ids, ['clock', 'day', 'notes']);
    expect(ids.toSet().length, ids.length);
  });

  testWidgets('splash screen leads to the app shell on the Home tab', (
    tester,
  ) async {
    final env = await makeEnv();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(AiClockApp(services: env.services));
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text(AppInfo.name), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2700));
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(selectedTab(tester), 0);
    for (final label in ['Home', 'Clock', 'Day', 'Notes', 'Options']) {
      expect(tabLabel(label), findsOneWidget);
    }
  });

  testWidgets('Home shows the local clock and the world clocks', (
    tester,
  ) async {
    final env = await makeEnv();
    await pumpApp(tester, env);

    expect(find.text('CLOCKS'), findsOneWidget);
    expect(find.text('Local time'), findsOneWidget);
    expect(find.text('WORLD CLOCKS'), findsOneWidget);
    // The default cities.
    for (final city in ['New York', 'London', 'Tokyo', 'Sydney']) {
      expect(find.text(city), findsOneWidget, reason: city);
    }
    // The old tool cards are gone: the tab bar is how you reach the tools.
    expect(find.text('TOOLS'), findsNothing);
  });

  testWidgets('Home reflects the saved world clocks', (tester) async {
    final env = await makeEnv(prefs: {'world.cityIds': '["paris"]'});
    await pumpApp(tester, env);

    expect(find.text('Paris'), findsOneWidget);
    expect(find.text('Tokyo'), findsNothing);
  });

  testWidgets('Home shows the next alarm on the local clock', (tester) async {
    final env = await makeEnv();
    env.services.alarms.add(hour: 10, minute: 0);
    await pumpApp(tester, env);

    expect(find.textContaining('10:00 AM'), findsOneWidget);
    expect(find.textContaining('Today'), findsWidgets);
  });

  testWidgets('tapping a world clock on Home opens the Clock tab', (
    tester,
  ) async {
    final env = await makeEnv();
    await pumpApp(tester, env);

    await tester.tap(find.text('Tokyo'));
    await tester.pumpAndSettle();

    expect(find.byType(ClockScreen), findsOneWidget);
    expect(selectedTab(tester), 1);
  });

  testWidgets('tools are built lazily and the tab bar switches between them', (
    tester,
  ) async {
    final env = await makeEnv();
    await pumpApp(tester, env);

    // Nothing but Home has been built yet.
    expect(find.byType(ClockScreen), findsNothing);
    expect(find.byType(DayScreen), findsNothing);
    expect(find.byType(NotesScreen), findsNothing);
    expect(find.byType(SettingsScreen), findsNothing);

    const tabs = {
      'Clock': ClockScreen,
      'Day': DayScreen,
      'Notes': NotesScreen,
      'Options': SettingsScreen,
    };
    var expectedIndex = 1;
    for (final entry in tabs.entries) {
      await tester.tap(tabLabel(entry.key));
      await tester.pumpAndSettle();
      expect(find.byType(entry.value), findsOneWidget);
      expect(selectedTab(tester), expectedIndex++);
    }

    await tester.tap(tabLabel('Home'));
    await tester.pumpAndSettle();
    expect(selectedTab(tester), 0);
  });

  testWidgets('the tab that was left fades out completely', (tester) async {
    final env = await makeEnv();
    await pumpApp(tester, env);

    double opacityOf(Type screen) => tester
        .renderObject<RenderAnimatedOpacity>(
          find
              .ancestor(
                of: find.byType(screen),
                matching: find.byType(AnimatedOpacity),
              )
              .first,
        )
        .opacity
        .value;

    expect(opacityOf(HomeScreen), 1);

    await tester.tap(tabLabel('Clock'));
    await tester.pumpAndSettle();

    expect(opacityOf(HomeScreen), 0);
    expect(opacityOf(ClockScreen), 1);
  });

  testWidgets('back returns to Home before leaving the app', (tester) async {
    final env = await makeEnv();
    await pumpApp(tester, env);

    await tester.tap(tabLabel('Notes'));
    await tester.pumpAndSettle();
    expect(selectedTab(tester), 3);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(selectedTab(tester), 0);
  });

  group('click sounds', () {
    testWidgets('tapping a tab plays the tap sound', (tester) async {
      final env = await makeEnv();
      await pumpApp(tester, env);
      env.player.played.clear();

      await tester.tap(tabLabel('Day'));
      await tester.pumpAndSettle();

      expect(env.player.played, [Sfx.tap]);
    });

    testWidgets('tapping the tab you are already on is silent', (tester) async {
      final env = await makeEnv();
      await pumpApp(tester, env);
      env.player.played.clear();

      await tester.tap(tabLabel('Home'));
      await tester.pumpAndSettle();

      expect(env.player.played, isEmpty);
    });

    testWidgets('a card tap plays the tap sound', (tester) async {
      final env = await makeEnv();
      await pumpApp(tester, env);
      env.player.played.clear();

      await tester.tap(find.text('Tokyo'));
      await tester.pumpAndSettle();

      // One for the card, one for the tab switch it causes.
      expect(env.player.played, [Sfx.tap, Sfx.tap]);
    });

    testWidgets('nothing plays once sound effects are switched off', (
      tester,
    ) async {
      final env = await makeEnv(prefs: {'settings.soundEffects': false});
      await pumpApp(tester, env);

      await tester.tap(tabLabel('Day'));
      await tester.pumpAndSettle();
      await tester.tap(tabLabel('Home'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tokyo'));
      await tester.pumpAndSettle();

      expect(env.player.played, isEmpty);
    });
  });
}
