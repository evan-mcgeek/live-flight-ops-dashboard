import 'dart:async';

import 'package:flight_ops_app/data/remote/aircraft_remote_data_source.dart';
import 'package:flight_ops_app/data/repositories/aircraft_repository_impl.dart';
import 'package:flight_ops_app/data/signalr/aircraft_signalr_data_source.dart';
import 'package:flight_ops_app/domain/entities/aircraft_snapshot.dart';
import 'package:flight_ops_app/domain/entities/bounding_box.dart';
import 'package:flight_ops_app/domain/repositories/settings_repository.dart';
import 'package:flight_ops_app/domain/settings/live_update_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemoteDataSource extends Mock implements AircraftRemoteDataSource {}

class _MockSignalRDataSource extends Mock
    implements AircraftSignalRDataSource {}

class _FakeSettingsRepository implements SettingsRepository {
  LiveUpdateMode _mode = LiveUpdateMode.standard;
  final StreamController<LiveUpdateMode> _controller =
      StreamController<LiveUpdateMode>.broadcast();

  @override
  LiveUpdateMode get currentLiveUpdateMode => _mode;

  @override
  Stream<LiveUpdateMode> watchLiveUpdateMode() async* {
    yield _mode;
    yield* _controller.stream;
  }

  @override
  Future<void> setLiveUpdateMode(LiveUpdateMode mode) async {
    _mode = mode;
    _controller.add(mode);
  }

  @override
  ThemeMode get currentThemeMode => throw UnimplementedError();

  @override
  Stream<ThemeMode> watchThemeMode() => throw UnimplementedError();

  @override
  Future<void> setThemeMode(ThemeMode mode) => throw UnimplementedError();

  int liveInterval = 5;

  @override
  int get currentLiveInterval => liveInterval;

  @override
  Future<void> setLiveInterval(int seconds) => throw UnimplementedError();
}

void main() {
  const bbox = BoundingBox(laMin: 1, loMin: 2, laMax: 3, loMax: 4);
  final snapshotA = AircraftSnapshot(aircraft: const [], stale: false);
  final snapshotB = AircraftSnapshot(aircraft: const [], stale: true);

  late _MockRemoteDataSource remote;
  late _MockSignalRDataSource signalR;
  late _FakeSettingsRepository settings;
  late AircraftRepositoryImpl repository;

  setUp(() {
    remote = _MockRemoteDataSource();
    signalR = _MockSignalRDataSource();
    settings = _FakeSettingsRepository();
    repository = AircraftRepositoryImpl(
      remote: remote,
      signalR: signalR,
      settings: settings,
    );
  });

  test('watchSnapshot polls the remote data source in standard mode', () async {
    when(
      () => remote.fetchSnapshot(
        bbox,
        liveIntervalSeconds: any(named: 'liveIntervalSeconds'),
      ),
    ).thenAnswer((_) async => snapshotA);

    final first = await repository.watchSnapshot(bbox).first;

    expect(first, snapshotA);
    verify(
      () => remote.fetchSnapshot(
        bbox,
        liveIntervalSeconds: any(named: 'liveIntervalSeconds'),
      ),
    ).called(1);
    verifyNever(() => signalR.watchSnapshot(bbox, any()));
  });

  test('watchSnapshot uses the SignalR data source in realtime mode', () async {
    await settings.setLiveUpdateMode(LiveUpdateMode.realtime);
    when(
      () => signalR.watchSnapshot(bbox, any()),
    ).thenAnswer((_) => Stream.value(snapshotB));

    final first = await repository.watchSnapshot(bbox).first;

    expect(first, snapshotB);
    verify(() => signalR.watchSnapshot(bbox, any())).called(1);
    verifyNever(
      () => remote.fetchSnapshot(
        bbox,
        liveIntervalSeconds: any(named: 'liveIntervalSeconds'),
      ),
    );
  });

  test(
    'watchSnapshot switches transport when the mode changes mid-subscription',
    () async {
      when(
        () => remote.fetchSnapshot(
          bbox,
          liveIntervalSeconds: any(named: 'liveIntervalSeconds'),
        ),
      ).thenAnswer((_) async => snapshotA);
      when(
        () => signalR.watchSnapshot(bbox, any()),
      ).thenAnswer((_) => Stream.value(snapshotB));

      final emissions = <AircraftSnapshot>[];
      final subscription = repository.watchSnapshot(bbox).listen(emissions.add);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await settings.setLiveUpdateMode(LiveUpdateMode.realtime);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emissions, contains(snapshotA));
      expect(emissions, contains(snapshotB));
      await subscription.cancel();
    },
  );

  test(
    'watchSnapshot keeps polling after a fetch error instead of ending the stream',
    () async {
      settings.liveInterval = 0;
      var callCount = 0;
      when(
        () => remote.fetchSnapshot(
          bbox,
          liveIntervalSeconds: any(named: 'liveIntervalSeconds'),
        ),
      ).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('boom');
        return snapshotA;
      });

      final errors = <Object>[];
      final emissions = <AircraftSnapshot>[];
      final subscription = repository
          .watchSnapshot(bbox)
          .listen(emissions.add, onError: errors.add);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(errors, hasLength(1));
      expect(emissions, contains(snapshotA));
      await subscription.cancel();
    },
  );

  test('getDetail always calls the remote data source', () async {
    when(() => remote.fetchDetail('abc123')).thenAnswer((_) async => null);

    final result = await repository.getDetail('abc123');

    expect(result, isNull);
    verify(() => remote.fetchDetail('abc123')).called(1);
  });

  test('updateLiveInterval delegates to the remote data source', () async {
    when(() => remote.updateLiveInterval(30)).thenAnswer((_) async {});

    await repository.updateLiveInterval(30);

    verify(() => remote.updateLiveInterval(30)).called(1);
  });
}
