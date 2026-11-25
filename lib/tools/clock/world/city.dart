import 'package:flutter/foundation.dart';

/// A city shown on the world clock. [zone] is an IANA time-zone name, which is
/// what the time-zone database understands (it knows each city's daylight
/// saving rules).
@immutable
class City {
  const City(this.id, this.name, this.country, this.zone);

  /// Stable identifier, saved with the user's list.
  final String id;
  final String name;
  final String country;
  final String zone;

  @override
  bool operator ==(Object other) => other is City && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// The cities the user can pick from, spread across the world's time zones.
const allCities = <City>[
  City('honolulu', 'Honolulu', 'United States', 'Pacific/Honolulu'),
  City('anchorage', 'Anchorage', 'United States', 'America/Anchorage'),
  City('los_angeles', 'Los Angeles', 'United States', 'America/Los_Angeles'),
  City('vancouver', 'Vancouver', 'Canada', 'America/Vancouver'),
  City('phoenix', 'Phoenix', 'United States', 'America/Phoenix'),
  City('denver', 'Denver', 'United States', 'America/Denver'),
  City('mexico_city', 'Mexico City', 'Mexico', 'America/Mexico_City'),
  City('chicago', 'Chicago', 'United States', 'America/Chicago'),
  City('new_york', 'New York', 'United States', 'America/New_York'),
  City('toronto', 'Toronto', 'Canada', 'America/Toronto'),
  City('bogota', 'Bogotá', 'Colombia', 'America/Bogota'),
  City('sao_paulo', 'São Paulo', 'Brazil', 'America/Sao_Paulo'),
  City(
    'buenos_aires',
    'Buenos Aires',
    'Argentina',
    'America/Argentina/Buenos_Aires',
  ),
  City('reykjavik', 'Reykjavík', 'Iceland', 'Atlantic/Reykjavik'),
  City('london', 'London', 'United Kingdom', 'Europe/London'),
  City('dublin', 'Dublin', 'Ireland', 'Europe/Dublin'),
  City('lisbon', 'Lisbon', 'Portugal', 'Europe/Lisbon'),
  City('lagos', 'Lagos', 'Nigeria', 'Africa/Lagos'),
  City('paris', 'Paris', 'France', 'Europe/Paris'),
  City('berlin', 'Berlin', 'Germany', 'Europe/Berlin'),
  City('madrid', 'Madrid', 'Spain', 'Europe/Madrid'),
  City('rome', 'Rome', 'Italy', 'Europe/Rome'),
  City('amsterdam', 'Amsterdam', 'Netherlands', 'Europe/Amsterdam'),
  City('stockholm', 'Stockholm', 'Sweden', 'Europe/Stockholm'),
  City('athens', 'Athens', 'Greece', 'Europe/Athens'),
  City('helsinki', 'Helsinki', 'Finland', 'Europe/Helsinki'),
  City('johannesburg', 'Johannesburg', 'South Africa', 'Africa/Johannesburg'),
  City('istanbul', 'Istanbul', 'Türkiye', 'Europe/Istanbul'),
  City('moscow', 'Moscow', 'Russia', 'Europe/Moscow'),
  City('nairobi', 'Nairobi', 'Kenya', 'Africa/Nairobi'),
  City('riyadh', 'Riyadh', 'Saudi Arabia', 'Asia/Riyadh'),
  City('dubai', 'Dubai', 'United Arab Emirates', 'Asia/Dubai'),
  City('mumbai', 'Mumbai', 'India', 'Asia/Kolkata'),
  City('bangkok', 'Bangkok', 'Thailand', 'Asia/Bangkok'),
  City('jakarta', 'Jakarta', 'Indonesia', 'Asia/Jakarta'),
  City('singapore', 'Singapore', 'Singapore', 'Asia/Singapore'),
  City('hong_kong', 'Hong Kong', 'China', 'Asia/Hong_Kong'),
  City('shanghai', 'Shanghai', 'China', 'Asia/Shanghai'),
  City('seoul', 'Seoul', 'South Korea', 'Asia/Seoul'),
  City('tokyo', 'Tokyo', 'Japan', 'Asia/Tokyo'),
  City('sydney', 'Sydney', 'Australia', 'Australia/Sydney'),
  City('melbourne', 'Melbourne', 'Australia', 'Australia/Melbourne'),
  City('auckland', 'Auckland', 'New Zealand', 'Pacific/Auckland'),
];

/// Looks a city up by its saved [id], or null if it is no longer offered.
City? cityById(String id) {
  for (final city in allCities) {
    if (city.id == id) return city;
  }
  return null;
}

/// The cities on the world clock the first time the app runs.
const defaultCityIds = ['new_york', 'london', 'tokyo', 'sydney'];
