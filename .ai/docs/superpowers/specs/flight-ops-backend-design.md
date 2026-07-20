# Live Flight Ops Dashboard — Backend Design

**Scope:** `api/` only.

## Purpose

A POC REST + real-time API serving live aircraft data (callsign, origin
country, position, altitude, velocity, heading, on-ground status, last
update time) for a caller-supplied bounding box, sourced from the
[OpenSky Network REST API](https://openskynetwork.github.io/opensky-api/rest.html).
Consumed by the Flutter frontend (`app/`) for a map view, a list/search
view, and an aircraft detail view.

## Repo layout

```
api/
├── src/
│   ├── FlightOps.Domain/          # Aircraft, BoundingBox — zero dependencies
│   ├── FlightOps.Infrastructure/  # OpenSky client + OAuth2 token provider, snapshot provider, settings
│   └── FlightOps.Api/             # Controllers, SignalR hub, Program.cs, middleware
└── test/
    └── FlightOps.Api.Tests/       # NUnit + NSubstitute, covers all three src projects
```

A lightweight layered POC convention — no persistence, no EF, no GraphQL.
Hosting is plain ASP.NET Core on Kestrel; the SignalR broadcast loop needs
a long-lived process to run in.

## OpenSky integration

- **Auth:** OAuth2 client-credentials flow. `OpenSkyTokenClient` posts to
  OpenSky's token endpoint; `OpenSkyTokenProvider` (a `DelegatingHandler`)
  caches the bearer token in memory and refreshes it before expiry
  (`TokenSettings.RefreshMargin`), attached to `IOpenSkyClient`'s
  `HttpClient` via `AddHttpMessageHandler`.
- **Settings:** `OpenSkySettings` (`TokenUrl`, `ApiBaseUrl`) live in the
  checked-in `appsettings.json`. `ClientId`/`ClientSecret` are sensitive —
  sourced from a gitignored `appsettings.secrets.json` in `FlightOps.Api`.
- **Client:** `IOpenSkyClient` calls `GET {ApiBaseUrl}/states/all` and
  `/states/all?icao24=` (single-aircraft detail), mapping OpenSky's raw
  array-of-arrays response into `Aircraft` domain models via
  `OpenSkyStateMapper`.

## Snapshot provider

`IAircraftSnapshotProvider` sits between the controller/hub and
`IOpenSkyClient` — currently one implementation, `DirectSnapshotProvider`,
calling straight through with no caching layer. The interface exists so an
alternative (e.g. a rate-limit-aware cached provider) could be swapped in
later without touching callers, but nothing beyond the direct pass-through
is built or needed at this POC's scale.

## Endpoints

- `GET /aircraft?lamin=&lomin=&lamax=&lomax=` — via `IAircraftSnapshotProvider`;
  backs both the map and list/search views. An optional
  `X-Live-Interval-Seconds` request header (one of `1,2,5,10,30,60,120`)
  updates the global SignalR broadcast interval as a side effect.
- `POST /aircraft/live-interval` — same header-driven interval update,
  standalone (used when the app changes the setting without an in-flight
  region fetch).
- `GET /aircraft/{icao24}` — single-aircraft detail, direct OpenSky call
  keyed on ICAO24 (6-hex-char, validated via regex).
- SignalR hub `/hubs/aircraft` — `Subscribe(laMin, loMin, laMax, loMax)`
  joins a group keyed by the exact bbox (no grid rounding), returns an
  immediate snapshot as the RPC response, and registers the connection in
  `IActiveBoundingBoxRegistry`. `AircraftBroadcastService` (a
  `BackgroundService`) ticks every second, and for each group whose
  per-group clock has reached the current global interval
  (`ILiveIntervalSettings`, seeded from `Broadcast:Interval` in
  `appsettings.json`, runtime-mutable via the endpoints above), broadcasts
  a fresh snapshot as `AircraftUpdate` and resets that group's clock. Each
  group's timer is independent — one region's interval change or broadcast
  never resets another's.

## Validation & error handling

- FluentValidation (`BoundingBoxRequestValidator`) validates the bbox query
  params (all four required, `lamin < lamax`, `lomin < lomax`), surfaced as
  a `ValidationProblem`.
- `OpenSkyExceptionHandler` (`IExceptionHandler`) maps upstream failures
  (rate limiting, network errors) to `ProblemDetails` responses.

## Testing

One test project, `FlightOps.Api.Tests` (NUnit + NSubstitute), covering the
bbox validator, `DirectSnapshotProvider`, the token client/provider's
refresh logic, the SignalR hub/registry/broadcast service, and a
`Program.cs` smoke test.
