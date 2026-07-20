part of 'map_bloc.dart';

sealed class MapEvent extends Equatable {
  const MapEvent();

  @override
  List<Object?> get props => [];
}

class MapViewportChanged extends MapEvent {
  const MapViewportChanged(this.bbox);

  final BoundingBox bbox;

  @override
  List<Object?> get props => [bbox];
}

class MapMarkerSelected extends MapEvent {
  const MapMarkerSelected(this.icao24);

  final String? icao24;

  @override
  List<Object?> get props => [icao24];
}

class MapActiveRegionUpdated extends MapEvent {
  const MapActiveRegionUpdated(this.regionState);

  final ActiveRegionState regionState;

  @override
  List<Object?> get props => [regionState];
}

class MapRetryRequested extends MapEvent {
  const MapRetryRequested();
}
