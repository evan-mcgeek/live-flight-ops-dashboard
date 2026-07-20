part of 'aircraft_list_bloc.dart';

sealed class AircraftListEvent extends Equatable {
  const AircraftListEvent();

  @override
  List<Object?> get props => [];
}

class AircraftListSearchChanged extends AircraftListEvent {
  const AircraftListSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

class AircraftListRegionUpdated extends AircraftListEvent {
  const AircraftListRegionUpdated(this.regionState);

  final ActiveRegionState regionState;

  @override
  List<Object?> get props => [regionState];
}

class AircraftListRetryRequested extends AircraftListEvent {
  const AircraftListRetryRequested();
}
