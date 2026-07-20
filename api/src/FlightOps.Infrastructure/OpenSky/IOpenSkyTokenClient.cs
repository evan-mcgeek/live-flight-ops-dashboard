namespace FlightOps.Infrastructure.OpenSky;

public interface IOpenSkyTokenClient
{
    Task<OpenSkyToken> FetchTokenAsync(CancellationToken cancellationToken);
}
