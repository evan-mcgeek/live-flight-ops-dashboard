import '../entities/aircraft.dart';
import '../entities/aircraft_snapshot.dart';
import '../entities/bounding_box.dart';

abstract interface class AircraftRepository {
  // Sourced from REST polling or SignalR push depending on the live-update mode setting; switches transport transparently.
  Stream<AircraftSnapshot> watchSnapshot(BoundingBox bbox);

  // Always via REST regardless of live-update mode. Null if not currently tracked.
  Future<Aircraft?> getDetail(String icao24);

  // Retunes the backend's SignalR broadcast interval — a global, server-wide
  // value, not scoped to this app instance.
  Future<void> updateLiveInterval(int seconds);
}
