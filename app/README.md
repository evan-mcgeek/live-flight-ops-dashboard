# Live Flight Ops Dashboard — Mobile Frontend

A Flutter app showing live aircraft positions on a map and in a searchable
list, backed by a companion .NET REST/SignalR API (see `../api/`).

## Stack

- **State management:** `flutter_bloc`, one bloc per feature, deriving from a
  shared `ActiveRegionBloc` that owns the current viewport's live data stream
- **Navigation:** `go_router`
- **Map:** `flutter_map`
- **DI:** `get_it` + `injectable` (codegen)
- **Networking:** `dio` (REST) and `signalr_netcore` (real-time push)

## Setup

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

The codegen step regenerates `*.g.dart` DTOs and `injection.config.dart` —
re-run it after changing any `@JsonSerializable`/`@injectable` class.

## Running

```bash
flutter run
```

By default the app points at `http://localhost:5273`, matching the API's
default local port. To point at a different host:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5273
```

## Testing

```bash
flutter test
```

## `.ai/` — where everything AI-related lives

This repo keeps all AI-produced and AI-tooling content in one place at
`../.ai/` (repo root), not scattered per-project. If you're an agent
picking up work here, look there first:

- `../.ai/.understand-anything/` — knowledge graphs (architecture layers,
  file relationships, a guided tour) for this app, for the API, and a
  merged graph covering both. Browse interactively with
  `/understand-dashboard ..` (from repo root; resolves source file content
  correctly for both `app/` and `api/`).
- `../.ai/.claude/app-skills/` and `../.ai/.claude/api-skills/` — project-specific
  lessons/conventions learned while building this app and the API
  (previously auto-discovered from `.claude/skills/` in each project; now
  archived here for reference — see the root README for why).
- `../.ai/docs/superpowers/{plans,specs}/` — the original design specs and
  build plans/retrospectives for both the app and the API.
- `../.ai/design/` — visual mockups (`Flight Ops Mockups.dc.html`,
  `ios-frame.jsx`) that drove this app's theme and screen layouts.

See the root README (`../README.md`) for the full picture, including which
Claude Code plugins were used to build this project.
