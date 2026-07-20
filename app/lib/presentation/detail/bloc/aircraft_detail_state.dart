part of 'aircraft_detail_bloc.dart';

sealed class AircraftDetailState extends Equatable {
  const AircraftDetailState();

  @override
  List<Object?> get props => [];
}

class AircraftDetailLoading extends AircraftDetailState {
  const AircraftDetailLoading();
}

class AircraftDetailLoaded extends AircraftDetailState {
  const AircraftDetailLoaded(this.aircraft);

  final Aircraft aircraft;

  @override
  List<Object?> get props => [aircraft];
}

class AircraftDetailNotFound extends AircraftDetailState {
  const AircraftDetailNotFound();
}

class AircraftDetailError extends AircraftDetailState {
  const AircraftDetailError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
