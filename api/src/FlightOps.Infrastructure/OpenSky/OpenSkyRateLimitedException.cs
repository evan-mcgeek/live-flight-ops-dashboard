namespace FlightOps.Infrastructure.OpenSky;

public sealed class OpenSkyRateLimitedException()
    : Exception("OpenSky API rate limit exceeded (429).");
