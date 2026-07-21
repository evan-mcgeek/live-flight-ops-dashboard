namespace FlightOps.Infrastructure.OpenSky;

public sealed class OpenSkyMalformedResponseException()
    : Exception("OpenSky returned a malformed state vector.");
