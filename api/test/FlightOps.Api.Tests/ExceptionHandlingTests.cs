using System.Net;
using FlightOps.Domain;
using FlightOps.Infrastructure.OpenSky;
using FlightOps.Infrastructure.Snapshots;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using NSubstitute;
using NUnit.Framework;

namespace FlightOps.Api.Tests;

[TestFixture]
public class ExceptionHandlingTests
{
    [Test]
    public async Task Returns_503_when_rate_limited_snapshot_provider_throws()
    {
        var snapshotProvider = Substitute.For<IAircraftSnapshotProvider>();
        snapshotProvider
            .GetSnapshotAsync(Arg.Any<BoundingBox>(), Arg.Any<CancellationToken>())
            .Returns<AircraftSnapshot>(_ => throw new OpenSkyRateLimitedException());

        await using var factory = new WebApplicationFactory<Program>().WithWebHostBuilder(builder =>
        {
            builder.ConfigureServices(services =>
            {
                services.RemoveAll<IAircraftSnapshotProvider>();
                services.AddSingleton(snapshotProvider);
            });
        });
        using var client = factory.CreateClient();

        var response = await client.GetAsync("/aircraft?lamin=10&lomin=10&lamax=20&lomax=20");

        Assert.That(response.StatusCode, Is.EqualTo(HttpStatusCode.ServiceUnavailable));
    }
}
