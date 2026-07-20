import 'package:bloc_test/bloc_test.dart';
import 'package:flight_ops_app/domain/entities/aircraft_snapshot.dart';
import 'package:flight_ops_app/domain/entities/bounding_box.dart';
import 'package:flight_ops_app/domain/failures/failure.dart';
import 'package:flight_ops_app/domain/failures/repository_exception.dart';
import 'package:flight_ops_app/domain/repositories/aircraft_repository.dart';
import 'package:flight_ops_app/presentation/active_region/bloc/active_region_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAircraftRepository extends Mock implements AircraftRepository {}

void main() {
  const bboxA = BoundingBox(laMin: 1, loMin: 2, laMax: 3, loMax: 4);
  const bboxB = BoundingBox(laMin: 5, loMin: 6, laMax: 7, loMax: 8);
  final snapshot = AircraftSnapshot(aircraft: const [], stale: false);

  late _MockAircraftRepository repository;

  setUp(() {
    repository = _MockAircraftRepository();
    registerFallbackValue(bboxA);
  });

  blocTest<ActiveRegionBloc, ActiveRegionState>(
    'UpdateRegionRequested subscribes to watchSnapshot(bbox) and emits Loading then Loaded',
    setUp: () {
      when(
        () => repository.watchSnapshot(bboxA),
      ).thenAnswer((_) => Stream.value(snapshot));
    },
    build: () => ActiveRegionBloc(repository),
    act: (bloc) => bloc.add(const UpdateRegionRequested(bboxA)),
    expect: () => [
      const ActiveRegionLoading(bboxA),
      ActiveRegionLoaded(bbox: bboxA, snapshot: snapshot),
    ],
  );

  blocTest<ActiveRegionBloc, ActiveRegionState>(
    'the first snapshot lands as Loaded even when the snapshot is empty',
    setUp: () {
      when(
        () => repository.watchSnapshot(bboxA),
      ).thenAnswer((_) => Stream.value(snapshot));
    },
    build: () => ActiveRegionBloc(repository),
    act: (bloc) => bloc.add(const UpdateRegionRequested(bboxA)),
    verify: (bloc) {
      expect(bloc.state, isA<ActiveRegionLoaded>());
      expect((bloc.state as ActiveRegionLoaded).snapshot.aircraft, isEmpty);
    },
  );

  blocTest<ActiveRegionBloc, ActiveRegionState>(
    'UpdateRegionRequested with an unchanged bbox and no failure is a no-op',
    setUp: () {
      when(
        () => repository.watchSnapshot(bboxA),
      ).thenAnswer((_) => const Stream.empty());
    },
    build: () => ActiveRegionBloc(repository),
    act: (bloc) {
      bloc.add(const UpdateRegionRequested(bboxA));
      bloc.add(const UpdateRegionRequested(bboxA));
    },
    expect: () => [const ActiveRegionLoading(bboxA)],
    verify: (_) => verify(() => repository.watchSnapshot(bboxA)).called(1),
  );

  blocTest<ActiveRegionBloc, ActiveRegionState>(
    'UpdateRegionRequested with a new bbox cancels the old subscription and starts a new one',
    setUp: () {
      when(
        () => repository.watchSnapshot(bboxA),
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => repository.watchSnapshot(bboxB),
      ).thenAnswer((_) => Stream.value(snapshot));
    },
    build: () => ActiveRegionBloc(repository),
    act: (bloc) {
      bloc.add(const UpdateRegionRequested(bboxA));
      bloc.add(const UpdateRegionRequested(bboxB));
    },
    expect: () => [
      const ActiveRegionLoading(bboxA),
      const ActiveRegionLoading(bboxB),
      ActiveRegionLoaded(bbox: bboxB, snapshot: snapshot),
    ],
  );

  blocTest<ActiveRegionBloc, ActiveRegionState>(
    'a RepositoryException on the stream is mapped to an Error state',
    setUp: () {
      when(() => repository.watchSnapshot(bboxA)).thenAnswer(
        (_) => Stream.error(const RepositoryException(NetworkFailure())),
      );
    },
    build: () => ActiveRegionBloc(repository),
    act: (bloc) => bloc.add(const UpdateRegionRequested(bboxA)),
    expect: () => [
      const ActiveRegionLoading(bboxA),
      const ActiveRegionError(bbox: bboxA, failure: NetworkFailure()),
    ],
  );

  blocTest<ActiveRegionBloc, ActiveRegionState>(
    'an error after a successful snapshot carries that snapshot as staleSnapshot',
    setUp: () {
      when(() => repository.watchSnapshot(bboxA)).thenAnswer(
        (_) => Stream.fromFutures([
          Future.value(snapshot),
          Future.error(const RepositoryException(NetworkFailure())),
        ]),
      );
    },
    build: () => ActiveRegionBloc(repository),
    act: (bloc) => bloc.add(const UpdateRegionRequested(bboxA)),
    expect: () => [
      const ActiveRegionLoading(bboxA),
      ActiveRegionLoaded(bbox: bboxA, snapshot: snapshot),
      ActiveRegionError(
        bbox: bboxA,
        failure: const NetworkFailure(),
        staleSnapshot: snapshot,
      ),
    ],
  );

  blocTest<ActiveRegionBloc, ActiveRegionState>(
    'retry: re-dispatching UpdateRegionRequested with the same bbox after a failure re-subscribes '
    'and can succeed on the second attempt',
    setUp: () {
      var callCount = 0;
      when(() => repository.watchSnapshot(bboxA)).thenAnswer((_) {
        callCount++;
        return callCount == 1
            ? Stream.error(const RepositoryException(NetworkFailure()))
            : Stream.value(snapshot);
      });
    },
    build: () => ActiveRegionBloc(repository),
    act: (bloc) async {
      bloc.add(const UpdateRegionRequested(bboxA));
      // Let the first attempt fully resolve before retrying.
      await Future<void>.delayed(Duration.zero);
      bloc.add(const UpdateRegionRequested(bboxA));
    },
    expect: () => [
      const ActiveRegionLoading(bboxA),
      const ActiveRegionError(bbox: bboxA, failure: NetworkFailure()),
      const ActiveRegionLoading(bboxA),
      ActiveRegionLoaded(bbox: bboxA, snapshot: snapshot),
    ],
    verify: (_) => verify(() => repository.watchSnapshot(bboxA)).called(2),
  );
}
