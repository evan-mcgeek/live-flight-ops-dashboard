# Live Flight Ops Dashboard — Frontend Design

**Scope:** `app/` only. Consumes the `api/` backend (REST `GET /aircraft`,
`GET /aircraft/{icao24}`, `POST /aircraft/live-interval`, and SignalR hub
`/hubs/aircraft`).

## Purpose

A Flutter mobile app (iOS + Android) showing live aircraft over a map,
letting the user browse/search the same data as a list, and viewing detail
on a single aircraft.

## Tech stack

- **State management:** `flutter_bloc`, sealed-class states per feature —
  each bloc lives in its own `bloc/` folder using Dart's `part`/`part of`
  file-splitting (`x_bloc.dart` declaring `part 'x_event.dart'` and
  `part 'x_state.dart'`).
- **DI:** `get_it` + `injectable`, code-generated via `build_runner`.
- **Routing:** `go_router`, with a `StatefulShellRoute` for the bottom-nav tabs.
- **Map:** `flutter_map` (OpenStreetMap tiles, no API key).
- **REST client:** a small hand-written `dio` client — with the SignalR
  side necessarily hand-written (no codegen tooling exists for it), the
  REST side stays hand-written too rather than mixing generated and manual
  networking code for two endpoints.
- **Real-time:** `signalr_netcore`, connecting to `/hubs/aircraft`.
- **Local persistence:** `shared_preferences`, for live-update mode, theme,
  and the polling interval.
- **Target:** mobile only (iOS + Android). No Flutter Web target.

## Architecture

`core/` (DI, routing, theme) / `domain/` (entities, repository interfaces,
failures) / `data/` (repository implementations, REST + SignalR data
sources, DTOs) / `presentation/` — one folder per feature
(`active_region`, `map`, `list`, `detail`, `settings`, `shell`, `splash`),
each with its own `bloc/` and, where the feature has extracted private
widgets, a `widgets/` subfolder.

- **Domain entities:** `Aircraft`, `AircraftSnapshot`, `BoundingBox` —
  immutable, value-equatable.
- **`AircraftRepository`:** `Stream<AircraftSnapshot> watchSnapshot(bbox)`
  (transparently sourced from REST polling or SignalR push depending on
  the live-update mode setting), `Future<Aircraft?> getDetail(icao24)`
  (always REST), `Future<void> updateLiveInterval(seconds)` (retunes the
  backend's global SignalR broadcast interval).
- **Shared active region:** `ActiveRegionBloc`, a singleton the whole app
  shares. It owns the current bounding box and its live snapshot stream —
  restarting the subscription on each region change and retaining the
  last-good snapshot across errors (as `staleSnapshot` on its sealed
  `Error` state). `MapBloc`, `AircraftListBloc`, and `SettingsBloc` each
  subscribe to its stream and derive their own state from it; only
  `MapBloc` writes region changes back (on debounced pan/zoom). This is
  what lets Map and List be peer routes without either owning the other or
  duplicating the live subscription.

## Visual design

Mockups (`.ai/design/Flight Ops Mockups.dc.html`) drive a fully
custom-styled theme (not default Material/Cupertino) shared across both
platforms.

- **Typography:** Barlow for UI text/labels, IBM Plex Mono for all data
  values (callsigns, coordinates, altitude/velocity, timestamps).
- **Themes:** dark (default) and light, toggleable in Settings. Color
  roles (`AppColors`, a `ThemeExtension`): `canvas`/`background` (page),
  `panel`/`panel2` (card surfaces), `line`/`line2` (borders),
  `textPrimary`/`textSecondary`/`textTertiary`, `accent` (teal —
  live/airborne), `ground`/`stale` (amber — on-ground aircraft and
  stale-data warnings share this color), `danger` (red, error states),
  `scrim` (overlay dimming).
- **Iconography:** a single rotated aircraft glyph (two-layer SVG — a
  fixed-color outline behind a dynamically-tinted fill) reused as map
  markers and list-row leading icons.
- **Bottom navigation:** a floating pill-shaped nav bar (Map/List/Settings);
  Detail pushes on top with a back button instead.

### Map view

Full-bleed `flutter_map`. A pill-shaped status chip top-center shows a
pulsing "Live" dot and aircraft count, morphing between loading/live/error
via `AnimatedSize` + `AnimatedSwitcher`. Zoom +/− and a recenter button
float on the right edge. Aircraft render as rotated plane-icon markers,
sorted by ascending altitude so higher aircraft paint on top; tapping one
selects it (brighter outline) and opens the detail view in a bottom sheet.

Between polls, marker positions are smoothed rather than jumping: in
**Standard** mode, a marker interpolates between its last two confirmed
reports (eased, eases into the new position roughly over one poll
interval, then falls back to dead reckoning if the next poll runs late);
in **Real-time** mode, a marker dead-reckons forward continuously from its
last reported position/velocity/heading, correcting toward each new report
over a duration scaled to the aircraft's own speed so a correction never
looks faster than the plane is actually flying. Both modes project
corrections onto the aircraft's own heading line, so a correction never
visibly moves it sideways or backward.

### List/Search view

Header shows the result count and a live-refresh spinner during
in-flight region refetches. A search field filters the list live (by
callsign or origin country, case-insensitive). A stale-data banner appears
when the active snapshot's `stale` flag is true. Each row: heading-rotated
aircraft icon, monospace callsign, origin country, right-aligned
altitude/AIR-GND readout. Empty state: "No aircraft in this area."

### Aircraft Detail view

Callsign (large, monospace) beside an Airborne/On-ground pill, origin
country subtitle, and a self-ticking "Updated Ns ago" freshness indicator
(blinking dot). Two side-by-side data cards: Altitude (with a flight-level
subtext, e.g. "FL380 · baro") and Velocity (knots-converted subtext, e.g.
"≈ 482 kt") — both computed client-side from the raw meter/m-per-second
values. A full-width Heading card follows. Below that, a plain record list:
ICAO24, origin country, on-ground, position, last update (local time).

### Settings view

- **Live updates:** a segmented control, **Standard / Real-time**, with an
  explanatory sentence that changes per selection. A slider sets the
  polling interval (1/2/5/10/30/60/120s, Standard mode only) — mode and
  interval are staged locally and only applied (persisted + app restart)
  on an explicit Save.
- **Appearance:** the dark/light theme segmented control.
- **Data source** (read-only): connection status (connecting/connected/error,
  derived from `ActiveRegionBloc`'s stream) and the current snapshot
  interval ("Ns poll" in Standard mode, "push · live" in Real-time mode).

## Navigation

`go_router` with a `StatefulShellRoute` for Map/List/Settings as peer
tabs, plus `/detail/:icao24` pushed on top of either.

## Error handling

Repository methods surface failures as a sealed `Failure` type
(`NetworkFailure`/`ServerFailure`/`NotFoundFailure`/`UnknownFailure`)
rather than throwing raw Dio/SignalR exceptions. Blocs map a `Failure`
into their own sealed error state, always carrying forward the last
good data as `staleSnapshot`/`staleAircraft` where applicable so the UI
never has to lose what it was already showing. The backend's base URL is
a single build-time `--dart-define=API_BASE_URL` config, not per-platform
branches.

## Testing

`bloc_test` for each bloc (given a repository/upstream-bloc state
sequence, assert the emitted state sequence), unit tests for
repository/data-source/DTO mapping logic, and one widget test
(`app_bootstrap_test.dart`) verifying the app boots without crashing.
