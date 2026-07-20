import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/entities/aircraft.dart';
import '../../../domain/failures/failure.dart';
import '../../active_region/bloc/active_region_bloc.dart';

part 'aircraft_list_event.dart';
part 'aircraft_list_state.dart';

@injectable
class AircraftListBloc extends Bloc<AircraftListEvent, AircraftListState> {
  AircraftListBloc(this._activeRegionBloc)
    : super(const AircraftListInitial()) {
    on<AircraftListSearchChanged>((event, emit) {
      emit(switch (state) {
        AircraftListInitial() => AircraftListInitial(query: event.query),
        AircraftListLoading() => AircraftListLoading(query: event.query),
        AircraftListLoaded(
          :final allAircraft,
          :final stale,
          :final isRefreshing,
        ) =>
          AircraftListLoaded(
            allAircraft: allAircraft,
            stale: stale,
            isRefreshing: isRefreshing,
            query: event.query,
          ),
        AircraftListError(:final failure, :final staleAircraft) =>
          AircraftListError(
            failure: failure,
            staleAircraft: staleAircraft,
            query: event.query,
          ),
      });
    });
    on<AircraftListRegionUpdated>((event, emit) {
      // Search text is UI-only and orthogonal to region data, so it survives across transitions.
      final query = state.query;
      emit(switch (event.regionState) {
        ActiveRegionInitial() => AircraftListInitial(query: query),
        ActiveRegionLoading() => AircraftListLoading(query: query),
        ActiveRegionLoaded(:final snapshot, :final isRefreshing) =>
          AircraftListLoaded(
            allAircraft: snapshot.aircraft,
            stale: snapshot.stale,
            isRefreshing: isRefreshing,
            query: query,
          ),
        ActiveRegionError(:final failure, :final staleSnapshot) =>
          AircraftListError(
            failure: failure,
            staleAircraft: staleSnapshot?.aircraft,
            query: query,
          ),
      });
    });
    on<AircraftListRetryRequested>((event, emit) {
      final bbox = _activeRegionBloc.state.bbox;
      if (bbox != null) _activeRegionBloc.add(UpdateRegionRequested(bbox));
    });

    // Seed with the current state — .stream only emits future changes.
    add(AircraftListRegionUpdated(_activeRegionBloc.state));
    _subscription = _activeRegionBloc.stream.listen(
      (regionState) => add(AircraftListRegionUpdated(regionState)),
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
