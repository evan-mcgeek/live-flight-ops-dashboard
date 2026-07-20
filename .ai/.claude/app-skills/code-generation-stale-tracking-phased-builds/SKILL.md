---
name: code-generation-stale-tracking-phased-builds
description: In multi-task builds where tasks incrementally add code-generation targets, track whether the generator has been re-run; stale generated configs cause runtime failures only when real code paths exercise them, not in unit tests with test doubles.
---

## Pattern

When a codebase phases implementation across multiple tasks and each task may add code-generation targets (e.g., `@injectable`, `@JsonSerializable`, `@GetIt` annotations), the generated artifacts (e.g., `injection.config.dart`, `*.g.dart`) can become stale if the code generator is not re-run after each task group adds new targets.

**Critical:** Stale generated files cause runtime failures *only* when real code exercises the generated paths. Unit tests that provide test doubles (mocks, fakes) will not catch missing registrations because they bypass DI entirely. This creates a false sense of passing tests masking broken production code.

## Detection

After a task group that adds new code-generation targets:
1. Re-run the code generator (e.g., `dart run build_runner build --delete-conflicting-outputs` for Flutter get_it/injectable).
2. Verify expected registrations are present by grepping the generated file for class names, scope modifiers (singleton, factory, factoryParam), and parameter types.

Example:
```bash
grep "SettingsBloc\|ActiveRegionBloc\|MapBloc\|AircraftListBloc\|AircraftDetailBloc" app/lib/core/di/injection.config.dart
```

Expected output pattern (verify scope):
```
gh.singleton<SettingsBloc>(...)
gh.singleton<ActiveRegionBloc>(...)
gh.factory<MapBloc>(...)
gh.factoryParam<AircraftDetailBloc, String, dynamic>(...)
```

## Prevention

- After tasks that add `@injectable` or `@singleton` annotations, run the generator.
- Include generator verification in task briefs: "Step 1: Regenerate DI config and verify all new Blocs are registered."
- Don't assume "the tests passed, so DI must be OK" — tests often bypass real DI by providing test doubles.

## Why it matters

Runtime failures in production (or integration tests that use real DI) are far more expensive to debug and fix than catching stale generation at development time. A missing registration only manifests when code calls `getIt<SomeBloc>()` in a real widget tree, hours or days after the task was completed.
