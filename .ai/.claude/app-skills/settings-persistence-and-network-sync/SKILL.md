---
name: settings-persistence-and-network-sync
description: Three-legged sync for app settings that drive backend behavior — persist locally, notify the backend on the next app boot (not immediately), and include the current value on every relevant request.
---

When an app setting controls server-side behavior (e.g., the SignalR
broadcast interval), implement **three sync legs** to ensure durability,
notification, and eventual consistency — but leg 2 doesn't have to fire
immediately from a settings-change event; it can validly ride along with
an app restart the setting already requires for other reasons.

## The three legs (as actually wired in this app)

1. **Persist locally** — `LiveUpdatesBlock` (a stateful settings widget)
   stages the pending mode/interval locally, and on Save writes it via
   `SettingsRepository.setLiveUpdateMode`/`setLiveInterval`
   (SharedPreferences-backed) *before* triggering a restart:
   ```dart
   Future<void> _save(BuildContext context) async {
     final repository = getIt<SettingsRepository>();
     await repository.setLiveUpdateMode(_pendingMode);
     await repository.setLiveInterval(_pendingInterval);
     if (!context.mounted) return;
     await RestartWidget.restartApp(context);
   }
   ```
2. **Notify the backend — deferred to the next app boot, not fired
   immediately.** There is no settings-change event that calls the
   backend synchronously. `main.dart`'s `_notifyBackendOfPersistedInterval()`
   runs once at every app start *and* every `RestartWidget.restartApp()`
   (which the Save button above always triggers), reading the
   just-persisted interval and POSTing it:
   ```dart
   void _notifyBackendOfPersistedInterval() {
     final seconds = getIt<SettingsRepository>().currentLiveInterval;
     getIt<AircraftRepository>().updateLiveInterval(seconds)
       .catchError((e) => debugPrint('updateLiveInterval($seconds) failed: $e'));
   }
   ```
   This works *because* changing this particular setting already requires
   a restart for other reasons (DI container rebuild) — the notification
   piggybacks on that restart rather than needing its own live network
   call wired into a bloc event.
3. **Include on every relevant request** — every REST poll attaches the
   current interval as a header, so the server stays in sync even between
   restarts (e.g. after a server restart resets its own state):
   ```dart
   Future<AircraftSnapshot> fetchSnapshot(BoundingBox bbox, {required int liveIntervalSeconds}) {
     return _dio.get(ApiConfig.aircraftPath, options: Options(
       headers: {'X-Live-Interval-Seconds': liveIntervalSeconds.toString()},
     ));
   }
   ```
   `AircraftRemoteDataSource.updateLiveInterval(seconds)` (leg 2's actual
   call) POSTs the same header to a dedicated `/aircraft/live-interval`
   endpoint.

## Why three legs

- **Persistence**: preference survives app restart.
- **Notification**: the server updates promptly even in SignalR-only
  mode, which never polls REST and so would otherwise never carry the
  header.
- **Eventual consistency**: any REST poll re-sends the header regardless,
  so a server restart or a missed notification self-corrects on the next
  poll rather than requiring a dedicated retry mechanism.

## Validation

Both the app (`AircraftRemoteDataSource.allowedLiveIntervalSeconds`) and
the backend (`AircraftController.AllowedLiveIntervalSeconds`) must agree
on the exact allowed set (`1, 2, 5, 10, 30, 60, 120`) — this is duplicated
by necessity (no shared contract layer between the two projects) and
flagged with a "must stay in sync" comment on both sides.

## Related

`dart-build-runner-di-hot-restart-required` — the reason leg 2 can safely
ride along with a restart is that this specific setting already forces
one (a DI container rebuild); a future setting that doesn't need a
restart would need its own trigger for leg 2, not this piggyback trick.
