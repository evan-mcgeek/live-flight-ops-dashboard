part of 'map_bloc.dart';

sealed class MapState extends Equatable {
  const MapState();
}

class MapInitial extends MapState {
  const MapInitial();

  @override
  List<Object?> get props => [];
}

class MapLoading extends MapState {
  const MapLoading();

  @override
  List<Object?> get props => [];
}

class MapLoaded extends MapState {
  const MapLoaded({
    required this.snapshot,
    this.isRefreshing = false,
    this.selectedIcao24,
  });

  final AircraftSnapshot snapshot;

  // True only while a region change (pan/zoom) is refetching after this data landed.
  final bool isRefreshing;
  final String? selectedIcao24;

  @override
  List<Object?> get props => [snapshot, isRefreshing, selectedIcao24];
}

class MapError extends MapState {
  const MapError({
    required this.failure,
    this.staleSnapshot,
    this.selectedIcao24,
  });

  final Failure failure;
  final AircraftSnapshot? staleSnapshot;
  final String? selectedIcao24;

  @override
  List<Object?> get props => [failure, staleSnapshot, selectedIcao24];
}
