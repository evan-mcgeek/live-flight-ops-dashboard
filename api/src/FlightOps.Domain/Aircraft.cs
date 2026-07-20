namespace FlightOps.Domain;

public sealed record Aircraft(
    string Icao24,
    string? Callsign,
    string OriginCountry,
    double? Longitude,
    double? Latitude,
    double? Altitude,
    double? Velocity,
    double? Heading,
    bool OnGround,
    DateTimeOffset LastUpdate
);
