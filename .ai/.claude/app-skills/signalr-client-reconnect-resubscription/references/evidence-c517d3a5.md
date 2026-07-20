connection.onreconnected(({connectionId}) {
      final bbox = _lastBbox;
      if (bbox == null) return;
      connection
          .invoke(_subscribeMethod, args: <Object>[bbox.laMin, bbox.loMin, bbox.laMax, bbox.loMax])
          .catchError((_) => null);
    });

// Explanation from trace: "the server hands a reconnected client a brand-new SignalR connection ID, so the backend's per-connection bbox-group registration (ActiveBoundingBoxRegistry) does NOT survive a reconnect. Without resending Subscribe from `onreconnected`, the app would silently stop receiving pushes after any network blip even though the transport itself recovered."