import 'dart:math' as math;

// Curves.easeInOut is a lightweight, non-widget, non-BuildContext part of the
// Flutter SDK — kept deliberately rather than hand-rolling the same easing curve.
import 'package:flutter/animation.dart' show Curves;
import 'package:latlong2/latlong.dart';

// WGS84 approximation: meters per degree of latitude.
const metersPerDegreeLat = 111320.0;

const minCorrectionDuration = Duration(milliseconds: 120);
const maxCorrectionDuration = Duration(milliseconds: 1500);
const maxExtrapolation = Duration(seconds: 15);
const _distance = Distance();

class AircraftMotion {
  const AircraftMotion({
    required this.previousPosition,
    required this.previousUpdatedAt,
    required this.currentPosition,
    required this.currentUpdatedAt,
    required this.correctionFrom,
    required this.correctionDuration,
    this.latPerSecond = 0,
    this.lonPerSecond = 0,
  });

  // Standard mode interpolates between this and currentPosition.
  final LatLng previousPosition;
  final DateTime previousUpdatedAt;

  final LatLng currentPosition;
  final DateTime currentUpdatedAt;

  final double latPerSecond;
  final double lonPerSecond;

  // Where the marker visually was when this report landed — correction blend start point.
  final LatLng correctionFrom;
  final Duration correctionDuration;
}

// Uses the aircraft's own reported speed/heading rather than a
// position-delta/dt estimate, which can spike arbitrarily over a short interval.
({double latPerSecond, double lonPerSecond})? telemetryVelocity({
  required double? speedMps,
  required double? headingDeg,
  required LatLng at,
}) {
  if (speedMps == null || headingDeg == null) return null;

  final headingRad = headingDeg * (math.pi / 180);
  final metersNorthPerSecond = speedMps * math.cos(headingRad);
  final metersEastPerSecond = speedMps * math.sin(headingRad);
  final metersPerDegreeLon =
      metersPerDegreeLat * math.cos(at.latitude * (math.pi / 180));

  return (
    latPerSecond: metersNorthPerSecond / metersPerDegreeLat,
    lonPerSecond: metersPerDegreeLon == 0
        ? 0
        : metersEastPerSecond / metersPerDegreeLon,
  );
}

// Correction blend duration = distance / the aircraft's own reported speed, so a
// correction never looks faster than the plane is actually flying.
Duration correctionDurationFor(LatLng from, LatLng to, double? velocityMps) {
  if (velocityMps == null || velocityMps <= 0) return minCorrectionDuration;

  final meters = _distance.distance(from, to);

  final ms = (meters / velocityMps * 1000).clamp(
    minCorrectionDuration.inMilliseconds.toDouble(),
    maxCorrectionDuration.inMilliseconds.toDouble(),
  );

  return Duration(milliseconds: ms.round());
}

// Standard mode: interpolates between the last two confirmed reports, lagged by
// roughly one poll interval; falls back to dead reckoning once the next poll
// runs later than that, instead of freezing.
LatLng interpolatedPosition(AircraftMotion motion, DateTime now) {
  final intervalMs = motion.currentUpdatedAt
      .difference(motion.previousUpdatedAt)
      .inMilliseconds;
  if (intervalMs <= 0) {
    return motion.currentPosition;
  }
  final sinceCurrentMs = now.difference(motion.currentUpdatedAt).inMilliseconds;

  if (sinceCurrentMs <= intervalMs) {
    final t = Curves.easeInOut.transform(
      (sinceCurrentMs / intervalMs).clamp(0.0, 1.0),
    );
    return LatLng(
      motion.previousPosition.latitude +
          (motion.currentPosition.latitude -
                  motion.previousPosition.latitude) *
              t,
      motion.previousPosition.longitude +
          (motion.currentPosition.longitude -
                  motion.previousPosition.longitude) *
              t,
    );
  }

  final overrunMs = (sinceCurrentMs - intervalMs).clamp(
    0,
    maxExtrapolation.inMilliseconds,
  );
  final dtSeconds = overrunMs / 1000.0;
  return LatLng(
    motion.currentPosition.latitude + motion.latPerSecond * dtSeconds,
    motion.currentPosition.longitude + motion.lonPerSecond * dtSeconds,
  );
}

// Real-time mode: continuous extrapolation from reported velocity/heading, with
// a linear (not eased) correction blend so the constant-velocity model holds
// throughout the blend, not just after it.
LatLng deadReckonedPosition(AircraftMotion motion, DateTime now) {
  final sinceUpdate = now.difference(motion.currentUpdatedAt);
  final clamped = sinceUpdate > maxExtrapolation ? maxExtrapolation : sinceUpdate;
  final dtSeconds = clamped.inMilliseconds / 1000.0;
  final deadReckoned = LatLng(
    motion.currentPosition.latitude + motion.latPerSecond * dtSeconds,
    motion.currentPosition.longitude + motion.lonPerSecond * dtSeconds,
  );
  if (sinceUpdate >= motion.correctionDuration) {
    return deadReckoned;
  }
  final blend =
      (sinceUpdate.inMilliseconds / motion.correctionDuration.inMilliseconds)
          .clamp(0.0, 1.0);
  return LatLng(
    motion.correctionFrom.latitude +
        (deadReckoned.latitude - motion.correctionFrom.latitude) * blend,
    motion.correctionFrom.longitude +
        (deadReckoned.longitude - motion.correctionFrom.longitude) * blend,
  );
}

// Projects onto the aircraft's heading line — discards any sideways/backward component.
LatLng forwardOnlyProjection({
  required LatLng candidate,
  required LatLng lastRendered,
  required double latPerSecond,
  required double lonPerSecond,
}) {
  final headingMagnitude = math.sqrt(
    latPerSecond * latPerSecond + lonPerSecond * lonPerSecond,
  );
  if (headingMagnitude == 0) {
    return candidate;
  }
  final unitLat = latPerSecond / headingMagnitude;
  final unitLon = lonPerSecond / headingMagnitude;
  final moveLat = candidate.latitude - lastRendered.latitude;
  final moveLon = candidate.longitude - lastRendered.longitude;
  final forwardDistance = moveLat * unitLat + moveLon * unitLon;
  if (forwardDistance <= 0) return lastRendered;

  return LatLng(
    lastRendered.latitude + unitLat * forwardDistance,
    lastRendered.longitude + unitLon * forwardDistance,
  );
}
