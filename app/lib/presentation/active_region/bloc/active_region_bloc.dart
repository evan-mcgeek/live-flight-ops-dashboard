import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/entities/aircraft_snapshot.dart';
import '../../../domain/entities/bounding_box.dart';
import '../../../domain/failures/failure.dart';
import '../../../domain/failures/repository_exception.dart';
import '../../../domain/repositories/aircraft_repository.dart';

part 'active_region_event.dart';
part 'active_region_state.dart';

// dispose required: without it, getIt.reset() never closes the old watchSnapshot subscription.
@Singleton(dispose: disposeActiveRegionBloc)
class ActiveRegionBloc extends Bloc<ActiveRegionEvent, ActiveRegionState> {
  ActiveRegionBloc(this._repository) : super(const ActiveRegionInitial()) {
    on<UpdateRegionRequested>(
      _onUpdateRegionRequested,
      transformer: restartable(),
    );
  }

  final AircraftRepository _repository;

  Future<void> _onUpdateRegionRequested(
    UpdateRegionRequested event,
    Emitter<ActiveRegionState> emit,
  ) async {
    final current = state;
    // Same bbox + no failure = no-op; same bbox + failure = manual retry.
    if (current.bbox == event.bbox && current is! ActiveRegionError) return;

    final priorSnapshot = switch (current) {
      ActiveRegionLoaded(:final snapshot) => snapshot,
      ActiveRegionError(:final staleSnapshot) => staleSnapshot,
      _ => null,
    };

    // Refetch shows the prior data with isRefreshing; a genuinely first load shows Loading.
    emit(
      priorSnapshot != null
          ? ActiveRegionLoaded(
              bbox: event.bbox,
              snapshot: priorSnapshot,
              isRefreshing: true,
            )
          : ActiveRegionLoading(event.bbox),
    );

    await emit.forEach<AircraftSnapshot>(
      _repository.watchSnapshot(event.bbox),
      onData: (snapshot) =>
          ActiveRegionLoaded(bbox: event.bbox, snapshot: snapshot),
      onError: (error, _) {
        final failure = error is RepositoryException
            ? error.failure
            : const UnknownFailure();
        // Reads `state` (not the pre-forEach priorSnapshot) so an error following
        // a successful emit within this same fetch keeps that newer data as stale.
        final latestSnapshot = switch (state) {
          ActiveRegionLoaded(:final snapshot) => snapshot,
          ActiveRegionError(:final staleSnapshot) => staleSnapshot,
          _ => priorSnapshot,
        };
        return ActiveRegionError(
          bbox: event.bbox,
          failure: failure,
          staleSnapshot: latestSnapshot,
        );
      },
    );
  }
}

FutureOr<void> disposeActiveRegionBloc(ActiveRegionBloc instance) =>
    instance.close();
