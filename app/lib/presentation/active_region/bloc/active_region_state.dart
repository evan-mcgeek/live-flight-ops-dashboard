part of 'active_region_bloc.dart';

sealed class ActiveRegionState extends Equatable {
  const ActiveRegionState();

  BoundingBox? get bbox => switch (this) {
    ActiveRegionInitial() => null,
    ActiveRegionLoading(:final bbox) => bbox,
    ActiveRegionLoaded(:final bbox) => bbox,
    ActiveRegionError(:final bbox) => bbox,
  };
}

class ActiveRegionInitial extends ActiveRegionState {
  const ActiveRegionInitial();

  @override
  List<Object?> get props => [];
}

class ActiveRegionLoading extends ActiveRegionState {
  const ActiveRegionLoading(this.bbox);

  @override
  final BoundingBox bbox;

  @override
  List<Object?> get props => [bbox];
}

class ActiveRegionLoaded extends ActiveRegionState {
  const ActiveRegionLoaded({
    required this.bbox,
    required this.snapshot,
    this.isRefreshing = false,
  });

  @override
  final BoundingBox bbox;
  final AircraftSnapshot snapshot;

  // True only while a region change (pan/zoom) is refetching after this data landed.
  final bool isRefreshing;

  @override
  List<Object?> get props => [bbox, snapshot, isRefreshing];
}

class ActiveRegionError extends ActiveRegionState {
  const ActiveRegionError({
    required this.bbox,
    required this.failure,
    this.staleSnapshot,
  });

  @override
  final BoundingBox bbox;
  final Failure failure;

  // Last-known-good data, if any, so an error after a successful load doesn't blank the screen.
  final AircraftSnapshot? staleSnapshot;

  @override
  List<Object?> get props => [bbox, failure, staleSnapshot];
}
