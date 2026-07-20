---
name: signalr-subscribe-rpc-response-race-elimination
description: Eliminate client-ready race conditions in SignalR subscriptions by returning initial snapshot as RPC response instead of relying on subsequent push.
---

## Problem

When a client calls a SignalR hub method to subscribe (e.g., `Subscribe(subscription)`), there is a temporal window between the method returning and the client being ready to receive pushed messages. The sequence is:

1. Client calls `Subscribe(sub)` on the hub.
2. Server processes the subscription and broadcasts first data via `Clients.Group(...).SendAsync("Update", data)`.
3. Server method returns.
4. Client receives the RPC return.
5. Client registers the push-message handler for "Update".

If the server broadcasts in step 2 before the client registers its handler in step 5, the message is dropped silently. The client remains in a stale or blank state until the next push arrives (seconds or minutes later), creating the impression that the subscription is not working or is slow to initialize.

This race is particularly damaging for subscriptions that drive UI state (aircraft positions, status counts, refresh badges) where dropped initial data leaves the UI empty or stale.

## Solution

Have the Subscribe method return the initial snapshot directly as the RPC response, eliminating the intermediate broadcast window. Subsequent updates still arrive via push.

**Server side** (C# / .NET Hub):

```csharp
public async Task<SnapshotDto> Subscribe(Subscription sub)
{
    // Fetch initial snapshot
    var snapshot = await _provider.GetSnapshotAsync(sub);
    
    // Register for future updates (push will work now)
    var groupKey = GetGroupKey(sub);
    await Groups.AddToGroupAsync(Context.ConnectionId, groupKey);
    
    // Return initial snapshot directly — no intermediate broadcast
    return snapshot;
}
```

**Client side** (Dart / Flutter):

```dart
final snapshot = await hub.invoke<SnapshotDto>('Subscribe', args: [subscription]);
// snapshot is immediately available; safe to update UI
state = snapshot;

// Register push handler for future updates
hub.on('Update', (data) {
  state = data;
});
```

The client receives the initial data as the method return value, not as a push. Subsequent updates arrive via the push handler once the client is fully set up.

## Outcome

- Initial snapshot is guaranteed to reach the client; no dropped data.
- No stale-state window where the UI is blank pending the next broadcast.
- Faster perceived initialization because data is available immediately.
- Subsequent broadcasts (incremental updates) continue to work as expected.

Particularly critical for real-time applications where the user's first view of the screen must show current data, not wait for the next scheduled push.
