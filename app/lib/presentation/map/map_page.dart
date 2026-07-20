import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/di/injection.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_strings.dart';
import '../../domain/entities/aircraft.dart';
import '../../domain/entities/bounding_box.dart';
import '../../domain/settings/live_update_mode.dart';
import '../detail/bloc/aircraft_detail_bloc.dart';
import '../detail/aircraft_detail_page.dart';
import '../settings/bloc/settings_bloc.dart';
import '../shared/live_status_chip.dart';
import 'bloc/map_bloc.dart' hide MapEvent;
import 'widgets/aircraft_marker.dart';
import 'widgets/map_state_overlay.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<MapBloc>(),
      child: const _MapView(),
    );
  }
}

class _MapView extends StatefulWidget {
  const _MapView();

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  Timer? _debounce;

  // Standard mode interpolates between the last two confirmed reports (never
  // extrapolates); real-time mode dead-reckons forward every frame via
  // _positionFor. _ticker just forces a rebuild each frame to drive both.
  final Map<String, _AircraftMotion> _motion = {};
  late final Ticker _ticker = createTicker((_) => setState(() {}));

  LiveUpdateMode _liveUpdateMode = LiveUpdateMode.standard;

  // Real-time mode only: stop extrapolating after this long without a new
  // report, so a dropped-off aircraft doesn't fly forever in a straight line.
  static const _maxExtrapolation = Duration(seconds: 15);

  // Correction blend duration = distance / the aircraft's own reported speed,
  // so a correction never looks faster than the plane is actually flying.
  // Min/max only guard a near-zero gap or near-zero reported speed.
  static const _minCorrectionDuration = Duration(milliseconds: 120);
  static const _maxCorrectionDuration = Duration(milliseconds: 1500);
  static const _distance = Distance();

  // Corrections project onto the heading line through this last rendered
  // position, so a blend never visibly moves an aircraft sideways/backward.
  final Map<String, LatLng> _lastRendered = {};

  Duration _correctionDurationFor(LatLng from, LatLng to, double? velocityMps) {
    if (velocityMps == null || velocityMps <= 0) return _minCorrectionDuration;
    final meters = _distance.distance(from, to);
    final ms = (meters / velocityMps * 1000).clamp(
      _minCorrectionDuration.inMilliseconds.toDouble(),
      _maxCorrectionDuration.inMilliseconds.toDouble(),
    );
    return Duration(milliseconds: ms.round());
  }

  static const _initialCenter = LatLng(50.0, 8.5);
  static const _initialZoom = 7.0;

  // Seeds the first region request before the map has laid out and a real
  // viewport exists — replaced as soon as the user pans/zooms.
  static const _initialBounds = BoundingBox(
    laMin: 35.0,
    loMin: -10.0,
    laMax: 65.0,
    loMax: 27.0,
  );

  @override
  void initState() {
    super.initState();
    _ticker.start();
    context.read<MapBloc>().add(const MapViewportChanged(_initialBounds));
  }

