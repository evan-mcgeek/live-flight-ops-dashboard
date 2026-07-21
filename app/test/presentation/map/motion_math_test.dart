import 'package:flight_ops_app/presentation/map/motion_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('telemetryVelocity', () {
    test('returns null when speed or heading is missing', () {
      expect(
        telemetryVelocity(
          speedMps: null,
          headingDeg: 90,
          at: const LatLng(50, 8),
        ),
        isNull,
      );
      expect(
        telemetryVelocity(
          speedMps: 100,
          headingDeg: null,
          at: const LatLng(50, 8),
        ),
        isNull,
      );
    });

    test('decomposes speed/heading into lat/lon per-second components', () {
      final velocity = telemetryVelocity(
        speedMps: 100,
        headingDeg: 90, // due east
        at: const LatLng(0, 0), // equator: no longitude shrinkage
      )!;

      expect(velocity.latPerSecond, closeTo(0, 1e-9));
      expect(velocity.lonPerSecond, closeTo(100 / 111320.0, 1e-9));
    });
  });

  group('correctionDurationFor', () {
    test('returns the minimum when velocity is null or non-positive', () {
      const from = LatLng(50, 8);
      const to = LatLng(50, 8.01);

      expect(correctionDurationFor(from, to, null), minCorrectionDuration);
      expect(correctionDurationFor(from, to, 0), minCorrectionDuration);
      expect(correctionDurationFor(from, to, -5), minCorrectionDuration);
    });

    test('clamps to the maximum for a large distance and slow speed', () {
      const from = LatLng(0, 0);
      const to = LatLng(10, 10);

      expect(correctionDurationFor(from, to, 1), maxCorrectionDuration);
    });
  });

  group('interpolatedPosition', () {
    test('returns the previous position at the start of the interval', () {
      final previousTime = DateTime(2026, 1, 1, 12, 0, 0);
      final currentTime = previousTime.add(const Duration(seconds: 5));
      final motion = AircraftMotion(
        previousPosition: const LatLng(50.0, 8.0),
        previousUpdatedAt: previousTime,
        currentPosition: const LatLng(50.1, 8.1),
        currentUpdatedAt: currentTime,
        correctionFrom: const LatLng(50.0, 8.0),
        correctionDuration: minCorrectionDuration,
      );

      final position = interpolatedPosition(motion, currentTime);

      expect(position.latitude, closeTo(50.0, 1e-9));
      expect(position.longitude, closeTo(8.0, 1e-9));
    });

    test(
      'falls back to dead reckoning once the poll runs later than the interval',
      () {
        final previousTime = DateTime(2026, 1, 1, 12, 0, 0);
        final currentTime = previousTime.add(const Duration(seconds: 5));
        final motion = AircraftMotion(
          previousPosition: const LatLng(50.0, 8.0),
          previousUpdatedAt: previousTime,
          currentPosition: const LatLng(50.1, 8.1),
          currentUpdatedAt: currentTime,
          correctionFrom: const LatLng(50.0, 8.0),
          correctionDuration: minCorrectionDuration,
          latPerSecond: 0.001,
          lonPerSecond: 0.002,
        );
        final overrunNow = currentTime.add(const Duration(seconds: 6));

        final position = interpolatedPosition(motion, overrunNow);

        // Overrun is measured past the interval (6s elapsed - 5s interval = 1s), not the full 6s.
        expect(position.latitude, closeTo(50.1 + 0.001 * 1, 1e-9));
        expect(position.longitude, closeTo(8.1 + 0.002 * 1, 1e-9));
      },
    );
  });

  group('deadReckonedPosition', () {
    test('extrapolates using reported velocity once past the correction blend', () {
      final currentTime = DateTime(2026, 1, 1, 12, 0, 0);
      final motion = AircraftMotion(
        previousPosition: const LatLng(50.0, 8.0),
        previousUpdatedAt: currentTime,
        currentPosition: const LatLng(50.0, 8.0),
        currentUpdatedAt: currentTime,
        correctionFrom: const LatLng(50.0, 8.0),
        correctionDuration: minCorrectionDuration,
        latPerSecond: 0.001,
        lonPerSecond: 0.002,
      );
      final now = currentTime.add(const Duration(seconds: 2));

      final position = deadReckonedPosition(motion, now);

      expect(position.latitude, closeTo(50.0 + 0.001 * 2, 1e-9));
      expect(position.longitude, closeTo(8.0 + 0.002 * 2, 1e-9));
    });

    test('blends linearly from correctionFrom during the correction window', () {
      final currentTime = DateTime(2026, 1, 1, 12, 0, 0);
      final motion = AircraftMotion(
        previousPosition: const LatLng(50.0, 8.0),
        previousUpdatedAt: currentTime,
        currentPosition: const LatLng(50.0, 8.0),
        currentUpdatedAt: currentTime,
        correctionFrom: const LatLng(49.0, 7.0),
        correctionDuration: const Duration(milliseconds: 1000),
        latPerSecond: 0,
        lonPerSecond: 0,
      );
      final halfway = currentTime.add(const Duration(milliseconds: 500));

      final position = deadReckonedPosition(motion, halfway);

      expect(position.latitude, closeTo(49.5, 1e-9));
      expect(position.longitude, closeTo(7.5, 1e-9));
    });
  });

  group('forwardOnlyProjection', () {
    test('accepts forward movement along the heading', () {
      final projected = forwardOnlyProjection(
        candidate: const LatLng(50.001, 8.0),
        lastRendered: const LatLng(50.0, 8.0),
        latPerSecond: 1,
        lonPerSecond: 0,
      );

      expect(projected.latitude, closeTo(50.001, 1e-9));
    });

    test('rejects backward movement and holds the last rendered position', () {
      final projected = forwardOnlyProjection(
        candidate: const LatLng(49.999, 8.0),
        lastRendered: const LatLng(50.0, 8.0),
        latPerSecond: 1,
        lonPerSecond: 0,
      );

      expect(projected, const LatLng(50.0, 8.0));
    });

    test('passes the candidate through when no heading is established', () {
      final projected = forwardOnlyProjection(
        candidate: const LatLng(50.001, 8.001),
        lastRendered: const LatLng(50.0, 8.0),
        latPerSecond: 0,
        lonPerSecond: 0,
      );

      expect(projected, const LatLng(50.001, 8.001));
    });
  });
}
