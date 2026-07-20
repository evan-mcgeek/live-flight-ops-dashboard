using FlightOps.Domain;

namespace FlightOps.Infrastructure.Snapshots;

public interface IAircraftSnapshotProvider
{
    Task<AircraftSnapshot> GetSnapshotAsync(BoundingBox bbox, CancellationToken cancellationToken);
}
