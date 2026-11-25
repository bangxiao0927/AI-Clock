import 'package:ai_clock_1/core/services/sound_service.dart';
import 'package:ai_clock_1/core/utils/date_time_format.dart';
import 'package:ai_clock_1/core/widgets/glass_tab_bar.dart';
import 'package:ai_clock_1/tools/day/day_screen.dart';
import 'package:ai_clock_1/tools/notes/note_editor_screen.dart';
import 'package:ai_clock_1/tools/notes/notes_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_app.dart';

Finder tabLabel(String label) =>
    find.descendant(of: find.byType(GlassTabBar), matching: find.text(label));

Finder inDay(Finder matching) =>
    find.descendant(of: find.byType(DayScreen), matching: matching);

Finder inNotes(Finder matching) =>
    find.descendant(of: find.byType(NotesScreen), matching: matching);

/// The Day screen shows the real date, so tests use it too.
DateTime get today => dateOnly(DateTime.now());

Future<void> openTab(WidgetTester tester, TestEnv env, String label) async {
  await pumpApp(tester, env);
  await tester.tap(tabLabel(label));
  await tester.pumpAndSettle();
}

/// Scrolls [screen]'s list until [finder] is on screen and lets it settle.
Future<void> scrollTo(WidgetTester tester, Type screen, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find
        .descendant(of: find.byType(screen), matching: find.byType(Scrollable))
        .first,
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Day', () {
    Future<void> openAddSheet(WidgetTester tester) async {
      await scrollTo(tester, DayScreen, find.text('Add to this day'));
      await tester.tap(find.text('Add to this day'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows progress, the day strip and an empty plan', (
      tester,
    ) async {
      final env = await makeEnv();
      await openTab(tester, env, 'Day');

      expect(find.text('Day progress'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.textContaining('Nothing planned'), findsOneWidget);
      expect(find.text('Add to this day'), findsOneWidget);
    });

    testWidgets('adds an all-day to-do', (tester) async {
      final env = await makeEnv();
      await openTab(tester, env, 'Day');

      await openAddSheet(tester);
      await tester.enterText(find.byType(TextField), 'Buy milk');
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final item = env.services.reminders.forDay(today).single;
      expect(item.title, 'Buy milk');
      expect(item.minutes, isNull);
      expect(inDay(find.text('Buy milk')), findsOneWidget);
      expect(inDay(find.text('All day')), findsOneWidget);
      expect(find.text('1 to do'), findsOneWidget);
      expect(find.textContaining('Nothing planned'), findsNothing);
      expect(env.player.played, contains(Sfx.confirm));
    });

    testWidgets('Save stays off until there is a title', (tester) async {
      final env = await makeEnv();
      await openTab(tester, env, 'Day');
      await openAddSheet(tester);

      FilledButton save() => tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save'),
      );
      expect(save().onPressed, isNull);

      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();
      expect(save().onPressed, isNull); // Blank does not count.

      await tester.enterText(find.byType(TextField), 'Call mum');
      await tester.pump();
      expect(save().onPressed, isNotNull);
    });

    testWidgets('adds a reminder with a time', (tester) async {
      final env = await makeEnv();
      await openTab(tester, env, 'Day');
      await openAddSheet(tester);

      await tester.enterText(find.byType(TextField), 'Stand-up');
      await tester.tap(find.text('Remind me at a time'));
      await tester.pumpAndSettle();
      expect(find.text('9:00 AM'), findsOneWidget); // The default time.

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final item = env.services.reminders.forDay(today).single;
      expect(item.minutes, 9 * 60);
      expect(inDay(find.text('9:00 AM')), findsOneWidget);
      expect(inDay(find.text('All day')), findsNothing);
    });

    testWidgets('ticking an item off marks it done', (tester) async {
      final handle = tester.ensureSemantics();
      final env = await makeEnv();
      env.services.reminders.add(title: 'Buy milk', date: today);
      await openTab(tester, env, 'Day');
      expect(find.text('1 to do'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Mark Buy milk done'));
      await tester.pumpAndSettle();

      expect(env.services.reminders.forDay(today).single.done, isTrue);
      expect(find.text('All done'), findsOneWidget);
      expect(env.player.played, contains(Sfx.toggleOn));
      handle.dispose();
    });

    testWidgets('tapping an item edits it, and it can be deleted', (
      tester,
    ) async {
      final env = await makeEnv();
      env.services.reminders.add(title: 'Dentist', date: today);
      await openTab(tester, env, 'Day');

      await tester.tap(inDay(find.text('Dentist')));
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, 'Dentist');

      await tester.enterText(find.byType(TextField), 'Dentist at 4');
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(env.services.reminders.forDay(today).single.title, 'Dentist at 4');

      await tester.tap(inDay(find.text('Dentist at 4')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Delete reminder'));
      await tester.pumpAndSettle();
      expect(env.services.reminders.forDay(today), isEmpty);
    });

    testWidgets('swiping an item away can be undone', (tester) async {
      final env = await makeEnv();
      env.services.reminders.add(title: 'Dentist', date: today);
      await openTab(tester, env, 'Day');

      await tester.drag(inDay(find.text('Dentist')), const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(env.services.reminders.forDay(today), isEmpty);
      expect(find.text('Deleted "Dentist"'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(env.services.reminders.forDay(today), hasLength(1));
    });

    testWidgets('the day strip switches to another day\'s plan', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final env = await makeEnv();
      final tomorrow = today.add(const Duration(days: 1));
      env.services.reminders.add(title: 'Team lunch', date: tomorrow);
      await openTab(tester, env, 'Day');
      expect(inDay(find.text('Team lunch')), findsNothing);

      await tester.tap(
        find.bySemanticsLabel(
          '${weekdayName(tomorrow)} ${formatDayMonthYear(tomorrow)}',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tomorrow'), findsOneWidget);
      expect(inDay(find.text('Team lunch')), findsOneWidget);
      handle.dispose();
    });
  });

  group('Notes', () {
    Future<void> typeNote(
      WidgetTester tester, {
      String title = '',
      String body = '',
    }) async {
      final fields = find.byType(TextField);
      if (title.isNotEmpty) await tester.enterText(fields.at(0), title);
      if (body.isNotEmpty) await tester.enterText(fields.at(1), body);
    }

    testWidgets('starts empty with a New note button', (tester) async {
      final env = await makeEnv();
      await openTab(tester, env, 'Notes');

      expect(find.text('No notes yet'), findsOneWidget);
      expect(find.text('New note'), findsOneWidget);
    });

    testWidgets('a new note is saved when you leave the editor', (
      tester,
    ) async {
      final env = await makeEnv();
      await openTab(tester, env, 'Notes');

      await tester.tap(find.text('New note'));
      await tester.pumpAndSettle();
      expect(find.byType(NoteEditorScreen), findsOneWidget);

      await typeNote(tester, title: 'Groceries', body: 'milk and eggs');
      await tester.pageBack();
      await tester.pumpAndSettle();

      final note = env.services.notes.notes.single;
      expect(note.title, 'Groceries');
      expect(note.body, 'milk and eggs');
      expect(find.text('No notes yet'), findsNothing);
      expect(inNotes(find.text('Groceries')), findsOneWidget);
      expect(inNotes(find.text('milk and eggs')), findsOneWidget);
    });

    testWidgets('it saves by itself shortly after typing', (tester) async {
      final env = await makeEnv();
      await openTab(tester, env, 'Notes');
      await tester.tap(find.text('New note'));
      await tester.pumpAndSettle();

      await typeNote(tester, body: 'Remember this');
      expect(env.services.notes.notes, isEmpty); // Not yet.
      await tester.pump(const Duration(milliseconds: 500));
      expect(env.services.notes.notes.single.body, 'Remember this');
    });

    testWidgets('an empty note is not kept', (tester) async {
      final env = await makeEnv();
      await openTab(tester, env, 'Notes');

      await tester.tap(find.text('New note'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(env.services.notes.notes, isEmpty);
      expect(find.text('No notes yet'), findsOneWidget);
    });

    testWidgets('opening a note shows its text, and edits are saved', (
      tester,
    ) async {
      final env = await makeEnv();
      final notes = env.services.notes;
      notes.save(notes.createDraft().copyWith(title: 'Plan', body: 'Draft'));
      await openTab(tester, env, 'Notes');

      await tester.tap(inNotes(find.text('Plan')));
      await tester.pumpAndSettle();
      final fields = find.byType(TextField);
      expect(tester.widget<TextField>(fields.at(0)).controller!.text, 'Plan');
      expect(tester.widget<TextField>(fields.at(1)).controller!.text, 'Draft');

      await tester.enterText(fields.at(1), 'Final version');
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(notes.notes.single.body, 'Final version');
      expect(notes.notes, hasLength(1)); // Edited, not duplicated.
    });

    testWidgets('pinning a note is saved and shown', (tester) async {
      final env = await makeEnv();
      final notes = env.services.notes;
      notes.save(notes.createDraft().copyWith(title: 'Important'));
      await openTab(tester, env, 'Notes');
      expect(inNotes(find.byIcon(Icons.push_pin_rounded)), findsNothing);

      await tester.tap(inNotes(find.text('Important')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Pin note'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Unpin note'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(notes.notes.single.pinned, isTrue);
      expect(inNotes(find.byIcon(Icons.push_pin_rounded)), findsOneWidget);
    });

    testWidgets('deleting from the editor can be undone', (tester) async {
      final env = await makeEnv();
      final notes = env.services.notes;
      notes.save(notes.createDraft().copyWith(title: 'Temporary'));
      await openTab(tester, env, 'Notes');

      await tester.tap(inNotes(find.text('Temporary')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Delete note'));
      await tester.pumpAndSettle();

      expect(find.byType(NoteEditorScreen), findsNothing);
      expect(notes.notes, isEmpty); // Deleting must not be undone by closing.
      expect(find.text('Note deleted'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(notes.notes.single.title, 'Temporary');
    });

    testWidgets('swiping a note away can be undone', (tester) async {
      final env = await makeEnv();
      final notes = env.services.notes;
      notes.save(notes.createDraft().copyWith(title: 'Old news'));
      await openTab(tester, env, 'Notes');

      await tester.drag(inNotes(find.text('Old news')), const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(notes.notes, isEmpty);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(notes.notes, hasLength(1));
    });

    testWidgets('search filters the list', (tester) async {
      final env = await makeEnv();
      final notes = env.services.notes;
      notes.save(
        notes.createDraft().copyWith(title: 'Groceries', body: 'milk'),
      );
      notes.save(
        notes.createDraft().copyWith(title: 'Work', body: 'Send the report'),
      );
      await openTab(tester, env, 'Notes');
      expect(inNotes(find.text('Groceries')), findsOneWidget);
      expect(inNotes(find.text('Work')), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'REPORT');
      await tester.pumpAndSettle();
      expect(inNotes(find.text('Work')), findsOneWidget);
      expect(inNotes(find.text('Groceries')), findsNothing);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.textContaining('No notes match'), findsOneWidget);

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(inNotes(find.text('Groceries')), findsOneWidget);
      expect(inNotes(find.text('Work')), findsOneWidget);
    });

    testWidgets('notes come back after the app is closed and reopened', (
      tester,
    ) async {
      final first = await makeEnv();
      first.services.notes.save(
        first.services.notes.createDraft().copyWith(title: 'Kept'),
      );
      first.services.reminders.add(title: 'Also kept', date: today);

      // The next launch finds exactly what was saved on disk.
      final second = await makeEnv(
        prefs: {
          for (final key in ['notes.v1', 'reminders.v1'])
            if (first.storage.getString(key) != null)
              key: first.storage.getString(key)!,
        },
      );
      await openTab(tester, second, 'Notes');
      expect(inNotes(find.text('Kept')), findsOneWidget);

      await tester.tap(tabLabel('Day'));
      await tester.pumpAndSettle();
      expect(inDay(find.text('Also kept')), findsOneWidget);
    });
  });
}
