import 'package:bloc_test/bloc_test.dart';
import 'package:flight_ops_app/domain/entities/aircraft.dart';
import 'package:flight_ops_app/domain/failures/failure.dart';
import 'package:flight_ops_app/domain/failures/repository_exception.dart';
import 'package:flight_ops_app/domain/repositories/aircraft_repository.dart';
import 'package:flight_ops_app/presentation/detail/bloc/aircraft_detail_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAircraftRepository extends Mock implements AircraftRepository {}

void main() {
  late _MockAircraftRepository repository;

  final aircraft = Aircraft(
    icao24: 'abc123',
    callsign: 'TEST1',
    originCountry: 'Testland',
    longitude: 1,
    latitude: 2,
    altitude: 3,
    velocity: 4,
    heading: 5,
    onGround: false,
    lastUpdate: DateTime.utc(2026, 1, 1),
  );

  setUp(() {
    repository = _MockAircraftRepository();
  });

  blocTest<AircraftDetailBloc, AircraftDetailState>(
    'loads the aircraft and emits AircraftDetailLoaded',
    setUp: () => when(
      () => repository.getDetail('abc123'),
    ).thenAnswer((_) async => aircraft),
    build: () => AircraftDetailBloc(repository, 'abc123'),
    expect: () => [
      const AircraftDetailLoading(),
      AircraftDetailLoaded(aircraft),
    ],
  );

  blocTest<AircraftDetailBloc, AircraftDetailState>(
    'emits AircraftDetailNotFound when the repository returns null',
    setUp: () => when(
      () => repository.getDetail('missing'),
    ).thenAnswer((_) async => null),
    build: () => AircraftDetailBloc(repository, 'missing'),
    expect: () => [
      const AircraftDetailLoading(),
      const AircraftDetailNotFound(),
    ],
  );

  blocTest<AircraftDetailBloc, AircraftDetailState>(
    'emits AircraftDetailError when the repository throws',
    setUp: () => when(
      () => repository.getDetail('abc123'),
    ).thenThrow(const RepositoryException(NetworkFailure())),
    build: () => AircraftDetailBloc(repository, 'abc123'),
    expect: () => [
      const AircraftDetailLoading(),
      const AircraftDetailError(NetworkFailure()),
    ],
  );
}
