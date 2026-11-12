import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;

import '../models/stay.dart';

class DailyForecast extends Equatable {
  const DailyForecast({
    required this.date,
    required this.code,
    required this.high,
    required this.low,
    required this.rainChance,
    required this.windMph,
  });

  final DateTime date;
  final int code;
  final int high;
  final int low;
  final int rainChance;
  final int windMph;

  static const _days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  String get dayLabel => '${_days[date.weekday - 1]} ${date.day}';

  /// WMO weather code as a short label.
  String get summary => switch (code) {
    0 => 'Sunny',
    1 || 2 => 'Partly sunny',
    3 => 'Cloudy',
    45 || 48 => 'Fog',
    51 || 53 || 55 || 56 || 57 => 'Drizzle',
    61 || 63 || 65 || 66 || 67 || 80 || 81 || 82 => 'Rain',
    71 || 73 || 75 || 77 || 85 || 86 => 'Snow',
    95 || 96 || 99 => 'Thunderstorms',
    _ => 'Mixed',
  };

  @override
  List<Object?> get props => [date, code, high, low, rainChance, windMph];
}

class Forecast {
  const Forecast({required this.days, required this.forTrip});

  final List<DailyForecast> days;

  /// False when the trip is beyond the 16-day forecast window and the
  /// next days are shown instead.
  final bool forTrip;

  int get high => days.map((d) => d.high).reduce((a, b) => a > b ? a : b);
  int get low => days.map((d) => d.low).reduce((a, b) => a < b ? a : b);
  int get maxRain =>
      days.map((d) => d.rainChance).reduce((a, b) => a > b ? a : b);
  int get maxWind => days.map((d) => d.windMph).reduce((a, b) => a > b ? a : b);

  String get packingTip {
    if (maxRain >= 50) return 'Rain is likely. Pack a rain fly and dry layers.';
    if (low <= 40) return 'Cold nights ahead. Bring a warm sleeping bag.';
    if (maxWind >= 20) return 'Windy at times. Stake your tent well.';
    return 'Nights near $low°F. Bring warm layers.';
  }
}

/// Live daily forecast from Open-Meteo (no API key).
class WeatherRepository {
  WeatherRepository({http.Client? client, DateTime Function()? clock})
    : _client = client ?? http.Client(),
      _clock = clock ?? DateTime.now;

  final http.Client _client;
  final DateTime Function() _clock;
  final _cache = <String, Forecast>{};

  static const forecastDays = 16;

  Future<Forecast> forecast(
    double latitude,
    double longitude, {
    Stay? stay,
  }) async {
    final today = dateOnly(_clock());
    final lastDay = today.add(const Duration(days: forecastDays - 1));
    var start = today;
    var end = today.add(const Duration(days: 2));
    var forTrip = false;
    if (stay != null &&
        !stay.checkIn.isBefore(today) &&
        !stay.checkIn.isAfter(lastDay)) {
      start = stay.checkIn;
      end = stay.checkOut.isAfter(lastDay) ? lastDay : stay.checkOut;
      forTrip = true;
    }
    final key = '$latitude,$longitude,${isoDate(start)},${isoDate(end)}';
    final cached = _cache[key];
    if (cached != null) return cached;

    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '$latitude',
      'longitude': '$longitude',
      'daily':
          'weather_code,temperature_2m_max,temperature_2m_min,'
          'precipitation_probability_max,wind_speed_10m_max',
      'temperature_unit': 'fahrenheit',
      'wind_speed_unit': 'mph',
      'timezone': 'auto',
      'start_date': isoDate(start),
      'end_date': isoDate(end),
    });
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw StateError('Forecast unavailable (${response.statusCode})');
    }
    final daily =
        (jsonDecode(response.body) as Map<String, dynamic>)['daily']
            as Map<String, dynamic>;
    List<num?> column(String name) =>
        (daily[name] as List).map((v) => v as num?).toList();
    final dates = (daily['time'] as List).cast<String>();
    final codes = column('weather_code');
    final highs = column('temperature_2m_max');
    final lows = column('temperature_2m_min');
    final rain = column('precipitation_probability_max');
    final wind = column('wind_speed_10m_max');
    final days = [
      for (var i = 0; i < dates.length; i++)
        DailyForecast(
          date: DateTime.parse(dates[i]),
          code: (codes[i] ?? -1).toInt(),
          high: (highs[i] ?? 0).round(),
          low: (lows[i] ?? 0).round(),
          rainChance: (rain[i] ?? 0).round(),
          windMph: (wind[i] ?? 0).round(),
        ),
    ];
    if (days.isEmpty) throw StateError('Forecast unavailable');
    final forecast = Forecast(days: days, forTrip: forTrip);
    _cache[key] = forecast;
    return forecast;
  }
}
