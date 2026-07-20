using FlightOps.Api.Hubs;
using FlightOps.Domain;
using FlightOps.Infrastructure.Snapshots;
using Microsoft.AspNetCore.SignalR;
using NSubstitute;
using NUnit.Framework;

namespace FlightOps.Api.Tests.Hubs;

[TestFixture]
public class AircraftHubTests
{
    [Test]
    public void GroupName_formats_bbox_to_two_decimal_places()
    {
        var name = AircraftHub.GroupName(10.1, 20.25, 30.5, 40.75);

        Assert.That(name, Is.EqualTo("bbox:10.10_20.25_30.50_40.75"));
    }

    [Test]
    public async Task Subscribe_registers_and_groups_by_the_exact_bbox_without_rounding()
    {
        var registry = new ActiveBoundingBoxRegistry();
        var snapshot = new AircraftSnapshot([], Stale: false);
        var snapshotProvider = Substitute.For<IAircraftSnapshotProvider>();
        snapshotProvider
            .GetSnapshotAsync(Arg.Any<BoundingBox>(), Arg.Any<CancellationToken>())
            .Returns(snapshot);
        var hub = new AircraftHub(registry, snapshotProvider);
        var context = Substitute.For<HubCallerContext>();
        context.ConnectionId.Returns("conn-1");
        var groups = Substitute.For<IGroupManager>();
        hub.Context = context;
        hub.Groups = groups;

        var result = await hub.Subscribe(laMin: 11, loMin: 21, laMax: 19, loMax: 29);

        const string expectedGroupName = "bbox:11.00_21.00_19.00_29.00";
        Assert.That(
            registry.ActiveGroups[expectedGroupName],
            Is.EqualTo(new BoundingBox(11, 21, 19, 29))
        );
        await groups
            .Received(1)
            .AddToGroupAsync("conn-1", expectedGroupName, Arg.Any<CancellationToken>());
        Assert.That(result, Is.EqualTo(snapshot));
    }

    [Test]
    public async Task OnDisconnectedAsync_unregisters_the_connection()
    {
        var registry = Substitute.For<IActiveBoundingBoxRegistry>();
        var snapshotProvider = Substitute.For<IAircraftSnapshotProvider>();
        var hub = new AircraftHub(registry, snapshotProvider);
        var context = Substitute.For<HubCallerContext>();
        context.ConnectionId.Returns("conn-1");
        hub.Context = context;

        await hub.OnDisconnectedAsync(null);

        registry.Received(1).Unregister("conn-1");
    }
}
