using FlightOps.Domain;
using FlightOps.Infrastructure.OpenSky;

namespace FlightOps.Infrastructure.Snapshots;

public sealed class DirectSnapshotProvider(IOpenSkyClient client) : IAircraftSnapshotProvider
{
    public async Task<AircraftSnapshot> GetSnapshotAsync(
        BoundingBox bbox,
        CancellationToken cancellationToken
    )
    {
        var aircraft = await client.GetStatesAsync(bbox, cancellationToken);
        return new AircraftSnapshot(aircraft, Stale: false);
    }
}
