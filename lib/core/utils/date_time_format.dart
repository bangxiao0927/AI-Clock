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

/// "Good morning", "Good afternoon", ...
String greeting(DateTime time) {
  final hour = time.hour;
  if (hour >= 5 && hour < 12) return 'Good morning';
  if (hour >= 12 && hour < 17) return 'Good afternoon';
  if (hour >= 17 && hour < 22) return 'Good evening';
  return 'Good night';
}
