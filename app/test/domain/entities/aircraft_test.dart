import 'package:flight_ops_app/domain/entities/aircraft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Aircraft', () {
    test('two aircraft with the same field values are equal', () {
      final a = Aircraft(
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
      );
      final b = Aircraft(
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
      );

      expect(a, equals(b));
    });

    test(
      'nullable fields (callsign, position, altitude, velocity, heading) accept null',
      () {
        final aircraft = Aircraft(
          icao24: 'abc123',
          callsign: null,
          originCountry: 'Testland',
          longitude: null,
          latitude: null,
          altitude: null,
          velocity: null,
          heading: null,
          onGround: true,
          lastUpdate: DateTime.utc(2026, 1, 1),
        );

        expect(aircraft.callsign, isNull);
        expect(aircraft.altitude, isNull);
      },
    );
  });
}
