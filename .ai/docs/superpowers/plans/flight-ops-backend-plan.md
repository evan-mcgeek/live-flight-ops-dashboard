# Flight Ops Backend — Build Retrospective

**Goal:** a lightweight .NET 8 POC serving live aircraft data from the
OpenSky Network via REST + SignalR. See `../specs/flight-ops-backend-design.md`
for the current architecture; this doc is a condensed record of how it got
built, kept for reference rather than as a task-by-task instruction set.

## Global constraints carried through the build

- All projects target `net8.0`; solution root is `api/`.
- One test project (`test/FlightOps.Api.Tests`) — the Domain layer is thin
  enough that a second test project would be empty ceremony.
- `OpenSkySettings.ClientId`/`ClientSecret` come from a gitignored
  `appsettings.secrets.json`; `TokenUrl`/`ApiBaseUrl` are public and
  checked into `appsettings.json`.
- OpenSky tokens expire after 30 minutes; refresh-before-expiry via a
  `DelegatingHandler`.

## Build phases

1. **Scaffolding + domain models** — solution structure
   (Domain/Infrastructure/Api/test), `BoundingBox` and `Aircraft` as
   immutable records, `OpenSkyStateMapper` translating OpenSky's
   array-of-arrays state-vector format into `Aircraft`.
2. **OpenSky OAuth2 token provider** — `OpenSkyTokenClient` (raw token
   POST) + `OpenSkyTokenProvider` (`DelegatingHandler`, caches and
   refreshes the bearer token) matching OpenSky's own documented
   refresh-before-expiry pattern.
3. **`IOpenSkyClient`** — wraps a named `HttpClient` with the token
   handler attached; fetches and maps aircraft states for a bbox or a
   single ICAO24.
4. **Snapshot provider** — `IAircraftSnapshotProvider` introduced as a
   swappable-implementation interface. A `CachedSnapshotProvider`
   (grid-rounded bbox keys, TTL cache, stale-on-429 fallback) was
   originally built alongside `DirectSnapshotProvider` to manage OpenSky's
   daily quota, selectable via an `OpenSky:RateLimitAware` config flag —
   **later removed** once quota pressure turned out not to be a real
   constraint at this POC's traffic level; only `DirectSnapshotProvider` is
   registered today.
5. **DI wiring** (`Program.cs`) — typed `HttpClient` registrations, options
   binding, `AddExceptionHandler`/`AddProblemDetails`, Swagger in
   Development.
6. **Validation + exception handling** — `BoundingBoxRequestValidator`
   (FluentValidation) and `OpenSkyExceptionHandler` (`IExceptionHandler`)
   mapping upstream failures to `ProblemDetails`.
7. **`AircraftController`** — `GET /aircraft`, `GET /aircraft/{icao24}`.
8. **SignalR real-time path** — `AircraftHub` (per-connection bbox
   subscription, exact-bbox group keys, immediate snapshot as the RPC
   response), `ActiveBoundingBoxRegistry` (per-group broadcast clock),
   `AircraftBroadcastService` (a `BackgroundService` ticking every second,
   broadcasting to each due group independently).

## Notable deviations from the original plan

- **Rate-limit caching dropped.** The `CachedSnapshotProvider` +
  `OpenSky:RateLimitAware` toggle described in the original design were
  fully implemented, then removed once real usage showed OpenSky's daily
  quota wasn't actually a binding constraint — simplifying back down to a
  single direct provider rather than carrying unused complexity.
- **Client-controlled live interval added post-plan.** The original design
  had a fixed backend broadcast interval. The shipped version added a
  runtime-mutable `ILiveIntervalSettings`, adjustable per-request via an
  `X-Live-Interval-Seconds` header on `GET /aircraft` or a standalone
  `POST /aircraft/live-interval`, so the frontend's Settings screen can
  actually change the server's push cadence (1–120s) rather than it being
  a fixed value.

## Testing

`FlightOps.Api.Tests` (NUnit + NSubstitute) covers the bbox validator,
`DirectSnapshotProvider`, the OpenSky token client/provider's refresh
logic, the SignalR hub/registry/broadcast service, and a `Program.cs`
smoke test — spanning all three `src/` projects from one test project.
