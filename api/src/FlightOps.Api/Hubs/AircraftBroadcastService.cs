using FlightOps.Domain;
using FlightOps.Infrastructure.Configuration;
using FlightOps.Infrastructure.Snapshots;
using Microsoft.AspNetCore.SignalR;

namespace FlightOps.Api.Hubs;

public sealed class AircraftBroadcastService(
    IHubContext<AircraftHub> hubContext,
    IAircraftSnapshotProvider snapshotProvider,
    IActiveBoundingBoxRegistry registry,
    ILiveIntervalSettings liveIntervalSettings
) : BackgroundService
{
    // Ticks every second so a mid-wait interval change applies next tick, not after a stale delay.
    private static readonly TimeSpan Tick = TimeSpan.FromSeconds(1);

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await Task.Delay(Tick, stoppingToken);
            }
            catch (OperationCanceledException)
            {
                return;
            }

            // Each group has its own clock — a region change never resets another group's wait.
            foreach (var (groupName, bbox) in registry.ActiveGroups)
            {
                if (!registry.IsDue(groupName, liveIntervalSettings.Interval))
                    continue;

                await BroadcastToGroupAsync(groupName, bbox, stoppingToken);
                registry.MarkBroadcast(groupName);
            }
        }
    }

    public async Task BroadcastOnceAsync(CancellationToken cancellationToken)
    {
        foreach (var (groupName, bbox) in registry.ActiveGroups)
        {
            await BroadcastToGroupAsync(groupName, bbox, cancellationToken);
        }
    }

    private async Task BroadcastToGroupAsync(
        string groupName,
        BoundingBox bbox,
        CancellationToken cancellationToken
    )
    {
        var snapshot = await snapshotProvider.GetSnapshotAsync(bbox, cancellationToken);
        await hubContext
            .Clients.Group(groupName)
            .SendAsync("AircraftUpdate", snapshot, cancellationToken);
    }
}
