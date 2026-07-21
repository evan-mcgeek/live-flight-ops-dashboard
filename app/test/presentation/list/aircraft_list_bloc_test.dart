import 'package:bloc_test/bloc_test.dart';
import 'package:flight_ops_app/domain/entities/aircraft.dart';
import 'package:flight_ops_app/domain/entities/aircraft_snapshot.dart';
import 'package:flight_ops_app/domain/entities/bounding_box.dart';
import 'package:flight_ops_app/domain/failures/failure.dart';
import 'package:flight_ops_app/presentation/active_region/bloc/active_region_bloc.dart';
import 'package:flight_ops_app/presentation/list/bloc/aircraft_list_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockActiveRegionBloc
    extends MockBloc<ActiveRegionEvent, ActiveRegionState>
    implements ActiveRegionBloc {}

Aircraft _aircraft(String icao24, String callsign, String country) => Aircraft(
  icao24: icao24,
  callsign: callsign,
  originCountry: country,
  longitude: 0,
  latitude: 0,
  altitude: 0,
  velocity: 0,
  heading: 0,
  onGround: false,
  lastUpdate: DateTime.utc(2026, 1, 1),
);

void main() {
  const bbox = BoundingBox(laMin: 1, loMin: 2, laMax: 3, loMax: 4);

  late _MockActiveRegionBloc activeRegionBloc;

  setUp(() {
    activeRegionBloc = _MockActiveRegionBloc();
    when(() => activeRegionBloc.state).thenReturn(const ActiveRegionInitial());
    whenListen(activeRegionBloc, const Stream<ActiveRegionState>.empty());
  });

  blocTest<AircraftListBloc, AircraftListState>(
    'forwards ActiveRegionBloc snapshot updates into allAircraft and stale',
    build: () {
      final snapshot = AircraftSnapshot(
        aircraft: [
          _aircraft('a1', 'DLH1', 'Germany'),
          _aircraft('a2', 'BAW1', 'United Kingdom'),
        ],
        stale: true,
      );
      whenListen(
        activeRegionBloc,
        Stream.value(ActiveRegionLoaded(bbox: bbox, snapshot: snapshot)),
      );
      return AircraftListBloc(activeRegionBloc);
    },
    expect: () => [
      const AircraftListInitial(),
      isA<AircraftListLoaded>()
          .having((s) => s.allAircraft, 'allAircraft', hasLength(2))
          .having((s) => s.stale, 'stale', true),
    ],
  );

  blocTest<AircraftListBloc, AircraftListState>(
    'a region still loading (bbox known, no snapshot yet) maps to AircraftListLoading, not Loaded',
    build: () {
      whenListen(
        activeRegionBloc,
        Stream.value(const ActiveRegionLoading(bbox)),
      );
      return AircraftListBloc(activeRegionBloc);
    },
    expect: () => [const AircraftListInitial(), const AircraftListLoading()],
    verify: (bloc) => expect(bloc.state, isA<AircraftListLoading>()),
  );

  blocTest<AircraftListBloc, AircraftListState>(
    'failure applies even before any snapshot has ever arrived (first-fetch error)',
    build: () {
      whenListen(
        activeRegionBloc,
        Stream.value(
          const ActiveRegionError(bbox: bbox, failure: NetworkFailure()),
        ),
      );
      return AircraftListBloc(activeRegionBloc);
    },
    expect: () => [
      const AircraftListInitial(),
      const AircraftListError(failure: NetworkFailure()),
    ],
  );

  blocTest<AircraftListBloc, AircraftListState>(
    'a later failure-free update clears a previously-set failure',
    build: () {
      final snapshot = AircraftSnapshot(
        aircraft: [_aircraft('a1', 'DLH1', 'Germany')],
        stale: false,
      );
      whenListen(
        activeRegionBloc,
        Stream.fromIterable([
          const ActiveRegionError(bbox: bbox, failure: NetworkFailure()),
          ActiveRegionLoaded(bbox: bbox, snapshot: snapshot),
        ]),
      );
      return AircraftListBloc(activeRegionBloc);
    },
    expect: () => [
      const AircraftListInitial(),
      const AircraftListError(failure: NetworkFailure()),
      isA<AircraftListLoaded>().having(
        (s) => s.allAircraft,
        'allAircraft',
        hasLength(1),
      ),
    ],
  );

  blocTest<AircraftListBloc, AircraftListState>(
    'AircraftListSearchChanged filters visibleAircraft by callsign or country',
    build: () {
      final snapshot = AircraftSnapshot(
        aircraft: [
          _aircraft('a1', 'DLH1', 'Germany'),
          _aircraft('a2', 'BAW1', 'United Kingdom'),
        ],
        stale: false,
      );
      // whenListen (not seed:) — this bloc's constructor eagerly adds an event
      // from activeRegionBloc.state, which would clobber a seed: state.
      whenListen(
        activeRegionBloc,
        Stream.value(ActiveRegionLoaded(bbox: bbox, snapshot: snapshot)),
      );
      return AircraftListBloc(activeRegionBloc);
    },
    act: (bloc) async {
      // Lets the whenListen stream's relayed event land before the search
      // event, matching the real timing of a stream subscription vs a direct add().
      await Future<void>.delayed(Duration.zero);
      bloc.add(const AircraftListSearchChanged('dlh'));
    },
    expect: () => [
      const AircraftListInitial(),
      isA<AircraftListLoaded>()
          .having((s) => s.allAircraft, 'allAircraft', hasLength(2)),
      isA<AircraftListLoaded>().having((s) => s.query, 'query', 'dlh'),
    ],
    verify: (bloc) {
      final state = bloc.state as AircraftListLoaded;
      expect(state.visibleAircraft, hasLength(1));
      expect(state.visibleAircraft.first.callsign, 'DLH1');
    },
  );
}
