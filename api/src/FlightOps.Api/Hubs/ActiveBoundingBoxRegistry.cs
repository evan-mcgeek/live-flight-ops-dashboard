using System.Collections.Concurrent;
using FlightOps.Domain;

namespace FlightOps.Api.Hubs;

public interface IActiveBoundingBoxRegistry
{
    void Register(string connectionId, string groupName, BoundingBox bbox);

    void Unregister(string connectionId);

    // Per-group broadcast clock — a region change or broadcast resets only that group's own timer.
    void MarkBroadcast(string groupName);

    bool IsDue(string groupName, TimeSpan interval);

    IReadOnlyDictionary<string, BoundingBox> ActiveGroups { get; }
}

public sealed class ActiveBoundingBoxRegistry : IActiveBoundingBoxRegistry
{
    private readonly ConcurrentDictionary<string, BoundingBox> _groups = new();
    private readonly ConcurrentDictionary<string, string> _connectionGroups = new();
    private readonly ConcurrentDictionary<string, int> _groupSubscriberCounts = new();
    private readonly ConcurrentDictionary<string, DateTime> _lastBroadcastUtc = new();

    public void Register(string connectionId, string groupName, BoundingBox bbox)
    {
        Unregister(connectionId);

        _groups[groupName] = bbox;
        _connectionGroups[connectionId] = groupName;
        _groupSubscriberCounts.AddOrUpdate(groupName, 1, (_, count) => count + 1);
        // The hub pushes this group a snapshot immediately on subscribe — start its clock now.
        _lastBroadcastUtc[groupName] = DateTime.UtcNow;
    }

    public void Unregister(string connectionId)
    {
        if (!_connectionGroups.TryRemove(connectionId, out var groupName))
        {
            return;
        }

        var remaining = _groupSubscriberCounts.AddOrUpdate(groupName, 0, (_, count) => count - 1);
        if (remaining <= 0)
        {
            _groupSubscriberCounts.TryRemove(groupName, out _);
            _groups.TryRemove(groupName, out _);
            _lastBroadcastUtc.TryRemove(groupName, out _);
        }
    }

    public void MarkBroadcast(string groupName) => _lastBroadcastUtc[groupName] = DateTime.UtcNow;

    public bool IsDue(string groupName, TimeSpan interval) =>
        !_lastBroadcastUtc.TryGetValue(groupName, out var last)
        || DateTime.UtcNow - last >= interval;

    public IReadOnlyDictionary<string, BoundingBox> ActiveGroups => _groups;
}
