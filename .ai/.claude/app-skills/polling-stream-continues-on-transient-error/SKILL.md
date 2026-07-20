---
name: polling-stream-continues-on-transient-error
description: In polling-based data streams, emit error state on fetch failure but do not break the stream; allow the next poll cycle to attempt recovery and self-correct.
---

## Pattern

When a data source is polled at regular intervals (e.g., every 5 seconds), transient network or service errors are common. The correct behavior is to emit an error state (so consumers know to show an offline/error indicator) **but continue polling**. This allows recovery without requiring the caller to manually retry or reinitialize the stream.

### Wrong

```dart
Stream<SnapshotState> watchSnapshot(Duration interval) async* {
  while (true) {
    try {
      final data = await remote.fetch();
      yield SuccessState(data);
    } catch (e) {
      yield ErrorState(e);
      return; // ❌ BREAKS THE STREAM — no more polls happen
    }
    await Future.delayed(interval);
  }
}
```

### Right

```dart
Stream<SnapshotState> watchSnapshot(Duration interval) async* {
  while (true) {
    try {
      final data = await remote.fetch();
      yield SuccessState(data);
    } catch (e) {
      yield ErrorState(e);
      // ✓ Fall through — loop continues, next poll will retry
    }
    await Future.delayed(interval);
  }
}
```

## Why

- **Transient errors are recoverable**: Network hiccups, temporary service unavailability, and rate-limit 429s often resolve within the next interval.
- **Caller expectations**: Consumers treating the stream as "long-lived polling" expect the stream to keep running unless explicitly canceled.
- **State self-correction**: The next successful poll automatically clears the error state without caller intervention.

## Tests

Verify that:
- Error emissions don't halt polling (e.g., check that the 5th poll succeeds after a 3rd-poll error).
- The stream remains open and responsive after an error.
- Multiple errors in a row don't break the loop.

## Related

See `external-service-error-handling-fail-loud` for patterns on whether to propagate errors; this skill is about *keeping the stream alive* after an error, not about loudness.
