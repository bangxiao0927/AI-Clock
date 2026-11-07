import 'package:ai_clock_1/app.dart';
import 'package:ai_clock_1/core/constants.dart';
import 'package:ai_clock_1/features/app_feature.dart';
import 'package:ai_clock_1/features/clock/clock_screen.dart';
import 'package:ai_clock_1/features/day/day_screen.dart';
import 'package:ai_clock_1/features/menu/main_menu_screen.dart';
import 'package:ai_clock_1/features/notes/notes_screen.dart';
import 'package:ai_clock_1/features/splash/splash_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app name is exactly "AI clock 1"', () {
    expect(AppInfo.name, 'AI clock 1');
  });

  testWidgets('splash screen leads to the main menu', (tester) async {
    await tester.pumpWidget(const AiClockApp());
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text(AppInfo.name), findsOneWidget);

    // Let the splash animation finish, then the cross-fade into the menu.
    await tester.pump(const Duration(milliseconds: 2700));
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(MainMenuScreen), findsOneWidget);
    for (final feature in AppFeature.values) {
      expect(find.text(feature.title), findsOneWidget);
    }
  });

  testWidgets('each menu card opens its own screen and returns', (
    tester,
  ) async {
    await tester.pumpWidget(const AiClockApp());
    await tester.pump(const Duration(milliseconds: 2700));
    await tester.pumpAndSettle();

    const screens = {
      AppFeature.clock: ClockScreen,
      AppFeature.day: DayScreen,
      AppFeature.notes: NotesScreen,
    };

    for (final entry in screens.entries) {
      await tester.tap(find.text(entry.key.title));
      await tester.pumpAndSettle();
      expect(find.byType(entry.value), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(MainMenuScreen), findsOneWidget);
    }
  });
}
