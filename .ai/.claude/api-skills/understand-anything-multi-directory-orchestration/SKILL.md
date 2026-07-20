---
name: understand-anything-multi-directory-orchestration
description: Analyze independent subdirectories in a monorepo by dispatching parallel project-scanner subagents for each, then merging outputs at root into .ai/.
---

# understand-anything multi-directory orchestration

Analyze independent subdirectories (app/, api/, etc.) in a monorepo-like structure by dispatching parallel project-scanner subagents for each, then merging outputs at the project root into `.ai/understand-anything/`.

## Pattern

When the project has multiple independent codebases (e.g., Flutter frontend + .NET backend):

1. **Configure `.understandignore` per subdirectory** — each gets its own ignore file, tuned to that subsystem's build artifacts and scaffolding.
   - Example (Flutter): exclude `/ios/`, `/android/`, `/windows/`, `/linux/`, `/macos/`, `/web/` (generated native shells).
   - Example (.NET): exclude `*/bin/*`, `*/obj/*` (build output).

2. **Dispatch parallel subagents** — use `Agent` tool with `subagent_type: "understand-anything:project-scanner"` for each subdirectory. Subagents run in parallel, avoiding sequential bottleneck.

3. **Merge outputs at root** — after all subagents complete, run a root-level `/understand` that combines subdomain graphs. Configure `PROJECT_ROOT` to the repo root and let the tool discover both `.understand-anything/intermediate/` results.

4. **Output to `.ai/` folder** — final merged knowledge graph lives in `.ai/understand-anything/`, per `ai-output-directory-convention`.

## Rationale

- **Parallelism**: N subagent scans run concurrently instead of sequentially, reducing wall-clock time.
- **Isolation**: Each subsystem's ignore rules and analysis scope are independent; changes to app/ ignore rules don't affect api/.
- **Completeness**: Each subsystem gets its own full knowledge graph before merge, capturing domain-specific patterns.
- **Clarity**: Task tracking (via TaskCreate) keeps the multi-phase pipeline visible and resumable.

## Configuration example

For `app/.understand-anything/.understandignore`:
```
# Platform scaffolding (Flutter-generated native shells, not app logic)
/ios/
/android/
/windows/
/linux/
/macos/
/web/
```

For `api/.understand-anything/.understandignore`:
```
*/bin/
*/obj/
*.lock
```