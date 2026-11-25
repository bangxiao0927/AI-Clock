import 'package:ai_clock_1/core/utils/date_time_format.dart';
import 'package:ai_clock_1/tools/clock/alarm/alarm.dart';
import 'package:ai_clock_1/tools/clock/world/city.dart';
import 'package:ai_clock_1/tools/clock/world/world_clock_controller.dart';
import 'package:ai_clock_1/tools/clock/world/world_time_labels.dart';
import 'package:ai_clock_1/tools/day/reminder.dart';
import 'package:ai_clock_1/tools/notes/note.dart';
import 'package:ai_clock_1/core/services/time_zones.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  group('Alarm', () {
    // 7 November 2026 is a Saturday.
    final saturdayMorning = DateTime(2026, 11, 7, 9, 0);

    test('a one-off alarm rings today if its time is still ahead', () {
      const alarm = Alarm(id: 1, hour: 10, minute: 30);
      expect(alarm.nextFire(saturdayMorning), DateTime(2026, 11, 7, 10, 30));
    });

    test('a one-off alarm whose time has passed rings tomorrow', () {
      const alarm = Alarm(id: 1, hour: 7, minute: 0);
      expect(alarm.nextFire(saturdayMorning), DateTime(2026, 11, 8, 7, 0));
    });

    test('an alarm at exactly the current time rings tomorrow, not now', () {
      const alarm = Alarm(id: 1, hour: 9, minute: 0);
      expect(alarm.nextFire(saturdayMorning), DateTime(2026, 11, 8, 9, 0));
    });

    test('a weekday alarm skips the weekend', () {
      const alarm = Alarm(id: 1, hour: 7, minute: 0, days: {1, 2, 3, 4, 5});
      expect(alarm.nextFire(saturdayMorning), DateTime(2026, 11, 9, 7, 0));
    });

    test('a switched-off alarm never rings', () {
      const alarm = Alarm(id: 1, hour: 10, minute: 0, enabled: false);
      expect(alarm.nextFire(saturdayMorning), isNull);
    });

    test(
      'nextOnWeekday finds that weekday even when today matches but passed',
      () {
        const alarm = Alarm(id: 1, hour: 7, minute: 0, days: {6});
        // Saturday 07:00 has passed, so the next Saturday is a week away.
        expect(
          alarm.nextOnWeekday(saturdayMorning, DateTime.saturday),
          DateTime(2026, 11, 14, 7, 0),
        );
      },
    );

    test('describes how it repeats', () {
      Alarm withDays(Set<int> days) =>
          Alarm(id: 1, hour: 7, minute: 0, days: days);
      expect(withDays({}).repeatSummary, 'Once');
      expect(withDays({1, 2, 3, 4, 5, 6, 7}).repeatSummary, 'Every day');
      expect(withDays({1, 2, 3, 4, 5}).repeatSummary, 'Weekdays');
      expect(withDays({6, 7}).repeatSummary, 'Weekends');
      expect(withDays({5, 1, 3}).repeatSummary, 'Mon, Wed, Fri');
    });

    test('survives a save and load', () {
      const alarm = Alarm(
        id: 4,
        hour: 6,
        minute: 45,
        label: 'Gym',
        days: {1, 3},
        enabled: false,
      );
      final restored = Alarm.fromJson(alarm.toJson())!;
      expect(restored.id, 4);
      expect(restored.hour, 6);
      expect(restored.minute, 45);
      expect(restored.label, 'Gym');
      expect(restored.days, {1, 3});
      expect(restored.enabled, isFalse);
    });

    test('rejects saved data that makes no sense', () {
      expect(Alarm.fromJson({'id': 1, 'hour': 25, 'minute': 0}), isNull);
      expect(Alarm.fromJson({'id': 'x', 'hour': 1, 'minute': 0}), isNull);
      expect(Alarm.fromJson({'hour': 1, 'minute': 0}), isNull);
    });
  });

  group('Reminder', () {
    test('has no alert time when it is an all-day item', () {
      final item = Reminder(
        id: 1,
        title: 'Pay rent',
        date: DateTime(2026, 11, 7),
      );
      expect(item.at, isNull);
    });

    test('computes its alert time from the date and minutes', () {
      final item = Reminder(
        id: 1,
        title: 'Call',
        date: DateTime(2026, 11, 7),
        minutes: 14 * 60 + 5,
      );
      expect(item.at, DateTime(2026, 11, 7, 14, 5));
    });

    test('copyWith can clear the time', () {
      final item = Reminder(
        id: 1,
        title: 'Call',
        date: DateTime(2026, 11, 7),
        minutes: 600,
      );
      expect(item.copyWith(minutes: null).minutes, isNull);
      expect(item.copyWith(title: 'Other').minutes, 600);
    });

    test('survives a save and load', () {
      final item = Reminder(
        id: 9,
        title: 'Dentist',
        date: DateTime(2026, 12, 1),
        minutes: 8 * 60 + 30,
        done: true,
      );
      final restored = Reminder.fromJson(item.toJson())!;
      expect(restored.id, 9);
      expect(restored.title, 'Dentist');
      expect(restored.date, DateTime(2026, 12, 1));
      expect(restored.minutes, 510);
      expect(restored.done, isTrue);
    });
  });

  group('Note', () {
    final now = DateTime(2026, 11, 7);

    Note note({String title = '', String body = ''}) =>
        Note(id: 1, title: title, body: body, createdAt: now, updatedAt: now);

    test('is empty only when both title and body are blank', () {
      expect(note().isEmpty, isTrue);
      expect(note(title: '  ', body: '\n').isEmpty, isTrue);
      expect(note(body: 'x').isEmpty, isFalse);
    });

    test('uses the first body line as the title when there is none', () {
      final n = note(body: '\nBuy milk\neggs and bread');
      expect(n.displayTitle, 'Buy milk');
      expect(n.snippet, 'eggs and bread');
    });

    test('keeps the whole body as the preview when it has a title', () {
      final n = note(title: 'Groceries', body: 'milk\neggs');
      expect(n.displayTitle, 'Groceries');
      expect(n.snippet, 'milk eggs');
    });

    test('is called Untitled when it has no text to borrow a title from', () {
      expect(note(title: '', body: '').displayTitle, 'Untitled');
    });

    test('survives a save and load', () {
      final n = note(title: 'T', body: 'B').copyWith(pinned: true);
      final restored = Note.fromJson(n.toJson())!;
      expect(restored.title, 'T');
      expect(restored.body, 'B');
      expect(restored.pinned, isTrue);
    });
  });

  group('World clock', () {
    setUpAll(ensureTimeZonesLoaded);

    test('every offered city has a valid, unique time zone entry', () {
      final ids = <String>{};
      for (final city in allCities) {
        expect(ids.add(city.id), isTrue, reason: 'duplicate id ${city.id}');
        expect(
          () => tz.getLocation(city.zone),
          returnsNormally,
          reason: '${city.name}: unknown zone ${city.zone}',
        );
      }
      expect(allCities.length, greaterThanOrEqualTo(30));
    });

    test('the default cities all exist', () {
      for (final id in defaultCityIds) {
        expect(cityById(id), isNotNull, reason: id);
      }
    });

    int hourIn(String id, DateTime utc) =>
        WorldClockController.timeIn(cityById(id)!, utc).hour;

    test('converts using each city\'s own offset', () {
      final noonUtc = DateTime.utc(2026, 1, 15, 12);
      expect(hourIn('tokyo', noonUtc), 21);
      expect(hourIn('mumbai', noonUtc), 17); // UTC+5:30
      expect(
        WorldClockController.timeIn(cityById('mumbai')!, noonUtc).minute,
        30,
      );
    });

    test('follows daylight saving time', () {
      final winter = DateTime.utc(2026, 1, 15, 12);
      final summer = DateTime.utc(2026, 7, 15, 12);
      expect(hourIn('london', winter), 12);
      expect(hourIn('london', summer), 13); // BST
      expect(hourIn('new_york', winter), 7);
      expect(hourIn('new_york', summer), 8); // EDT
      expect(hourIn('sydney', winter), 23); // AEDT, UTC+11 in January
      expect(hourIn('sydney', summer), 22); // AEST, UTC+10 in July
    });

    test('labels the offset between cities', () {
      expect(offsetLabel(Duration.zero), 'Same time');
      expect(offsetLabel(const Duration(hours: 1)), '+1 hr');
      expect(offsetLabel(const Duration(hours: 5)), '+5 hrs');
      expect(offsetLabel(const Duration(hours: -8)), '-8 hrs');
      expect(offsetLabel(const Duration(hours: 5, minutes: 30)), '+5:30 hrs');
    });

    test('a morning to evening sun icon rule', () {
      expect(isDaytime(DateTime(2026, 1, 1, 5, 59)), isFalse);
      expect(isDaytime(DateTime(2026, 1, 1, 6)), isTrue);
      expect(isDaytime(DateTime(2026, 1, 1, 17, 59)), isTrue);
      expect(isDaytime(DateTime(2026, 1, 1, 18)), isFalse);
    });
  });

  group('Formatting', () {
    test('stopwatch shows hundredths', () {
      expect(
        formatStopwatch(
          const Duration(minutes: 2, seconds: 3, milliseconds: 450),
        ),
        '02:03.45',
      );
      expect(formatStopwatch(Duration.zero), '00:00.00');
    });

    test('timer shows hours only when needed', () {
      expect(
        formatHms(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '1:02:03',
      );
      expect(formatHms(const Duration(minutes: 5)), '05:00');
    });

    test('clock times in 12 and 24 hour styles', () {
      expect(
        formatClockTime(DateTime(2026, 1, 1, 0, 5), use24Hour: false),
        '12:05 AM',
      );
      expect(
        formatClockTime(DateTime(2026, 1, 1, 13, 7), use24Hour: false),
        '1:07 PM',
      );
      expect(
        formatClockTime(DateTime(2026, 1, 1, 13, 7), use24Hour: true),
        '13:07',
      );
      expect(
        formatClockTime(DateTime(2026, 1, 1, 0, 5), use24Hour: true),
        '00:05',
      );
    });

    test('names days relative to today', () {
      final now = DateTime(2026, 11, 7, 23, 30);
      expect(relativeDayLabel(DateTime(2026, 11, 7, 1), now), 'Today');
      expect(relativeDayLabel(DateTime(2026, 11, 8, 1), now), 'Tomorrow');
      expect(relativeDayLabel(DateTime(2026, 11, 6, 23), now), 'Yesterday');
      expect(relativeDayLabel(DateTime(2026, 11, 12), now), 'Thu, 12 Nov');
    });

    test('greets by time of day', () {
      expect(greeting(DateTime(2026, 1, 1, 8)), 'Good morning');
      expect(greeting(DateTime(2026, 1, 1, 13)), 'Good afternoon');
      expect(greeting(DateTime(2026, 1, 1, 19)), 'Good evening');
      expect(greeting(DateTime(2026, 1, 1, 2)), 'Good night');
    });
  });
}
