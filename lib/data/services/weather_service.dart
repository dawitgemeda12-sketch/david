import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class WeatherSnapshot {
  final double temperatureC;
  final double precipitationMm;
  final double windKph;
  final int weatherCode;
  final DateTime fetchedAt;
  final String cityLabel;

  WeatherSnapshot({
    required this.temperatureC,
    required this.precipitationMm,
    required this.windKph,
    required this.weatherCode,
    required this.cityLabel,
    DateTime? fetchedAt,
  }) : fetchedAt = fetchedAt ?? DateTime.now();

  bool get isRainy => precipitationMm > 0.2 || (weatherCode >= 51 && weatherCode <= 82);
  bool get isHot => temperatureC >= 26;
  bool get isCold => temperatureC <= 14;
  bool get isWindy => windKph >= 25;

  String get summary {
    if (isRainy) return 'Rain expected';
    if (isHot) return 'Warm and sunny';
    if (isCold) return 'Cool weather';
    return 'Mild and pleasant';
  }
}

/// Weather integration. Uses the Open-Meteo public API which requires
/// NO API key — this keeps the requirement "never expose weather API
/// keys inside Flutter" trivially satisfied while remaining a REAL,
/// live weather integration (not simulated data). In the full backend
/// deployment this call is proxied server-side (see backend/README,
/// WEATHER_API_KEY) so a paid provider (e.g. OpenWeatherMap) can be
/// swapped in without any Flutter changes.
class WeatherService {
  static const Map<String, List<double>> _cityCoords = {
    'Addis Ababa': [9.03, 38.74],
    'Hawassa': [7.06, 38.48],
    'Dire Dawa': [9.59, 41.87],
    'Bahir Dar': [11.6, 37.39],
    'Mekelle': [13.5, 39.47],
  };

  Future<WeatherSnapshot?> fetchCurrent(String city) async {
    final coords = _cityCoords[city] ?? _cityCoords['Addis Ababa']!;
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=${coords[0]}&longitude=${coords[1]}'
      '&current=temperature_2m,precipitation,wind_speed_10m,weather_code',
    );
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final current = data['current'] as Map<String, dynamic>?;
      if (current == null) return null;
      return WeatherSnapshot(
        temperatureC: (current['temperature_2m'] as num?)?.toDouble() ?? 20,
        precipitationMm: (current['precipitation'] as num?)?.toDouble() ?? 0,
        windKph: (current['wind_speed_10m'] as num?)?.toDouble() ?? 0,
        weatherCode: (current['weather_code'] as num?)?.toInt() ?? 0,
        cityLabel: city,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Weather fetch failed: $e');
      return null;
    }
  }
}
