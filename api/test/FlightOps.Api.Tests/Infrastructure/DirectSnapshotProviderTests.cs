using FlightOps.Domain;
using FlightOps.Infrastructure.OpenSky;
using FlightOps.Infrastructure.Snapshots;
using NSubstitute;
using NUnit.Framework;

namespace FlightOps.Api.Tests.Infrastructure;

[TestFixture]
public class DirectSnapshotProviderTests
{
    [Test]
    public async Task GetSnapshotAsync_calls_the_client_on_every_invocation()
    {
        var bbox = new BoundingBox(1, 2, 3, 4);
        var aircraft = new List<Aircraft>
        {
            new("abc123", "TEST1", "Testland", 1, 2, 3, 4, 5, false, DateTimeOffset.UtcNow),
        };
        var client = Substitute.For<IOpenSkyClient>();
        client.GetStatesAsync(bbox, Arg.Any<CancellationToken>()).Returns(aircraft);
        var provider = new DirectSnapshotProvider(client);

        var first = await provider.GetSnapshotAsync(bbox, CancellationToken.None);
        var second = await provider.GetSnapshotAsync(bbox, CancellationToken.None);

        Assert.That(first.Aircraft, Is.EqualTo(aircraft));
        Assert.That(first.Stale, Is.False);
        Assert.That(second.Aircraft, Is.EqualTo(aircraft));
        await client.Received(2).GetStatesAsync(bbox, Arg.Any<CancellationToken>());
    }
}
