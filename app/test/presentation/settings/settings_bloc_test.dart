import 'package:bloc_test/bloc_test.dart';
import 'package:flight_ops_app/domain/entities/aircraft_snapshot.dart';
import 'package:flight_ops_app/domain/entities/bounding_box.dart';
import 'package:flight_ops_app/domain/failures/failure.dart';
import 'package:flight_ops_app/domain/repositories/settings_repository.dart';
import 'package:flight_ops_app/domain/settings/live_update_mode.dart';
import 'package:flight_ops_app/presentation/active_region/bloc/active_region_bloc.dart';
import 'package:flight_ops_app/presentation/settings/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

class _MockActiveRegionBloc
    extends MockBloc<ActiveRegionEvent, ActiveRegionState>
    implements ActiveRegionBloc {}

void main() {
  const bbox = BoundingBox(laMin: 1, loMin: 2, laMax: 3, loMax: 4);

  late _MockSettingsRepository repository;
  late _MockActiveRegionBloc activeRegionBloc;

  // The constructor seeds from activeRegionBloc.state immediately, so every
  // test's expect() list gets this leading state first (Bloc's dedup only
  // skips repeats from the second emit onward, not the first).
  const seedState = SettingsState(
    liveUpdateMode: LiveUpdateMode.standard,
    themeMode: ThemeMode.dark,
    liveInterval: 5,
  );

  setUp(() {
    repository = _MockSettingsRepository();
    when(
      () => repository.currentLiveUpdateMode,
    ).thenReturn(LiveUpdateMode.standard);
    when(() => repository.currentThemeMode).thenReturn(ThemeMode.dark);
    when(() => repository.currentLiveInterval).thenReturn(5);
    when(
      () => repository.watchLiveUpdateMode(),
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => repository.watchThemeMode(),
    ).thenAnswer((_) => const Stream.empty());

    activeRegionBloc = _MockActiveRegionBloc();
    when(() => activeRegionBloc.state).thenReturn(const ActiveRegionInitial());
    whenListen(activeRegionBloc, const Stream<ActiveRegionState>.empty());
  });

  blocTest<SettingsBloc, SettingsState>(
    'initial state reflects the repository\'s current values',
    build: () => SettingsBloc(repository, activeRegionBloc),
    verify: (bloc) {
      expect(
        bloc.state,
        const SettingsState(
          liveUpdateMode: LiveUpdateMode.standard,
          themeMode: ThemeMode.dark,
          liveInterval: 5,
        ),
      );
    },
  );

  blocTest<SettingsBloc, SettingsState>(
    'ThemeModeChanged calls the repository and emits the new theme',
    setUp: () => when(
      () => repository.setThemeMode(ThemeMode.light),
    ).thenAnswer((_) async {}),
    build: () => SettingsBloc(repository, activeRegionBloc),
    act: (bloc) => bloc.add(const ThemeModeChanged(ThemeMode.light)),
    expect: () => [
      seedState,
      const SettingsState(
        liveUpdateMode: LiveUpdateMode.standard,
        themeMode: ThemeMode.light,
        liveInterval: 5,
      ),
    ],
    verify: (_) =>
        verify(() => repository.setThemeMode(ThemeMode.light)).called(1),
  );

  group('SettingsRegionUpdated', () {
    blocTest<SettingsBloc, SettingsState>(
      'threads the connection status from the ActiveRegionBloc into SettingsState',
      build: () {
        whenListen(
          activeRegionBloc,
          Stream.value(
            const ActiveRegionError(bbox: bbox, failure: NetworkFailure()),
          ),
        );
        return SettingsBloc(repository, activeRegionBloc);
      },
      expect: () => [
        seedState,
        const SettingsState(
          liveUpdateMode: LiveUpdateMode.standard,
          themeMode: ThemeMode.dark,
          liveInterval: 5,
          connectionStatus: ConnectionError(NetworkFailure()),
        ),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'a later update with no failure clears a previously-set error',
      build: () {
        final snapshot = AircraftSnapshot(aircraft: const [], stale: false);
        whenListen(
          activeRegionBloc,
          Stream.fromIterable([
            const ActiveRegionError(bbox: bbox, failure: NetworkFailure()),
            ActiveRegionLoaded(bbox: bbox, snapshot: snapshot),
          ]),
        );
        return SettingsBloc(repository, activeRegionBloc);
      },
      expect: () => [
        seedState,
        const SettingsState(
          liveUpdateMode: LiveUpdateMode.standard,
          themeMode: ThemeMode.dark,
          liveInterval: 5,
          connectionStatus: ConnectionError(NetworkFailure()),
        ),
        const SettingsState(
          liveUpdateMode: LiveUpdateMode.standard,
          themeMode: ThemeMode.dark,
          liveInterval: 5,
          connectionStatus: ConnectionConnected(),
        ),
      ],
      verify: (bloc) =>
          expect(bloc.state.connectionStatus, isA<ConnectionConnected>()),
    );
  });
}
