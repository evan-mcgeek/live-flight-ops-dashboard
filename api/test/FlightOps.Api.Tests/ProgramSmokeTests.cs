using FlightOps.Infrastructure.Snapshots;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using NUnit.Framework;

namespace FlightOps.Api.Tests;

[TestFixture]
public class ProgramSmokeTests
{
    [Test]
    public async Task Resolves_direct_snapshot_provider()
    {
        await using var factory = new WebApplicationFactory<Program>();

        using var scope = factory.Services.CreateScope();
        var provider = scope.ServiceProvider.GetRequiredService<IAircraftSnapshotProvider>();

        Assert.That(provider, Is.InstanceOf<DirectSnapshotProvider>());
    }
}
