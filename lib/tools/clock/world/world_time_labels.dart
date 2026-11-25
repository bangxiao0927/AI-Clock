import '../../../core/utils/date_time_format.dart';

/// Whether the sun is up at [time] (a rough 6 am to 6 pm), for the sun/moon
/// icon on a city's clock.
bool isDaytime(DateTime time) => time.hour >= 6 && time.hour < 18;

/// "+5 hrs", "-8 hrs", "+5:30 hrs" or "Same time": how far a city's clock is
/// from the device's clock.
String offsetLabel(Duration offset) {
  if (offset == Duration.zero) return 'Same time';
  final sign = offset.isNegative ? '-' : '+';
  final abs = offset.abs();
  final hours = abs.inHours;
  final minutes = abs.inMinutes % 60;
  if (minutes != 0) return '$sign$hours:${twoDigits(minutes)} hrs';
  return '$sign$hours ${hours == 1 ? 'hr' : 'hrs'}';
}
