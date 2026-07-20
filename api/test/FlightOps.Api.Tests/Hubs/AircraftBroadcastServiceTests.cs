using FlightOps.Api.Hubs;
using FlightOps.Domain;
using FlightOps.Infrastructure.Configuration;
using FlightOps.Infrastructure.Snapshots;
using Microsoft.AspNetCore.SignalR;
using NSubstitute;
using NUnit.Framework;

namespace FlightOps.Api.Tests.Hubs;

[TestFixture]
public class AircraftBroadcastServiceTests
{
    [Test]
    public async Task BroadcastOnceAsync_sends_snapshot_to_each_registered_group()
    {
        var hubContext = Substitute.For<IHubContext<AircraftHub>>();
        var hubClients = Substitute.For<IHubClients>();
        var clientProxy = Substitute.For<IClientProxy>();
        hubContext.Clients.Returns(hubClients);
        hubClients.Group(Arg.Any<string>()).Returns(clientProxy);

        var bbox = new BoundingBox(10, 10, 20, 20);
        var registry = new ActiveBoundingBoxRegistry();
        registry.Register("conn-1", "bbox:10.00_10.00_20.00_20.00", bbox);

        var snapshot = new AircraftSnapshot([], Stale: false);
        var snapshotProvider = Substitute.For<IAircraftSnapshotProvider>();
        snapshotProvider.GetSnapshotAsync(bbox, Arg.Any<CancellationToken>()).Returns(snapshot);

        var service = new AircraftBroadcastService(
            hubContext,
            snapshotProvider,
            registry,
            new LiveIntervalSettings(TimeSpan.FromSeconds(5))
        );

        await service.BroadcastOnceAsync(CancellationToken.None);

        hubClients.Received(1).Group("bbox:10.00_10.00_20.00_20.00");
        await clientProxy
            .Received(1)
            .SendCoreAsync(
                "AircraftUpdate",
                Arg.Is<object[]>(args =>
                    args != null && args.Length == 1 && Equals(args[0], snapshot)
                ),
                Arg.Any<CancellationToken>()
            );
    }
}
