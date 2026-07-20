import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../../core/config/api_config.dart';
import '../../domain/entities/aircraft_snapshot.dart';
import '../../domain/entities/bounding_box.dart';
import '../remote/dto/aircraft_snapshot_dto.dart';

// Standalone function so the mapping is testable without a live hub connection.
AircraftSnapshot parseAircraftUpdateArguments(List<Object?>? arguments) {
  if (arguments == null || arguments.isEmpty) {
    throw const FormatException('AircraftUpdate arrived with no payload');
  }
  return AircraftSnapshotDto.fromJson(
    arguments.first! as Map<String, dynamic>,
  ).toDomain();
}

@lazySingleton
class AircraftSignalRDataSource {
  AircraftSignalRDataSource(@Named(hubUrlToken) this._hubUrl);

  static const _aircraftUpdateEvent = 'AircraftUpdate';
  static const _subscribeMethod = 'Subscribe';
  static const _retryDelay = Duration(seconds: 3);

  final String _hubUrl;
  Future<HubConnection>? _connecting;
  final StreamController<AircraftSnapshot> _updates =
      StreamController<AircraftSnapshot>.broadcast();

  // Re-sent to Subscribe on reconnect — a new SignalR connection ID drops the server-side bbox registration.
  BoundingBox? _lastBbox;

  // `??=` shares one in-flight connection across concurrent callers.
  Future<HubConnection> _ensureConnected() => _connecting ??= _connect();

  Future<HubConnection> _connect() async {
    final connection = HubConnectionBuilder()
        .withUrl(_hubUrl)
        .withAutomaticReconnect()
        .build();
    connection.on(_aircraftUpdateEvent, (arguments) {
      _updates.add(parseAircraftUpdateArguments(arguments));
    });
    connection.onreconnected(({connectionId}) {
      final bbox = _lastBbox;
      if (bbox == null) return;
      connection
          .invoke(
            _subscribeMethod,
            args: <Object>[bbox.laMin, bbox.loMin, bbox.laMax, bbox.loMax],
          )
          .then((result) {
            if (result is Map<String, dynamic>) {
              _updates.add(AircraftSnapshotDto.fromJson(result).toDomain());
            }
          })
          .catchError((_) => null);
    });
    try {
      await connection.start();
    } catch (_) {
      _connecting = null; // let the next watchSnapshot retry a fresh connection
      rethrow;
    }
    return connection;
  }

  // Retries on failure and reports via onError instead of rethrow (which would kill this stream forever).
  Stream<AircraftSnapshot> watchSnapshot(
    BoundingBox bbox,
    void Function(Object error) onError,
  ) async* {
    _lastBbox = bbox;
    while (true) {
      try {
        final connection = await _ensureConnected();
        // Subscribe returns the first snapshot as its RPC response, not a separate
        // push, which would race the broadcast listener attached below.
        final result = await connection.invoke(
          _subscribeMethod,
          args: <Object>[bbox.laMin, bbox.loMin, bbox.laMax, bbox.loMax],
        );
        if (result is Map<String, dynamic>) {
          yield AircraftSnapshotDto.fromJson(result).toDomain();
        }
        yield* _updates.stream;
        return;
      } catch (e) {
        _connecting = null;
        onError(e);
        await Future<void>.delayed(_retryDelay);
      }
    }
  }
}
