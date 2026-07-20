---
name: signalr-client-reconnect-resubscription
description: In SignalR client connections, automatic reconnect recovers the transport but not server-side subscription state; re-invoke subscription methods in the onreconnected handler
---

## Pattern

When a SignalR client connection drops and reconnects via `withAutomaticReconnect()`, the underlying WebSocket/transport recovers, but the server assigns a new connection ID. Server-side state keyed to the old connection ID (group registrations, subscriptions, active filters) is lost.

**Problem:** After a brief network hiccup, the client transport reconnects silently, but the app stops receiving data because the server no longer has the client registered in the subscription group.

**Solution:** 

1. **Track subscription parameters** — store the last subscription arguments (e.g., bounding box, filters) in an instance field.
2. **Register a reconnected handler** — `connection.onreconnected(({connectionId}) { ... })` fires after transport recovers.
3. **Re-invoke subscription** — call the server method that registers the client with the subscription group again, passing the tracked parameters.
4. **Handle transient re-subscription failures** — wrap the re-subscription in `.catchError((_) => null)` or similar to prevent stream termination if the re-subscribe fails; the next reconnect will try again.

## Code pattern

```dart
class MySignalRDataSource {
  // Track the last subscription parameters
  SubscriptionParams? _lastParams;

  Future<HubConnection> _connect() async {
    final connection = HubConnectionBuilder()
        .withUrl(hubUrl)
        .withAutomaticReconnect()  // Essential: enables reconnection
        .build();

    connection.on('DataUpdate', (args) {
      // Handle incoming data
    });

    // Hook the reconnected event
    connection.onreconnected(({connectionId}) {
      final params = _lastParams;
      if (params == null) return;  // Not yet subscribed
      
      // Re-invoke the subscription method to re-register with the server
      connection
          .invoke('Subscribe', args: [params.arg1, params.arg2])
          .catchError((_) => null);  // Swallow transient failures; next reconnect will retry
    });

    await connection.start();
    return connection;
  }

  Stream<MyData> watch(SubscriptionParams params) async* {
    _lastParams = params;  // Remember for reconnect
    final connection = await _ensureConnected();
    
    // Initial subscription
    await connection.invoke('Subscribe', args: [params.arg1, params.arg2]);
    
    // Yield updates from the hub
    yield* _updates.stream;
  }
}
```

## When to apply

- Client-side SignalR subscriptions where subscription state is keyed to connection identity (groups, broadcast channels, active filters).
- Any real-time feature that must survive brief network interruptions (mobile, poor connectivity, simulator hiccups).

## What this does NOT cover

- Server-side broadcasting to many clients (covered by `signalr-background-broadcast-pattern`).
- Graceful shutdown via cancellation tokens (use `PeriodicTimer` with token support).
- General polling-stream error recovery (covered by `polling-stream-continues-on-transient-error`).

