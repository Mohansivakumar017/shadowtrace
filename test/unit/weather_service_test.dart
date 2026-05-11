import 'package:flutter_test/flutter_test.dart';
import 'package:shadowtrace/services/weather_service.dart';
import 'package:shadowtrace/config/app_config.dart';

void main() {
  group('WeatherService', () {
    late WeatherService weatherService;

    setUp(() {
      weatherService = WeatherService();
    });

    test('getCurrentWeather calls correct endpoint', () {
      expect(AppConfig.weatherDataEndpoint,
          contains('bt0afo9upa.execute-api.us-east-1.amazonaws.com'));
      expect(AppConfig.weatherDataEndpoint, contains('wheatherdataget'));
    });

    test('getRouteForecast calls correct endpoint', () {
      expect(AppConfig.weatherForecastEndpoint,
          contains('bt0afo9upa.execute-api.us-east-1.amazonaws.com'));
      expect(AppConfig.weatherForecastEndpoint,
          contains('wheatherforecasting'));
    });

    test('isHazardous returns true for Thunderstorm', () {
      final data = {'condition': 'Thunderstorm', 'temperature': 25};
      expect(weatherService.isHazardous(data), true);
    });

    test('isHazardous returns true for Snow', () {
      final data = {'condition': 'Snow', 'temperature': -5};
      expect(weatherService.isHazardous(data), true);
    });

    test('isHazardous returns true for Tornado', () {
      final data = {'condition': 'Tornado', 'temperature': 20};
      expect(weatherService.isHazardous(data), true);
    });

    test('isHazardous returns false for Clear', () {
      final data = {'condition': 'Clear', 'temperature': 28};
      expect(weatherService.isHazardous(data), false);
    });

    test('isHazardous handles null condition', () {
      final data = {'temperature': 25};
      expect(weatherService.isHazardous(data), false);
    });
  });
}
