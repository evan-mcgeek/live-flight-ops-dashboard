namespace FlightOps.Infrastructure.OpenSky;

public sealed record OpenSkyToken(string AccessToken, DateTimeOffset ExpiresAt);
