part of 'aircraft_detail_bloc.dart';

sealed class AircraftDetailEvent extends Equatable {
  const AircraftDetailEvent();

  @override
  List<Object?> get props => [];
}

class AircraftDetailRequested extends AircraftDetailEvent {
  const AircraftDetailRequested();
}
