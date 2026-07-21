import 'dart:async';

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
import '../detail/bloc/aircraft_detail_bloc.dart';
import '../detail/aircraft_detail_page.dart';
import '../settings/bloc/settings_bloc.dart';
import '../shared/live_status_chip.dart';
import 'bloc/map_bloc.dart' hide MapEvent;
import '../services/motion/map_motion_service.dart';
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

  final MapMotionService _motionService = MapMotionService();
  late final Ticker _ticker = createTicker(
    (_) => _motionService.tick(DateTime.now()),
  );

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
    _motionService.dispose();
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
    _motionService.liveUpdateMode =
        context.watch<SettingsBloc>().state.liveUpdateMode;
    return Scaffold(
      body: BlocConsumer<MapBloc, MapState>(
        listener: (context, state) =>
            _motionService.updateSnapshot(_aircraftOf(state), DateTime.now()),
        builder: (context, state) {
          final aircraft = _sortedByAltitude(_aircraftOf(state));
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
                  ValueListenableBuilder<Map<String, LatLng>>(
                    valueListenable: _motionService.positions,
                    builder: (context, positions, _) {
                      return MarkerLayer(
                        markers: [
                          // Sorted so higher-altitude aircraft paint on top of lower ones.
                          for (final ac in aircraft)
                            if (ac.latitude != null && ac.longitude != null)
                              Marker(
                                key: ValueKey(ac.icao24),
                                point:
                                    positions[ac.icao24] ??
                                    LatLng(ac.latitude!, ac.longitude!),
                                width: 40,
                                height: 40,
                                child: GestureDetector(
                                  onTap: () {
                                    context.read<MapBloc>().add(
                                      MapMarkerSelected(ac.icao24),
                                    );
                                    _showAircraftDetailSheet(
                                      context,
                                      ac.icao24,
                                    );
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
                      );
                    },
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
