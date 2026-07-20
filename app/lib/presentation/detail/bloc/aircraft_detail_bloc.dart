import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/entities/aircraft.dart';
import '../../../domain/failures/failure.dart';
import '../../../domain/failures/repository_exception.dart';
import '../../../domain/repositories/aircraft_repository.dart';

part 'aircraft_detail_event.dart';
part 'aircraft_detail_state.dart';

@injectable
class AircraftDetailBloc
    extends Bloc<AircraftDetailEvent, AircraftDetailState> {
  AircraftDetailBloc(this._repository, @factoryParam this.icao24)
    : super(const AircraftDetailLoading()) {
    on<AircraftDetailRequested>(_onRequested);
    add(const AircraftDetailRequested());
  }

  final AircraftRepository _repository;
  final String icao24;

  Future<void> _onRequested(
    AircraftDetailRequested event,
    Emitter<AircraftDetailState> emit,
  ) async {
    emit(const AircraftDetailLoading());
    try {
      final aircraft = await _repository.getDetail(icao24);
      emit(
        aircraft == null
            ? const AircraftDetailNotFound()
            : AircraftDetailLoaded(aircraft),
      );
    } on RepositoryException catch (e) {
      emit(AircraftDetailError(e.failure));
    } catch (_) {
      emit(const AircraftDetailError(UnknownFailure()));
    }
  }
}
