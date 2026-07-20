# Live Flight Ops Dashboard — Backend API

A lightweight .NET 8 POC backend that fetches live aircraft state from the
OpenSky Network REST API for a caller-supplied bounding box, and serves it
via REST endpoints and a SignalR push hub, for the companion Flutter app
(see `../app/`).

## Project layout

Deliberately lightweight 3-project layering — no persistence/EF/GraphQL:

- **`FlightOps.Domain`** — zero-dependency models (`Aircraft`, `BoundingBox`)
- **`FlightOps.Infrastructure`** — OpenSky OAuth2 token client/provider, REST
  client, snapshot providers
- **`FlightOps.Api`** — controllers, the SignalR hub + background broadcast
  service, request validation, exception-handling middleware, `Program.cs`

## API credentials

`src/FlightOps.Api/appsettings.secrets.json` holds an OpenSky Network OAuth2
client id/secret and is gitignored. Create it locally with:

```json
{
  "OpenSkySettings": {
    "ClientId": "<your-opensky-client-id>",
    "ClientSecret": "<your-opensky-client-secret>"
  }
}
```

Register a client at the [OpenSky Network](https://opensky-network.org/)
to obtain these values.

## Running

```bash
cd src/FlightOps.Api
dotnet run
```

Listens on `http://localhost:5273` by default (Swagger UI at `/swagger`).

## Testing

```bash
dotnet test
```

## `.ai/` — where everything AI-related lives

This repo keeps all AI-produced and AI-tooling content in one place at
`../.ai/` (repo root), not scattered per-project. If you're an agent
picking up work here, look there first:

- `../.ai/.understand-anything/` — knowledge graphs (architecture layers,
  file relationships, a guided tour) for the app, for this API, and a
  merged graph covering both. Browse interactively with
  `/understand-dashboard ..` (from repo root; resolves source file content
  correctly for both `app/` and `api/`).
- `../.ai/.claude/app-skills/` and `../.ai/.claude/api-skills/` — project-specific
  lessons/conventions learned while building the app and this API
  (previously auto-discovered from `.claude/skills/` in each project; now
  archived here for reference — see the root README for why).
- `../.ai/docs/superpowers/{plans,specs}/` — the original design specs and
  build plans/retrospectives for both the app and this API.
- `../.ai/design/` — visual mockups that drove the app's screens (not
  directly relevant to this API, but part of the same project record).

See the root README (`../README.md`) for the full picture, including which
Claude Code plugins were used to build this project.
