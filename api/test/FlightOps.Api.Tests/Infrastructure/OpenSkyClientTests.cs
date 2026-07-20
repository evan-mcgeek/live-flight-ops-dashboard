using System.Net;
using System.Text;
using FlightOps.Domain;
using FlightOps.Infrastructure.OpenSky;
using Microsoft.Extensions.Logging.Abstractions;
using NUnit.Framework;

namespace FlightOps.Api.Tests.Infrastructure;

[TestFixture]
public class OpenSkyClientTests
{
    [Test]
    public async Task GetStatesAsync_maps_all_states_in_the_response()
    {
        const string json = """
            {
              "time": 1700000000,
              "states": [
                ["3c6444","DLH9LF  ","Germany",1700000000,1700000000,10.3768,60.0392,9639.3,false,232.88,98.16,0.33,null,10058.4,"1000",false,0,0],
                ["a1b2c3","UAL123  ","United States",1700000000,1700000000,-122.4,37.7,null,true,0.0,0.0,0.0,null,null,"1200",false,0,0]
              ]
            }
            """;
        var handler = new StubHandler(
            new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent(json, Encoding.UTF8, "application/json"),
            }
        );
        using var httpClient = new HttpClient(handler)
        {
            BaseAddress = new Uri("https://opensky-network.org/api"),
        };
        var client = new OpenSkyClient(httpClient, NullLogger<OpenSkyClient>.Instance);

        var states = await client.GetStatesAsync(
            new BoundingBox(30, -130, 60, -60),
            CancellationToken.None
        );

        Assert.That(states, Has.Count.EqualTo(2));
        Assert.That(states[0].Icao24, Is.EqualTo("3c6444"));
        Assert.That(states[1].OnGround, Is.True);
    }

    [Test]
    public void GetStatesAsync_throws_OpenSkyRateLimitedException_on_429()
    {
        var handler = new StubHandler(new HttpResponseMessage(HttpStatusCode.TooManyRequests));
        using var httpClient = new HttpClient(handler)
        {
            BaseAddress = new Uri("https://opensky-network.org/api"),
        };
        var client = new OpenSkyClient(httpClient, NullLogger<OpenSkyClient>.Instance);

        Assert.ThrowsAsync<OpenSkyRateLimitedException>(() =>
            client.GetStatesAsync(new BoundingBox(30, -130, 60, -60), CancellationToken.None)
        );
    }

    [Test]
    public async Task GetStateByIcao24Async_url_encodes_the_icao24_value()
    {
        HttpRequestMessage? capturedRequest = null;
        var handler = new CapturingHandler(request =>
        {
            capturedRequest = request;
            return new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent(
                    """{"time":1700000000,"states":[]}""",
                    Encoding.UTF8,
                    "application/json"
                ),
            };
        });
        using var httpClient = new HttpClient(handler)
        {
            BaseAddress = new Uri("https://opensky-network.org/api"),
        };
        var client = new OpenSkyClient(httpClient, NullLogger<OpenSkyClient>.Instance);

        await client.GetStateByIcao24Async("a1&foo=bar", CancellationToken.None);

        Assert.That(capturedRequest!.RequestUri!.Query, Is.EqualTo("?icao24=a1%26foo%3Dbar"));
    }

    private sealed class StubHandler(HttpResponseMessage response) : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(
            HttpRequestMessage request,
            CancellationToken cancellationToken
        ) => Task.FromResult(response);
    }

    private sealed class CapturingHandler(Func<HttpRequestMessage, HttpResponseMessage> respond)
        : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(
            HttpRequestMessage request,
            CancellationToken cancellationToken
        ) => Task.FromResult(respond(request));
    }
}
