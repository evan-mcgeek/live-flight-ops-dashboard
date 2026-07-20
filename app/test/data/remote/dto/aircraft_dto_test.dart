import 'package:flight_ops_app/data/remote/dto/aircraft_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AircraftDto', () {
    test('fromJson + toDomain maps a fully populated aircraft JSON object', () {
      final json = {
        'icao24': 'abc123',
        'callsign': 'TEST1',
        'originCountry': 'Testland',
        'longitude': 1.5,
        'latitude': 2.5,
        'altitude': 3500.0,
        'velocity': 200.0,
        'heading': 90.0,
        'onGround': false,
        'lastUpdate': '2026-01-01T12:00:00Z',
      };

      final aircraft = AircraftDto.fromJson(json).toDomain();

      expect(aircraft.icao24, 'abc123');
      expect(aircraft.callsign, 'TEST1');
      expect(aircraft.originCountry, 'Testland');
      expect(aircraft.longitude, 1.5);
      expect(aircraft.latitude, 2.5);
      expect(aircraft.altitude, 3500.0);
      expect(aircraft.velocity, 200.0);
      expect(aircraft.heading, 90.0);
      expect(aircraft.onGround, false);
      expect(aircraft.lastUpdate, DateTime.parse('2026-01-01T12:00:00Z'));
    });

    test('fromJson + toDomain maps null nullable fields', () {
      final json = {
        'icao24': 'abc123',
        'callsign': null,
        'originCountry': 'Testland',
        'longitude': null,
        'latitude': null,
        'altitude': null,
        'velocity': null,
        'heading': null,
        'onGround': true,
        'lastUpdate': '2026-01-01T12:00:00Z',
      };

      final aircraft = AircraftDto.fromJson(json).toDomain();

      expect(aircraft.callsign, isNull);
      expect(aircraft.altitude, isNull);
      expect(aircraft.onGround, true);
    });
  });
}
