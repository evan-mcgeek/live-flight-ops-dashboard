import 'package:bloc_test/bloc_test.dart';
import 'package:flight_ops_app/domain/entities/aircraft_snapshot.dart';
import 'package:flight_ops_app/domain/entities/bounding_box.dart';
import 'package:flight_ops_app/domain/failures/failure.dart';
import 'package:flight_ops_app/presentation/active_region/bloc/active_region_bloc.dart';
import 'package:flight_ops_app/presentation/map/bloc/map_bloc.dart'
    hide MapEvent;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockActiveRegionBloc
    extends MockBloc<ActiveRegionEvent, ActiveRegionState>
    implements ActiveRegionBloc {}

void main() {
  const bbox = BoundingBox(laMin: 1, loMin: 2, laMax: 3, loMax: 4);
  final snapshot = AircraftSnapshot(aircraft: const [], stale: false);

  late _MockActiveRegionBloc activeRegionBloc;

  setUp(() {
    activeRegionBloc = _MockActiveRegionBloc();
    when(() => activeRegionBloc.state).thenReturn(const ActiveRegionInitial());
    whenListen(activeRegionBloc, const Stream<ActiveRegionState>.empty());
  });

  blocTest<MapBloc, MapState>(
    'MapViewportChanged adds UpdateRegionRequested to the ActiveRegionBloc',
    build: () => MapBloc(activeRegionBloc),
    act: (bloc) => bloc.add(const MapViewportChanged(bbox)),
    verify: (_) => verify(
      () => activeRegionBloc.add(const UpdateRegionRequested(bbox)),
    ).called(1),
  );

  blocTest<MapBloc, MapState>(
    'MapMarkerSelected updates selectedIcao24 once the state is loaded',
    build: () {
      whenListen(
        activeRegionBloc,
        Stream.value(ActiveRegionLoaded(bbox: bbox, snapshot: snapshot)),
      );
      return MapBloc(activeRegionBloc);
    },
    act: (bloc) async {
      await Future<void>.delayed(Duration.zero);
      bloc.add(const MapMarkerSelected('abc123'));
    },
    expect: () => [
      const MapInitial(),
      MapLoaded(snapshot: snapshot),
      MapLoaded(snapshot: snapshot, selectedIcao24: 'abc123'),
    ],
  );

  blocTest<MapBloc, MapState>(
    'MapMarkerSelected is a no-op before any data has loaded',
    build: () => MapBloc(activeRegionBloc),
    act: (bloc) => bloc.add(const MapMarkerSelected('abc123')),
    expect: () => [const MapInitial()],
  );

  blocTest<MapBloc, MapState>(
    'forwards ActiveRegionBloc snapshot updates into MapState',
    build: () {
      whenListen(
        activeRegionBloc,
        Stream.value(ActiveRegionLoaded(bbox: bbox, snapshot: snapshot)),
      );
      return MapBloc(activeRegionBloc);
    },
    expect: () => [const MapInitial(), MapLoaded(snapshot: snapshot)],
  );

  blocTest<MapBloc, MapState>(
    'a later failure-free update clears a previously-set failure',
    build: () {
      whenListen(
        activeRegionBloc,
        Stream.fromIterable([
          const ActiveRegionError(bbox: bbox, failure: NetworkFailure()),
          ActiveRegionLoaded(bbox: bbox, snapshot: snapshot),
        ]),
      );
      return MapBloc(activeRegionBloc);
    },
    expect: () => [
      const MapInitial(),
      const MapError(failure: NetworkFailure()),
      MapLoaded(snapshot: snapshot),
    ],
  );

  blocTest<MapBloc, MapState>(
    'a failure with no snapshot yet stays an Error state, never Loaded',
    build: () {
      whenListen(
        activeRegionBloc,
        Stream.value(
          const ActiveRegionError(bbox: bbox, failure: NetworkFailure()),
        ),
      );
      return MapBloc(activeRegionBloc);
    },
    expect: () => [
      const MapInitial(),
      const MapError(failure: NetworkFailure()),
    ],
    verify: (bloc) => expect(bloc.state, isA<MapError>()),
  );
}
