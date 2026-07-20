// Shared @Named tag between RegisterModule and AircraftSignalRDataSource — avoids a duplicated string literal.
const hubUrlToken = 'hubUrl';

class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5273',
  );

  static const String aircraftPath = '/aircraft';
  static const String liveIntervalPath = '/aircraft/live-interval';
  static const String laMinParam = 'lamin';
  static const String loMinParam = 'lomin';
  static const String laMaxParam = 'lamax';
  static const String loMaxParam = 'lomax';

  static String get hubUrl => '$baseUrl/hubs/aircraft';
  static String aircraftDetailPath(String icao24) => '$aircraftPath/$icao24';
}
