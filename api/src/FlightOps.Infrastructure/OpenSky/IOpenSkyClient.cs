using FlightOps.Domain;

namespace FlightOps.Infrastructure.OpenSky;

public interface IOpenSkyClient
{
    Task<IReadOnlyList<Aircraft>> GetStatesAsync(
        BoundingBox bbox,
        CancellationToken cancellationToken
    );

    Task<Aircraft?> GetStateByIcao24Async(string icao24, CancellationToken cancellationToken);
}
