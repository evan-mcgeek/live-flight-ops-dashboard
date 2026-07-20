using FlightOps.Domain;
using FlightOps.Infrastructure.Snapshots;
using Microsoft.AspNetCore.SignalR;

namespace FlightOps.Api.Hubs;

public sealed class AircraftHub(
    IActiveBoundingBoxRegistry registry,
    IAircraftSnapshotProvider snapshotProvider
) : Hub
{
    // No grid rounding — groups/queries by the exact viewport bbox.
    public async Task<AircraftSnapshot> Subscribe(
        double laMin,
        double loMin,
        double laMax,
        double loMax
    )
    {
        var bbox = new BoundingBox(laMin, loMin, laMax, loMax);
        var groupName = GroupName(bbox.LaMin, bbox.LoMin, bbox.LaMax, bbox.LoMax);

        registry.Register(Context.ConnectionId, groupName, bbox);
        await Groups.AddToGroupAsync(Context.ConnectionId, groupName);

        // Returned as the RPC's own response — a separate push here would race the client's broadcast listener.
        return await snapshotProvider.GetSnapshotAsync(bbox, Context.ConnectionAborted);
    }

    public override Task OnDisconnectedAsync(Exception? exception)
    {
        registry.Unregister(Context.ConnectionId);
        return base.OnDisconnectedAsync(exception);
    }

    public static string GroupName(double laMin, double loMin, double laMax, double loMax) =>
        $"bbox:{laMin:F2}_{loMin:F2}_{laMax:F2}_{loMax:F2}";
}
