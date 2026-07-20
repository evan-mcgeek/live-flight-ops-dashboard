import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../domain/entities/aircraft.dart';
import '../../domain/entities/aircraft_snapshot.dart';
import '../../domain/entities/bounding_box.dart';
import '../../domain/repositories/aircraft_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/settings/live_update_mode.dart';
import '../remote/aircraft_remote_data_source.dart';
import '../signalr/aircraft_signalr_data_source.dart';

@LazySingleton(as: AircraftRepository)
class AircraftRepositoryImpl implements AircraftRepository {
  AircraftRepositoryImpl({
    required AircraftRemoteDataSource remote,
    required AircraftSignalRDataSource signalR,
    required SettingsRepository settings,
  }) : _remote = remote,
       _signalR = signalR,
       _settings = settings;

  final AircraftRemoteDataSource _remote;
  final AircraftSignalRDataSource _signalR;
  final SettingsRepository _settings;

  @override
  Stream<AircraftSnapshot> watchSnapshot(BoundingBox bbox) {
    // Not asyncExpand: it wouldn't observe a mode change mid-poll.
    late StreamController<AircraftSnapshot> controller;
    StreamSubscription<LiveUpdateMode>? modeSubscription;
    StreamSubscription<AircraftSnapshot>? innerSubscription;
    // Guards a fetch still in flight when its subscription is cancelled.
    var cancelled = false;

    void switchTo(LiveUpdateMode mode) {
      innerSubscription?.cancel();
      final innerStream = mode == LiveUpdateMode.standard
          ? _pollSnapshot(bbox, () => cancelled, controller.addError)
          : _signalR.watchSnapshot(bbox, controller.addError);
      innerSubscription = innerStream.listen(
        controller.add,
        onError: controller.addError,
      );
    }

    controller = StreamController<AircraftSnapshot>(
      onListen: () {
        modeSubscription = _settings.watchLiveUpdateMode().listen(switchTo);
      },
      // Fire-and-forget: awaiting would stall cancellation.
      onCancel: () {
        cancelled = true;
        modeSubscription?.cancel();
        innerSubscription?.cancel();
      },
    );

    return controller.stream;
  }

  // ponytail: a rethrow here would kill this async* generator's stream permanently — forward via onError instead.
  Stream<AircraftSnapshot> _pollSnapshot(
    BoundingBox bbox,
    bool Function() isCancelled,
    void Function(Object error) onError,
  ) async* {
    while (!isCancelled()) {
      try {
        final snapshot = await _remote.fetchSnapshot(
          bbox,
          liveIntervalSeconds: _settings.currentLiveInterval,
        );
        if (isCancelled()) return;
        yield snapshot;
      } catch (e) {
        if (isCancelled()) return;
        onError(e);
      }
      await Future<void>.delayed(
        Duration(seconds: _settings.currentLiveInterval),
      );
    }
  }

  @override
  Future<Aircraft?> getDetail(String icao24) => _remote.fetchDetail(icao24);

  @override
  Future<void> updateLiveInterval(int seconds) =>
      _remote.updateLiveInterval(seconds);
}
