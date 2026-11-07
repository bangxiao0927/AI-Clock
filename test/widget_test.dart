import 'package:ai_clock_1/app/app.dart';
import 'package:ai_clock_1/app/app_shell.dart';
import 'package:ai_clock_1/core/constants.dart';
import 'package:ai_clock_1/core/widgets/glass_tab_bar.dart';
import 'package:ai_clock_1/features/home/home_screen.dart';
import 'package:ai_clock_1/features/splash/splash_screen.dart';
import 'package:ai_clock_1/tools/clock/clock_screen.dart';
import 'package:ai_clock_1/tools/day/day_screen.dart';
import 'package:ai_clock_1/tools/notes/notes_screen.dart';
import 'package:ai_clock_1/tools/tool_registry.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps the app on a phone-sized screen and waits out the splash screen.
Future<void> pumpAppPastSplash(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const AiClockApp());
  await tester.pump(const Duration(milliseconds: 2700));
  await tester.pumpAndSettle();
}

/// A label inside the glass tab bar (Home also shows the tool names).
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
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const AiClockApp());
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text(AppInfo.name), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2700));
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(selectedTab(tester), 0);
    for (final label in ['Home', 'Clock', 'Day', 'Notes']) {
      expect(tabLabel(label), findsOneWidget);
    }
  });

  testWidgets('tools are built lazily and the tab bar switches between them', (
    tester,
  ) async {
    await pumpAppPastSplash(tester);

    // Nothing but Home has been built yet.
    expect(find.byType(ClockScreen), findsNothing);
    expect(find.byType(DayScreen), findsNothing);
    expect(find.byType(NotesScreen), findsNothing);

    const tabs = {'Clock': ClockScreen, 'Day': DayScreen, 'Notes': NotesScreen};
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
    await pumpAppPastSplash(tester);

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

  testWidgets('a Home card opens that tool\'s tab', (tester) async {
    await pumpAppPastSplash(tester);

    await tester.tap(
      find.descendant(of: find.byType(HomeScreen), matching: find.text('Day')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DayScreen), findsOneWidget);
    expect(selectedTab(tester), 2);
  });

  testWidgets('back returns to Home before leaving the app', (tester) async {
    await pumpAppPastSplash(tester);

    await tester.tap(tabLabel('Notes'));
    await tester.pumpAndSettle();
    expect(selectedTab(tester), 3);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(selectedTab(tester), 0);
  });
}
