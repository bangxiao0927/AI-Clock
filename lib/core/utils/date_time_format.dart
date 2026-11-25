// Tiny English-only date/time helpers, so the app needs no extra packages.

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String twoDigits(int value) => value.toString().padLeft(2, '0');

String weekdayName(DateTime date) => _weekdays[date.weekday - 1];

/// "7 November 2026"
String formatDayMonthYear(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';

/// "Saturday, 7 November 2026"
String formatFullDate(DateTime date) =>
    '${weekdayName(date)}, ${formatDayMonthYear(date)}';

/// Hours and minutes, following the device's 12/24-hour preference.
String formatHoursMinutes(DateTime time, {required bool use24Hour}) {
  if (use24Hour) return '${twoDigits(time.hour)}:${twoDigits(time.minute)}';
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  return '$hour:${twoDigits(time.minute)}';
}

String meridiem(DateTime time) => time.hour < 12 ? 'AM' : 'PM';

/// "7:05 AM" or "07:05".
String formatClockTime(DateTime time, {required bool use24Hour}) {
  final hoursMinutes = formatHoursMinutes(time, use24Hour: use24Hour);
  return use24Hour ? hoursMinutes : '$hoursMinutes ${meridiem(time)}';
}

/// "1:02:03" for an hour or more, otherwise "02:03".
String formatHms(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  final seconds = duration.inSeconds % 60;
  return hours > 0
      ? '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}'
      : '${twoDigits(minutes)}:${twoDigits(seconds)}';
}

/// "02:03.45": minutes, seconds and hundredths, for the stopwatch.
String formatStopwatch(Duration duration) {
  final centiseconds = (duration.inMilliseconds % 1000) ~/ 10;
  return '${twoDigits(duration.inMinutes)}:'
      '${twoDigits(duration.inSeconds % 60)}.${twoDigits(centiseconds)}';
}

const _shortWeekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// "Mon" for [weekday] 1 (Monday) to 7 (Sunday).
String shortWeekday(int weekday) => _shortWeekdays[weekday - 1];

/// [date] without its time of day.
DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// "Today", "Tomorrow", "Yesterday", or the weekday and date.
String relativeDayLabel(DateTime date, DateTime now) {
  // Compare as UTC dates so a daylight-saving day (23 or 25 hours) still
  // counts as exactly one day.
  final difference = DateTime.utc(
    date.year,
    date.month,
    date.day,
  ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
  return switch (difference) {
    0 => 'Today',
    1 => 'Tomorrow',
    -1 => 'Yesterday',
    _ =>
      '${shortWeekday(date.weekday)}, ${date.day} ${_months[date.month - 1].substring(0, 3)}',
  };
}

/// "Good morning", "Good afternoon", ...
String greeting(DateTime time) {
  final hour = time.hour;
  if (hour >= 5 && hour < 12) return 'Good morning';
  if (hour >= 12 && hour < 17) return 'Good afternoon';
  if (hour >= 17 && hour < 22) return 'Good evening';
  return 'Good night';
}