  // MapEventWithMove catches every camera change (drag/zoom/controller
  // moves) — the narrower MapEventMoveEnd misses programmatic moves entirely.
  void _onMapEvent(MapEvent event) {
    if (event is! MapEventWithMove) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final bounds = _mapController.camera.visibleBounds;
      context.read<MapBloc>().add(
        MapViewportChanged(
          BoundingBox(
            laMin: bounds.south,
            loMin: bounds.west,
            laMax: bounds.north,
            loMax: bounds.east,
          ),
        ),
      );
    });
  }

  // Uses the aircraft's own reported speed/heading rather than a
  // position-delta/dt estimate, which can spike arbitrarily over a short
  // interval. Falls back to delta/dt only when telemetry omits either value.
  ({double latPerSecond, double lonPerSecond})? _telemetryVelocity(
    Aircraft ac,
    LatLng at,
  ) {
    final speedMps = ac.velocity;
    final headingDeg = ac.heading;
    if (speedMps == null || headingDeg == null) return null;
    const metersPerDegreeLat = 111320.0;
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

  // Shifts current->previous per aircraft each update; standard mode
  // interpolates between the two, both modes' dead-reckoning uses _telemetryVelocity.
  void _syncMarkerPositions(List<Aircraft> aircraft) {
    // Drop aircraft no longer in this snapshot so this map doesn't grow unbounded.
    final currentIds = aircraft.map((ac) => ac.icao24).toSet();
    _motion.removeWhere((icao24, _) => !currentIds.contains(icao24));
    _lastRendered.removeWhere((icao24, _) => !currentIds.contains(icao24));

    final now = DateTime.now();
    for (final ac in aircraft) {
      if (ac.latitude == null || ac.longitude == null) continue;
      final reported = LatLng(ac.latitude!, ac.longitude!);
      final previous = _motion[ac.icao24];
      if (previous == null) {
        // First report: appear directly (zero-length interval, no interpolation yet).
        _motion[ac.icao24] = _AircraftMotion(
          previousPosition: reported,
          previousUpdatedAt: now,
          currentPosition: reported,
          currentUpdatedAt: now,
          correctionFrom: reported,
          correctionDuration: _minCorrectionDuration,
        );
        continue;
      }
      final dtSeconds =
          now.difference(previous.currentUpdatedAt).inMilliseconds / 1000.0;
      if (dtSeconds <= 0) {
        // Duplicate/out-of-order report — skip rather than shift a zero/negative interval.
        continue;
      }
      // Captured before overwriting motion, so real-time mode's correction blend has no discontinuity.
      final visualNow = _liveUpdateMode == LiveUpdateMode.realtime
          ? _positionFor(ac.icao24, reported)
          : reported;
      final correctionDuration = _liveUpdateMode == LiveUpdateMode.realtime
          ? _correctionDurationFor(visualNow, reported, ac.velocity)
          : _minCorrectionDuration;
      final telemetryVelocity = _telemetryVelocity(ac, reported);
      _motion[ac.icao24] = _AircraftMotion(
        previousPosition: previous.currentPosition,
        previousUpdatedAt: previous.currentUpdatedAt,
        currentPosition: reported,
        currentUpdatedAt: now,
        latPerSecond:
            telemetryVelocity?.latPerSecond ??
            (reported.latitude - previous.currentPosition.latitude) / dtSeconds,
        lonPerSecond:
            telemetryVelocity?.lonPerSecond ??
            (reported.longitude - previous.currentPosition.longitude) /
                dtSeconds,
        correctionFrom: visualNow,
        correctionDuration: correctionDuration,
      );
    }
  }

  // Standard mode interpolates between the last two confirmed reports, lagged
  // by roughly one poll interval; if the next poll runs later than that, it
  // falls back to real-time mode's dead reckoning instead of freezing.
  LatLng _positionFor(String icao24, LatLng fallback) {
    final motion = _motion[icao24];
    if (motion == null) return fallback;

    if (_liveUpdateMode == LiveUpdateMode.standard) {
      final intervalMs = motion.currentUpdatedAt
          .difference(motion.previousUpdatedAt)
          .inMilliseconds;
      if (intervalMs <= 0) {
        return _forwardOnly(icao24, motion.currentPosition, motion);
      }
      // Lagged elapsed time reduces to "time since current arrived" — t starts at 0 showing previousPosition.
      final sinceCurrentMs = DateTime.now()
          .difference(motion.currentUpdatedAt)
          .inMilliseconds;

      if (sinceCurrentMs <= intervalMs) {
        final t = Curves.easeInOut.transform(
          (sinceCurrentMs / intervalMs).clamp(0.0, 1.0),
        );
        final candidate = LatLng(
          motion.previousPosition.latitude +
              (motion.currentPosition.latitude -
                      motion.previousPosition.latitude) *
                  t,
          motion.previousPosition.longitude +
              (motion.currentPosition.longitude -
                      motion.previousPosition.longitude) *
                  t,
        );
        return _forwardOnly(icao24, candidate, motion);
      }

      // Next poll running later than the previous interval — keep
      // moving via dead reckoning instead of holding still until it lands.
      final overrunMs = (sinceCurrentMs - intervalMs).clamp(
        0,
        _maxExtrapolation.inMilliseconds,
      );
      final dtSeconds = overrunMs / 1000.0;
      final candidate = LatLng(
        motion.currentPosition.latitude + motion.latPerSecond * dtSeconds,
        motion.currentPosition.longitude + motion.lonPerSecond * dtSeconds,
      );
      return _forwardOnly(icao24, candidate, motion);
    }

    final sinceUpdate = DateTime.now().difference(motion.currentUpdatedAt);
    final clamped = sinceUpdate > _maxExtrapolation
        ? _maxExtrapolation
        : sinceUpdate;
    final dtSeconds = clamped.inMilliseconds / 1000.0;
    final deadReckoned = LatLng(
      motion.currentPosition.latitude + motion.latPerSecond * dtSeconds,
      motion.currentPosition.longitude + motion.lonPerSecond * dtSeconds,
    );
    LatLng candidate;
    if (sinceUpdate >= motion.correctionDuration) {
      candidate = deadReckoned;
    } else {
      // Linear, not eased — an eased curve would vary speed across the blend,
      // reintroducing the burst correctionDuration's constant-velocity model avoids.
      final blend =
          (sinceUpdate.inMilliseconds /
                  motion.correctionDuration.inMilliseconds)
              .clamp(0.0, 1.0);
      candidate = LatLng(
        motion.correctionFrom.latitude +
            (deadReckoned.latitude - motion.correctionFrom.latitude) * blend,
        motion.correctionFrom.longitude +
            (deadReckoned.longitude - motion.correctionFrom.longitude) * blend,
      );
    }
    return _forwardOnly(icao24, candidate, motion);
  }

  // Projects onto the aircraft's heading line — discards any sideways/backward component.
  LatLng _forwardOnly(String icao24, LatLng candidate, _AircraftMotion motion) {
    final last = _lastRendered[icao24];
    if (last == null) {
      _lastRendered[icao24] = candidate;
      return candidate;
    }
    final headingMagnitude = math.sqrt(
      motion.latPerSecond * motion.latPerSecond +
          motion.lonPerSecond * motion.lonPerSecond,
    );
    if (headingMagnitude == 0) {
      // No established heading (e.g. stationary on ground) — nothing to project onto.
      _lastRendered[icao24] = candidate;
      return candidate;
    }
    final unitLat = motion.latPerSecond / headingMagnitude;
    final unitLon = motion.lonPerSecond / headingMagnitude;
    final moveLat = candidate.latitude - last.latitude;
    final moveLon = candidate.longitude - last.longitude;
    // Scalar projection of the move onto the heading direction — negative means backward.
    final forwardDistance = moveLat * unitLat + moveLon * unitLon;
    if (forwardDistance <= 0) return last;
    final projected = LatLng(
      last.latitude + unitLat * forwardDistance,
      last.longitude + unitLon * forwardDistance,
    );
    _lastRendered[icao24] = projected;
    return projected;
  }

  // Ascending altitude — later markers paint on top, so higher planes sit above lower ones.
  List<Aircraft> _sortedByAltitude(List<Aircraft> aircraft) =>
      [...aircraft]
        ..sort((a, b) => (a.altitude ?? 0).compareTo(b.altitude ?? 0));

  List<Aircraft> _aircraftOf(MapState state) => switch (state) {
    MapLoaded(:final snapshot) => snapshot.aircraft,
    MapError(:final staleSnapshot) => staleSnapshot?.aircraft ?? const [],
    _ => const [],
  };

  @override
  void dispose() {
    _debounce?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  static const _minZoom = 3.0;
  static const _maxZoom = 18.0;

  void _zoomBy(double delta) {
    final camera = _mapController.camera;
    _mapController.move(
      camera.center,
      (camera.zoom + delta).clamp(_minZoom, _maxZoom),
    );
  }

  void _recenter() {
    _mapController.move(_initialCenter, _initialZoom);
  }

  // Bottom sheet, not a full-screen push (unlike the list row tap) — needs its
  // own AircraftDetailBloc instance since the bloc is per-instance (@factoryParam).
  void _showAircraftDetailSheet(BuildContext context, String icao24) {
    final colors = Theme.of(context).extension<AppColors>()!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.75,
        child: BlocProvider(
          create: (_) => getIt<AircraftDetailBloc>(param1: icao24),
          child: Container(
            decoration: BoxDecoration(
              color: colors.panel,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: const SafeArea(top: false, child: AircraftDetailContent()),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // watch, not read: a mode change on Settings should apply immediately, not on next reopen.
    _liveUpdateMode = context.watch<SettingsBloc>().state.liveUpdateMode;
    return Scaffold(
      body: BlocConsumer<MapBloc, MapState>(
        listener: (context, state) => _syncMarkerPositions(_aircraftOf(state)),
        builder: (context, state) {
          final aircraft = _aircraftOf(state);
          final failure = switch (state) {
            MapError(:final failure) => failure,
            _ => null,
          };
          final isRefreshing = switch (state) {
            MapLoaded(:final isRefreshing) => isRefreshing,
            _ => false,
          };
          final selectedIcao24 = switch (state) {
            MapLoaded(:final selectedIcao24) => selectedIcao24,
            MapError(:final selectedIcao24) => selectedIcao24,
            _ => null,
          };
          // The map always renders underneath; loading/error are overlays, not a replacement for it.
          final isLoading = state is MapInitial || state is MapLoading;
          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _initialCenter,
                  initialZoom: _initialZoom,
                  minZoom: _minZoom,
                  maxZoom: _maxZoom,
                  onMapEvent: _onMapEvent,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.flightops.flight_ops_app',
                  ),
                  MarkerLayer(
                    markers: [
                      // Sorted so higher-altitude aircraft paint on top of lower ones.
                      for (final ac in _sortedByAltitude(aircraft))
                        if (ac.latitude != null && ac.longitude != null)
                          Marker(
                            key: ValueKey(ac.icao24),
                            point: _positionFor(
                              ac.icao24,
                              LatLng(ac.latitude!, ac.longitude!),
                            ),
                            width: 40,
                            height: 40,
                            child: GestureDetector(
                              onTap: () {
                                context.read<MapBloc>().add(
                                  MapMarkerSelected(ac.icao24),
                                );
                                _showAircraftDetailSheet(context, ac.icao24);
                              },
                              child: AircraftMarker(
                                key: Key(ac.icao24),
                                headingDegrees: ac.heading ?? 0,
                                onGround: ac.onGround,
                                selected: selectedIcao24 == ac.icao24,
                              ),
                            ),
                          ),
                    ],
                  ),
                ],
              ),
              // One chip morphs between loading/live/error via AnimatedSize + AnimatedSwitcher.
              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: LiveStatusChip(
                        key: ValueKey(
                          isLoading
                              ? 'loading'
                              : (failure != null ? 'error' : 'live'),
                        ),
                        aircraftCount: aircraft.length,
                        isRefreshing: isRefreshing,
                        variant: isLoading
                            ? LiveStatusChipVariant.loading
                            : failure != null
                            ? LiveStatusChipVariant.error
                            : LiveStatusChipVariant.live,
                      ),
                    ),
                  ),
                ),
              ),
              if (failure != null)
                MapStateOverlay(
                  icon: Icons.error_outline,
                  title: AppStrings.somethingWentWrong,
                  subtitle: AppStrings.errorLoadingAircraft,
                  buttonLabel: AppStrings.tryAgain,
                  onRetry: () =>
                      context.read<MapBloc>().add(const MapRetryRequested()),
                ),
              Positioned(
                right: 16,
                bottom: 110,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'map_zoom_in',
                      onPressed: () => _zoomBy(1),
                      child: const Icon(Icons.add),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'map_zoom_out',
                      onPressed: () => _zoomBy(-1),
                      child: const Icon(Icons.remove),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'map_recenter',
                      onPressed: _recenter,
                      child: const Icon(Icons.my_location),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AircraftMotion {
  const _AircraftMotion({
    required this.previousPosition,
    required this.previousUpdatedAt,
    required this.currentPosition,
    required this.currentUpdatedAt,
    required this.correctionFrom,
    required this.correctionDuration,
    this.latPerSecond = 0,
    this.lonPerSecond = 0,
  });

  // previousPosition/previousUpdatedAt: standard mode interpolates between this and current.
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
