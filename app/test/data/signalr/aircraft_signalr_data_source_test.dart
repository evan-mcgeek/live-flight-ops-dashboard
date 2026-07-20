import 'package:flight_ops_app/data/signalr/aircraft_signalr_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseAircraftUpdateArguments', () {
    test('parses the AircraftUpdate payload into an AircraftSnapshot', () {
      final arguments = <Object?>[
        {
          'aircraft': [
            {
              'icao24': 'abc123',
              'callsign': 'TEST1',
              'originCountry': 'Testland',
              'longitude': 1.0,
              'latitude': 2.0,
              'altitude': 3.0,
              'velocity': 4.0,
              'heading': 5.0,
              'onGround': false,
              'lastUpdate': '2026-01-01T12:00:00Z',
            },
          ],
          'stale': false,
        },
      ];

      final snapshot = parseAircraftUpdateArguments(arguments);

      expect(snapshot.aircraft, hasLength(1));
      expect(snapshot.aircraft.first.icao24, 'abc123');
      expect(snapshot.stale, false);
    });

    test('throws FormatException when arguments are null or empty', () {
      expect(() => parseAircraftUpdateArguments(null), throwsFormatException);
      expect(
        () => parseAircraftUpdateArguments(<Object?>[]),
        throwsFormatException,
      );
    });
  });
}
