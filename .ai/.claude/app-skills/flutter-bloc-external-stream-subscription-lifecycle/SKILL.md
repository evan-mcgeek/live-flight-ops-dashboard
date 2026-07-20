---
name: flutter-bloc-external-stream-subscription-lifecycle
description: Safely subscribe a Bloc to external bloc streams by forwarding via internal events and canceling subscriptions in close(), ensuring proper cleanup when using BlocProvider's create constructor.
---

## Pattern

When a Bloc needs to consume another Bloc's output (e.g., `MapBloc`
listening to `ActiveRegionBloc`), follow this three-part lifecycle. Below
is the actual current shape (sealed states, inline handlers) — the
underlying three steps matter more than this exact syntax:

**1. Subscribe in constructor, sync current state immediately, forward
future updates via an internal event:**

```dart
class MapBloc extends Bloc<MapEvent, MapState> {
  MapBloc(this._activeRegionBloc) : super(const MapInitial()) {
    on<MapActiveRegionUpdated>((event, emit) {
      // ... translate ActiveRegionState into MapState ...
    });

    // Sync the parent bloc's CURRENT state immediately — don't wait for its next emission.
    add(MapActiveRegionUpdated(_activeRegionBloc.state));
    // Forward all future emissions the same way.
    _subscription = _activeRegionBloc.stream.listen((regionState) => add(MapActiveRegionUpdated(regionState)));
  }

  final ActiveRegionBloc _activeRegionBloc;
  late final StreamSubscription<ActiveRegionState> _subscription;
```

**2. Override close() to cancel the subscription:**

```dart
  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
```

**3. Use BlocProvider's `create:` constructor (not `.value`) to auto-dispose:**

```dart
BlocProvider(
  create: (_) => getIt<MapBloc>(),  // Auto-disposes: calls bloc.close() on page exit
  child: MapPage(),
);
```

**NOT** `BlocProvider.value` — that constructor does not auto-dispose.

## Why this pattern

- Avoids StreamSubscription leaks when the page is popped.
- Internal event forwarding keeps Bloc logic testable and event-driven (no hidden stream logic in test setup).
- `create:` constructor auto-calls `close()` per flutter_bloc source, triggering the subscription cancellation.

## Verification checklist

1. **Subscribe in constructor** — not in `on<>` event handlers (which may not be called early enough).
2. **Sync current state immediately** — `add(...(_activeRegionBloc.state))` right after subscribing, so this bloc doesn't start blank waiting for the parent's next emission.
3. **Forward via internal event** — keep the Bloc's event stream as the single source of state changes.
4. **Override close()** — verify `_subscription.cancel()` is called before `super.close()`.
5. **Test for leaks** — ensure `blocTest` disposes the Bloc and no warnings appear; check that subscription is cancelled when the Bloc closes.
6. **Use `create:` constructor** — never use `BlocProvider.value` for Blocs that manage their own resources.
