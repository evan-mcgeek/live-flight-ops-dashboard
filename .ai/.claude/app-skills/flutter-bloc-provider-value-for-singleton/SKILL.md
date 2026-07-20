---
name: flutter-bloc-provider-value-for-singleton
description: For Blocs that are @singleton-scoped and shared app-wide, wrap them in BlocProvider.value() not BlocProvider(create:); the latter auto-disposes on page pop, destroying shared state for all consumers.
---

## Pattern

When a Bloc is registered as `@singleton` in your DI container (via get_it + injectable) and accessed from multiple screens (e.g., `SettingsBloc` providing theme and live-update-mode toggles), use `BlocProvider.value()` to provide it to widgets:

```dart
BlocProvider.value(
  value: getIt<SettingsBloc>(),
  child: const _SettingsView(),
)
```

**Do not** use `BlocProvider(create:)`:

```dart
// Wrong for singleton-scoped Blocs
BlocProvider(
  create: (context) => getIt<SettingsBloc>(),
  child: const _SettingsView(),
)
```

## Why

`BlocProvider(create:)` registers the provided Bloc with a `dispose` lifecycle managed by the provider. When the widget tree pops that provider (e.g., user navigates away from the screen), the Bloc is auto-disposed. If other screens depend on that same Bloc (it's singleton-scoped), disposing it breaks downstream consumers.

`BlocProvider.value()` does not auto-dispose; it only holds a reference. The Bloc's lifecycle is managed by the DI container (`@singleton` scope), not by the provider.

## Signal

- Bloc is annotated `@singleton` in the domain/presentation layer.
- Multiple screens access the same Bloc instance via `getIt<BlocType>()`.
- Changes to the Bloc's state must be visible across all screens without re-initialization.
