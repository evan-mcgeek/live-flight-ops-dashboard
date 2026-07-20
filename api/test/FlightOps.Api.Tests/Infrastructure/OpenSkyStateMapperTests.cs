using System.Text.Json;
using FlightOps.Infrastructure.OpenSky;
using NUnit.Framework;

namespace FlightOps.Api.Tests.Infrastructure;

[TestFixture]
public class OpenSkyStateMapperTests
{
    [Test]
    public void Maps_a_fully_populated_state_vector()
    {
        const string json = """
            ["3c6444","DLH9LF  ","Germany",1700000000,1700000000,10.3768,60.0392,9639.3,false,232.88,98.16,0.33,null,10058.4,"1000",false,0,0]
            """;
        using var document = JsonDocument.Parse(json);

        var aircraft = OpenSkyStateMapper.Map(document.RootElement);

        Assert.Multiple(() =>
        {
            Assert.That(aircraft.Icao24, Is.EqualTo("3c6444"));
            Assert.That(aircraft.Callsign, Is.EqualTo("DLH9LF"));
            Assert.That(aircraft.OriginCountry, Is.EqualTo("Germany"));
            Assert.That(aircraft.Longitude, Is.EqualTo(10.3768));
            Assert.That(aircraft.Latitude, Is.EqualTo(60.0392));
            Assert.That(aircraft.Altitude, Is.EqualTo(9639.3));
            Assert.That(aircraft.Velocity, Is.EqualTo(232.88));
            Assert.That(aircraft.Heading, Is.EqualTo(98.16));
            Assert.That(aircraft.OnGround, Is.False);
            Assert.That(
                aircraft.LastUpdate,
                Is.EqualTo(DateTimeOffset.FromUnixTimeSeconds(1700000000))
            );
        });
    }

    [Test]
    public void Maps_null_altitude_and_on_ground_true()
    {
        const string json = """
            ["a1b2c3","UAL123  ","United States",1700000000,1700000000,-122.4,37.7,null,true,0.0,0.0,0.0,null,null,"1200",false,0,0]
            """;
        using var document = JsonDocument.Parse(json);

        var aircraft = OpenSkyStateMapper.Map(document.RootElement);

        Assert.Multiple(() =>
        {
            Assert.That(aircraft.Callsign, Is.EqualTo("UAL123"));
            Assert.That(aircraft.Altitude, Is.Null);
            Assert.That(aircraft.OnGround, Is.True);
        });
    }
}
