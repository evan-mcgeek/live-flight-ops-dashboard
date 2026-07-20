---
name: dart-build-runner-di-hot-restart-required
description: In Dart/Flutter projects using build_runner for code generation (e.g., injectable DI, json_serializable), hot reload does not re-run the generator; hot restart is required to apply DI/serialization changes.
---

## Pattern

When using `build_runner`-backed code generation in Dart/Flutter—dependency injection with `injectable`, serialization with `json_serializable`, or any similar tool—the generator runs during **build time**, not during hot reload.

**Hot reload** reloads only hand-written source files; it does not trigger `build_runner` and leaves the old generated code in memory.

**Hot restart** (stop/relaunch the app, or press capital **R** in the terminal during `flutter run`) performs a full rebuild, which re-runs `build_runner` and regenerates the config.

## When This Matters

- Constructor signatures in DI-injected classes change (parameters added/removed/reordered).
- DI provider methods are added, removed, or annotated differently.
- Serialization annotations (`@JsonSerializable`) change.
- Any change that drives the generator.

## Symptom

After editing code that affects generation—e.g., removing an unused dependency from a BLoC constructor—hot reload succeeds, but:
- The new code doesn't appear to work (because the old generated config is still loaded).
- DI failures or type mismatches occur at runtime.
- The app behaves as if the change never happened.

This is especially confusing because hand-written code changes *do* appear on hot reload, making it feel like code generation changes should too.

## Solution

Press **R** (capital R, not lowercase r) in the `flutter run` terminal to hot restart. This triggers a rebuild, re-running `build_runner`.

Alternatively, stop the process and relaunch: `flutter run`.

After a hot restart, the newly generated configs are in memory, and the app reflects the changes.

## Avoid the Trap

- Do not assume hot reload applies to all code changes.
- After editing a DI class (constructor, providers, annotations), do a hot restart, not a hot reload.
- Monitor `build_runner` output during the build to confirm generation ran.
