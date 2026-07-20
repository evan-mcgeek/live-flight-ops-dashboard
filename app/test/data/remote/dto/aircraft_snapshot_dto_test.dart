import 'package:flight_ops_app/data/remote/dto/aircraft_snapshot_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AircraftSnapshotDto', () {
    test(
      'fromJson + toDomain maps a snapshot with a nested aircraft array and stale flag',
      () {
        final json = {
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
          'stale': true,
        };

        final snapshot = AircraftSnapshotDto.fromJson(json).toDomain();

        expect(snapshot.aircraft, hasLength(1));
        expect(snapshot.aircraft.first.icao24, 'abc123');
        expect(snapshot.stale, true);
      },
    );

    test('fromJson + toDomain maps an empty aircraft array', () {
      final json = {'aircraft': <dynamic>[], 'stale': false};

      final snapshot = AircraftSnapshotDto.fromJson(json).toDomain();

      expect(snapshot.aircraft, isEmpty);
      expect(snapshot.stale, false);
    });
  });
}
