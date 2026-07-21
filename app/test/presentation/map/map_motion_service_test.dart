import 'package:flight_ops_app/domain/entities/aircraft.dart';
import 'package:flight_ops_app/presentation/map/map_motion_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

Aircraft _aircraft({
  required String icao24,
  double? latitude,
  double? longitude,
  double? velocity,
  double? heading,
}) => Aircraft(
  icao24: icao24,
  callsign: null,
  originCountry: 'Testland',
  longitude: longitude,
  latitude: latitude,
  altitude: null,
  velocity: velocity,
  heading: heading,
  onGround: false,
  lastUpdate: DateTime(2026, 1, 1),
);

void main() {
  group('MapMotionService', () {
    test('seeds a newly tracked aircraft at its reported position', () {
      final service = MapMotionService();
      final now = DateTime(2026, 1, 1, 12);

      service.updateSnapshot([
        _aircraft(icao24: 'abc123', latitude: 50.0, longitude: 8.0),
      ], now);
      service.tick(now);

      expect(service.positions.value['abc123'], const LatLng(50.0, 8.0));
    });

    test('does not notify when no tracked position has changed', () {
      final service = MapMotionService();
      final now = DateTime(2026, 1, 1, 12);
      service.updateSnapshot([
        _aircraft(icao24: 'abc123', latitude: 50.0, longitude: 8.0),
      ], now);
      service.tick(now);

      var notifications = 0;
      service.positions.addListener(() => notifications++);

      service.tick(now);

      expect(notifications, 0);
    });

    test('removing a previously tracked aircraft counts as a change', () {
      final service = MapMotionService();
      final now = DateTime(2026, 1, 1, 12);
      service.updateSnapshot([
        _aircraft(icao24: 'abc123', latitude: 50.0, longitude: 8.0),
      ], now);
      service.tick(now);

      var notifications = 0;
      service.positions.addListener(() => notifications++);

      service.updateSnapshot([], now);
      service.tick(now);

      expect(notifications, 1);
      expect(service.positions.value, isEmpty);
    });
  });
}
