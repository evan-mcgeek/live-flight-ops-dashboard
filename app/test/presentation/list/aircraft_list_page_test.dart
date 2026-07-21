import 'package:bloc_test/bloc_test.dart';
import 'package:flight_ops_app/core/di/injection.dart';
import 'package:flight_ops_app/core/theme/app_theme.dart';
import 'package:flight_ops_app/domain/entities/aircraft.dart';
import 'package:flight_ops_app/domain/failures/failure.dart';
import 'package:flight_ops_app/presentation/list/aircraft_list_page.dart';
import 'package:flight_ops_app/presentation/list/bloc/aircraft_list_bloc.dart';
import 'package:flight_ops_app/presentation/list/widgets/stale_data_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAircraftListBloc
    extends MockBloc<AircraftListEvent, AircraftListState>
    implements AircraftListBloc {}

Aircraft _aircraft(String icao24) => Aircraft(
  icao24: icao24,
  callsign: 'TEST1',
  originCountry: 'Testland',
  longitude: 1,
  latitude: 2,
  altitude: 3,
  velocity: 4,
  heading: 5,
  onGround: false,
  lastUpdate: DateTime(2026, 1, 1),
);

void main() {
  late _MockAircraftListBloc bloc;

  setUp(() {
    bloc = _MockAircraftListBloc();
    getIt.registerFactory<AircraftListBloc>(() => bloc);
  });

  tearDown(() => getIt.unregister<AircraftListBloc>());

  testWidgets('shows the stale data banner when the loaded state is stale', (
    tester,
  ) async {
    whenListen(
      bloc,
      const Stream<AircraftListState>.empty(),
      initialState: AircraftListLoaded(
        allAircraft: [_aircraft('abc123')],
        stale: true,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.darkTheme, home: const AircraftListPage()),
    );

    expect(find.byType(StaleDataBanner), findsOneWidget);
  });

  testWidgets(
    'does not show the stale data banner when the loaded state is fresh',
    (tester) async {
      whenListen(
        bloc,
        const Stream<AircraftListState>.empty(),
        initialState: AircraftListLoaded(
          allAircraft: [_aircraft('abc123')],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AircraftListPage(),
        ),
      );

      expect(find.byType(StaleDataBanner), findsNothing);
    },
  );

  testWidgets('tapping retry dispatches AircraftListRetryRequested', (
    tester,
  ) async {
    whenListen(
      bloc,
      const Stream<AircraftListState>.empty(),
      initialState: const AircraftListError(failure: NetworkFailure()),
    );

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.darkTheme, home: const AircraftListPage()),
    );
    await tester.tap(find.text('Try again'));

    verify(() => bloc.add(const AircraftListRetryRequested())).called(1);
  });
}
