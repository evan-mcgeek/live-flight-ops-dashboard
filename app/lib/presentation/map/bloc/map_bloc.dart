import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/entities/aircraft_snapshot.dart';
import '../../../domain/entities/bounding_box.dart';
import '../../../domain/failures/failure.dart';
import '../../active_region/bloc/active_region_bloc.dart';

part 'map_event.dart';
part 'map_state.dart';

@injectable
class MapBloc extends Bloc<MapEvent, MapState> {
  MapBloc(this._activeRegionBloc) : super(const MapInitial()) {
    on<MapViewportChanged>(
      (event, emit) => _activeRegionBloc.add(UpdateRegionRequested(event.bbox)),
    );
    on<MapMarkerSelected>((event, emit) {
      // Nothing to select before data exists — Initial/Loading are left as-is.
      switch (state) {
        case MapLoaded(:final snapshot, :final isRefreshing):
          emit(
            MapLoaded(
              snapshot: snapshot,
              isRefreshing: isRefreshing,
              selectedIcao24: event.icao24,
            ),
          );
        case MapError(:final failure, :final staleSnapshot):
          emit(
            MapError(
              failure: failure,
              staleSnapshot: staleSnapshot,
              selectedIcao24: event.icao24,
            ),
          );
        case MapInitial():
        case MapLoading():
          break;
      }
    });
    on<MapActiveRegionUpdated>((event, emit) {
      // Selection is UI-only and orthogonal to region data, so it survives across transitions.
      final selected = switch (state) {
        MapLoaded(:final selectedIcao24) => selectedIcao24,
        MapError(:final selectedIcao24) => selectedIcao24,
        _ => null,
      };
      emit(switch (event.regionState) {
        ActiveRegionInitial() => const MapInitial(),
        ActiveRegionLoading() => const MapLoading(),
        ActiveRegionLoaded(:final snapshot, :final isRefreshing) => MapLoaded(
          snapshot: snapshot,
          isRefreshing: isRefreshing,
          selectedIcao24: selected,
        ),
        ActiveRegionError(:final failure, :final staleSnapshot) => MapError(
          failure: failure,
          staleSnapshot: staleSnapshot,
          selectedIcao24: selected,
        ),
      });
    });
    on<MapRetryRequested>((event, emit) {
      final bbox = _activeRegionBloc.state.bbox;
      if (bbox != null) _activeRegionBloc.add(UpdateRegionRequested(bbox));
    });

    // Seed with the current state — .stream only emits future changes.
    add(MapActiveRegionUpdated(_activeRegionBloc.state));
    _subscription = _activeRegionBloc.stream.listen(
      (regionState) => add(MapActiveRegionUpdated(regionState)),
    );
  }

  final ActiveRegionBloc _activeRegionBloc;
  late final StreamSubscription<ActiveRegionState> _subscription;

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
