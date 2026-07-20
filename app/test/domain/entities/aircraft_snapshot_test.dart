import 'package:flight_ops_app/domain/entities/aircraft.dart';
import 'package:flight_ops_app/domain/entities/aircraft_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AircraftSnapshot', () {
    test(
      'two snapshots with the same aircraft list and stale flag are equal',
      () {
        final aircraft = [
          Aircraft(
            icao24: 'abc123',
            callsign: 'TEST1',
            originCountry: 'Testland',
            longitude: 1,
            latitude: 2,
            altitude: 3,
            velocity: 4,
            heading: 5,
            onGround: false,
            lastUpdate: DateTime.utc(2026, 1, 1),
          ),
        ];

        final a = AircraftSnapshot(aircraft: aircraft, stale: false);
        final b = AircraftSnapshot(aircraft: aircraft, stale: false);

        expect(a, equals(b));
      },
    );

    test('stale flag participates in equality', () {
      final a = AircraftSnapshot(aircraft: const [], stale: false);
      final b = AircraftSnapshot(aircraft: const [], stale: true);

      expect(a, isNot(equals(b)));
    });
  });
}
