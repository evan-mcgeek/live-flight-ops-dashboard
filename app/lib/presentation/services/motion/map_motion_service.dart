import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../../../domain/entities/aircraft.dart';
import '../../../domain/settings/live_update_mode.dart';
import 'motion_math.dart';

// Recomputes every tracked aircraft's on-screen position each tick and only
// notifies listeners when at least one position actually changed — the
// coarsest granularity flutter_map's Marker API allows (a Marker's point is
// fixed at construction time, so only the MarkerLayer itself can move it).
class MapMotionService {
  final Map<String, AircraftMotion> _motion = {};
  final Map<String, LatLng> _lastRendered = {};

  LiveUpdateMode liveUpdateMode = LiveUpdateMode.standard;

  final ValueNotifier<Map<String, LatLng>> positions =
      ValueNotifier<Map<String, LatLng>>({});

  void updateSnapshot(List<Aircraft> aircraft, DateTime now) {
    final currentIds = aircraft.map((ac) => ac.icao24).toSet();
    _motion.removeWhere((icao24, _) => !currentIds.contains(icao24));
    _lastRendered.removeWhere((icao24, _) => !currentIds.contains(icao24));

    for (final ac in aircraft) {
      if (ac.latitude == null || ac.longitude == null) continue;
      final reported = LatLng(ac.latitude!, ac.longitude!);
      final previous = _motion[ac.icao24];
      if (previous == null) {
        // First report: appear directly (zero-length interval, no interpolation yet).
        _motion[ac.icao24] = AircraftMotion(
          previousPosition: reported,
          previousUpdatedAt: now,
          currentPosition: reported,
          currentUpdatedAt: now,
          correctionFrom: reported,
          correctionDuration: minCorrectionDuration,
        );
        continue;
      }
      final dtSeconds =
          now.difference(previous.currentUpdatedAt).inMilliseconds / 1000.0;
      if (dtSeconds <= 0) continue;

      final visualNow = liveUpdateMode == LiveUpdateMode.realtime
          ? positionFor(ac.icao24, reported, now)
          : reported;
      final correctionDuration = liveUpdateMode == LiveUpdateMode.realtime
          ? correctionDurationFor(visualNow, reported, ac.velocity)
          : minCorrectionDuration;
      final velocity = telemetryVelocity(
        speedMps: ac.velocity,
        headingDeg: ac.heading,
        at: reported,
      );

      _motion[ac.icao24] = AircraftMotion(
        previousPosition: previous.currentPosition,
        previousUpdatedAt: previous.currentUpdatedAt,
        currentPosition: reported,
        currentUpdatedAt: now,
        latPerSecond:
            velocity?.latPerSecond ??
            (reported.latitude - previous.currentPosition.latitude) /
                dtSeconds,
        lonPerSecond:
            velocity?.lonPerSecond ??
            (reported.longitude - previous.currentPosition.longitude) /
                dtSeconds,
        correctionFrom: visualNow,
        correctionDuration: correctionDuration,
      );
    }
  }

  LatLng positionFor(String icao24, LatLng fallback, DateTime now) {
    final motion = _motion[icao24];
    if (motion == null) return fallback;

    final candidate = liveUpdateMode == LiveUpdateMode.standard
        ? interpolatedPosition(motion, now)
        : deadReckonedPosition(motion, now);

    final last = _lastRendered[icao24];
    if (last == null) {
      _lastRendered[icao24] = candidate;
      return candidate;
    }
    final projected = forwardOnlyProjection(
      candidate: candidate,
      lastRendered: last,
      latPerSecond: motion.latPerSecond,
      lonPerSecond: motion.lonPerSecond,
    );
    _lastRendered[icao24] = projected;
    return projected;
  }

  void tick(DateTime now) {
    final next = <String, LatLng>{
      for (final icao24 in _motion.keys)
        icao24: positionFor(icao24, _motion[icao24]!.currentPosition, now),
    };

    final unchanged =
        next.length == positions.value.length &&
        next.entries.every(
          (entry) => positions.value[entry.key] == entry.value,
        );
    if (!unchanged) {
      positions.value = next;
    }
  }

  void dispose() {
    positions.dispose();
  }
}
