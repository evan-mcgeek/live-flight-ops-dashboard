# Flight Ops Frontend — Build Retrospective

**Goal:** a Flutter mobile app showing live aircraft on a map, in a
searchable list, and in detail, backed by the `api/` project. See
`../specs/flight-ops-frontend-design.md` for the current architecture;
this doc is a condensed record of how it got built, kept for reference
rather than as a task-by-task instruction set.

## Global constraints carried through the build

- Flutter 3.38.x / Dart `>=3.10.0 <4.0.0`.
- `core/domain/data/presentation` layering, one Bloc per feature.
- Backend base URL is a build-time constant
  (`String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:5273')`),
  not a runtime platform branch.
- Repository/data-source failures surface as a sealed `Failure` type
  carried by a `RepositoryException`, never as raw `DioException`/SignalR
  exceptions escaping the data layer.
- Design tokens (colors, typography) come from
  `.ai/design/Flight Ops Mockups.dc.html` — dark theme default, both
  themes supported via a `ThemeExtension`.

## Build phases

1. **Scaffolding** — Flutter project setup, pinned dependency versions
   (several combinations needed downgrading to actually resolve together —
   `injectable`/`injectable_generator` off the 3.x line, `latlong2` pinned
   for `flutter_map` compatibility).
2. **Domain layer** — `Aircraft`, `BoundingBox`, `AircraftSnapshot`
   entities; a sealed `Failure` hierarchy; `LiveUpdateMode` enum;
   `AircraftRepository`/`SettingsRepository` interfaces.
3. **Data layer** — `AircraftDto`/`AircraftSnapshotDto` (`json_serializable`),
   `AircraftRemoteDataSource` (REST via `dio`), `AircraftSignalRDataSource`
   (`signalr_netcore`), `SettingsRepositoryImpl` (`shared_preferences`),
   `AircraftRepositoryImpl` switching REST-polling vs. SignalR-push
   transparently based on the live-update mode setting.
4. **DI wiring** — `get_it` + `injectable`, code-generated.
5. **Theme & design tokens** — `AppColors` (`ThemeExtension`), typography
   (Barlow + IBM Plex Mono via `google_fonts`).
6. **Shared state** — `ActiveRegionBloc`, the single upstream bloc every
   feature bloc derives from.
7. **Feature blocs + screens** — Map, List/Search, Detail, Settings, each
   with its own bloc and page.
8. **Shell + navigation** — `AppShell` (bottom nav) + `go_router`.
9. **Bootstrap** — `main.dart`, DI container setup, app restart mechanism
   for settings that require one.

## Notable deviations from the original plan

- **Marker clustering never shipped.** `flutter_map_marker_cluster` was
  pinned in the original dependency list, but the clustering behavior it
  would've enabled was never built — the map renders individual markers
  directly, sorted by ascending altitude so higher aircraft paint on top.
- **`ActiveRegionCubit` became `ActiveRegionBloc`.** The original design
  called it a Cubit; it shipped as a full Bloc (event-driven, restartable
  transformer on region-change events) to match the rest of the app's
  event/state pattern rather than mixing Cubit and Bloc styles.
- **Fixed 5-second polling became a configurable slider.** The original
  design fixed the Standard-mode REST polling interval at 5 seconds. The
  shipped Settings screen exposes a slider (1/2/5/10/30/60/120s) that also
  retunes the backend's SignalR broadcast interval via
  `AircraftRepository.updateLiveInterval` — the interval is genuinely
  adjustable, not just displayed.
- **Dead-reckoning/interpolation animation added post-plan.** Not present
  in the original design at all: markers now smoothly interpolate between
  polls (Standard mode) or continuously dead-reckon from reported
  velocity/heading (Real-time mode), with corrections projected onto the
  aircraft's own heading line so they never visibly move it sideways or
  backward. This became one of the largest pieces of logic in the app.
- **Post-launch bloc restructuring.** After the app was functionally
  complete, all five blocs (`ActiveRegionBloc`, `MapBloc`,
  `AircraftListBloc`, `SettingsBloc`, `AircraftDetailBloc`) were converted
  from flat state classes with boolean flags to sealed-class state
  hierarchies (`Initial`/`Loading`/`Loaded`/`Error`, pattern-matched via
  `switch`), each split into `bloc/`-folder `part`/`part of` files. Error
  states carry the last-good data forward (`staleSnapshot`/`staleAircraft`)
  instead of the earlier `hasReceivedData=true && failure!=null` combo.
  Large private widget classes were also extracted into per-feature
  `widgets/` subfolders in the same pass.

## Testing

`bloc_test` for every bloc (given an upstream state/event sequence, assert
the emitted state sequence), unit tests (`mocktail` fakes) for
repository/data-source/DTO mapping, and one widget test
(`app_bootstrap_test.dart`) verifying the app boots end-to-end against a
faked repository. No broader `integration_test` suite — matches the
design's stated POC testing scope.
