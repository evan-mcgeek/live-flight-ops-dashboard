using System.Text.Json;
using FlightOps.Domain;

namespace FlightOps.Infrastructure.OpenSky;

public static class OpenSkyStateMapper
{
    public static Aircraft Map(JsonElement stateVector)
    {
        return new Aircraft(
            Icao24: stateVector[0].GetString()!,
            Callsign: stateVector[1].GetString()?.Trim(),
            OriginCountry: stateVector[2].GetString()!,
            Longitude: GetNullableDouble(stateVector[5]),
            Latitude: GetNullableDouble(stateVector[6]),
            Altitude: GetNullableDouble(stateVector[7]),
            Velocity: GetNullableDouble(stateVector[9]),
            Heading: GetNullableDouble(stateVector[10]),
            OnGround: stateVector[8].GetBoolean(),
            LastUpdate: DateTimeOffset.FromUnixTimeSeconds(stateVector[4].GetInt64())
        );
    }

    private static double? GetNullableDouble(JsonElement element) =>
        element.ValueKind == JsonValueKind.Null ? null : element.GetDouble();
}
