using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using FlightOps.Domain;
using FlightOps.Infrastructure.Configuration;
using FlightOps.Infrastructure.OpenSky;
using FlightOps.Infrastructure.Snapshots;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using NSubstitute;
using NUnit.Framework;

namespace FlightOps.Api.Tests.Controllers;

[TestFixture]
public class AircraftControllerTests
{
    // Controllers serialize with ASP.NET Core's camelCase default; matching options
    // are needed here so deserialization matches "aircraft"/"stale" back to the
    // PascalCase record properties instead of silently leaving them at their defaults.
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    private IAircraftSnapshotProvider _snapshotProvider = null!;
    private IOpenSkyClient _openSkyClient = null!;
    private ILiveIntervalSettings _liveIntervalSettings = null!;
    private WebApplicationFactory<Program> _factory = null!;
    private HttpClient _client = null!;

    [SetUp]
    public void SetUp()
    {
        _snapshotProvider = Substitute.For<IAircraftSnapshotProvider>();
        _openSkyClient = Substitute.For<IOpenSkyClient>();
        _liveIntervalSettings = Substitute.For<ILiveIntervalSettings>();
        // AircraftBroadcastService (a hosted BackgroundService, running for the
        // lifetime of every WebApplicationFactory instance here) does
        // `Task.Delay(liveIntervalSettings.Interval, ...)` on every loop iteration.
        // An unstubbed NSubstitute property defaults to TimeSpan.Zero, which turns
        // that into a zero-delay busy loop that pins a thread-pool thread for as
        // long as the host is alive — stubbing a real interval keeps the
        // background service quiescent during these HTTP-focused tests.
        _liveIntervalSettings.Interval.Returns(TimeSpan.FromSeconds(5));
        _factory = new WebApplicationFactory<Program>().WithWebHostBuilder(builder =>
        {
            builder.ConfigureServices(services =>
            {
                services.RemoveAll<IAircraftSnapshotProvider>();
                services.AddSingleton(_snapshotProvider);
                services.RemoveAll<IOpenSkyClient>();
                services.AddSingleton(_openSkyClient);
                services.RemoveAll<ILiveIntervalSettings>();
                services.AddSingleton(_liveIntervalSettings);
            });
        });
        _client = _factory.CreateClient();
    }

    [TearDown]
    public void TearDown()
    {
        _client.Dispose();
        _factory.Dispose();
    }

    [Test]
    public async Task GetAircraft_returns_snapshot_for_valid_bbox()
    {
        var aircraft = new List<Aircraft>
        {
            new("abc123", "TEST1", "Testland", 1, 2, 3, 4, 5, false, DateTimeOffset.UtcNow),
        };
        _snapshotProvider
            .GetSnapshotAsync(Arg.Any<BoundingBox>(), Arg.Any<CancellationToken>())
            .Returns(new AircraftSnapshot(aircraft, Stale: false));

        var response = await _client.GetAsync("/aircraft?lamin=10&lomin=10&lamax=20&lomax=20");
        var snapshot = await response.Content.ReadFromJsonAsync<AircraftSnapshot>(JsonOptions);

        Assert.That(response.StatusCode, Is.EqualTo(HttpStatusCode.OK));
        Assert.That(snapshot!.Aircraft, Has.Count.EqualTo(1));
    }

    [Test]
    public async Task GetAircraft_returns_400_for_invalid_bbox()
    {
        var response = await _client.GetAsync("/aircraft?lamin=20&lomin=10&lamax=10&lomax=20");

        Assert.That(response.StatusCode, Is.EqualTo(HttpStatusCode.BadRequest));
    }

    [Test]
    public async Task GetAircraftDetail_returns_404_when_not_found()
    {
        _openSkyClient
            .GetStateByIcao24Async("ffffff", Arg.Any<CancellationToken>())
            .Returns((Aircraft?)null);

        var response = await _client.GetAsync("/aircraft/ffffff");

        Assert.That(response.StatusCode, Is.EqualTo(HttpStatusCode.NotFound));
    }

    [Test]
    public async Task GetAircraftDetail_returns_the_aircraft_when_found()
    {
        var aircraft = new Aircraft(
            "abc123",
            "TEST1",
            "Testland",
            1,
            2,
            3,
            4,
            5,
            false,
            DateTimeOffset.UtcNow
        );
        _openSkyClient
            .GetStateByIcao24Async("abc123", Arg.Any<CancellationToken>())
            .Returns(aircraft);

        var response = await _client.GetAsync("/aircraft/abc123");
        var body = await response.Content.ReadFromJsonAsync<Aircraft>(JsonOptions);

        Assert.That(response.StatusCode, Is.EqualTo(HttpStatusCode.OK));
        Assert.That(body!.Icao24, Is.EqualTo("abc123"));
    }

    [Test]
    public async Task GetAircraftDetail_returns_400_for_invalid_icao24_format()
    {
        var response = await _client.GetAsync("/aircraft/not-a-valid-icao");

        Assert.That(response.StatusCode, Is.EqualTo(HttpStatusCode.BadRequest));
    }

    [Test]
    public async Task SetLiveInterval_returns_200_and_sets_interval_for_valid_header()
    {
        var request = new HttpRequestMessage(HttpMethod.Post, "/aircraft/live-interval")
        {
            Headers = { { "X-Live-Interval-Seconds", "30" } },
        };

        var response = await _client.SendAsync(request);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();

        Assert.That(response.StatusCode, Is.EqualTo(HttpStatusCode.OK));
        Assert.That(body.GetProperty("intervalSeconds").GetInt32(), Is.EqualTo(30));
        _liveIntervalSettings.Received(1).Set(TimeSpan.FromSeconds(30));
    }

    [Test]
    public async Task SetLiveInterval_returns_400_for_disallowed_value()
    {
        var request = new HttpRequestMessage(HttpMethod.Post, "/aircraft/live-interval")
        {
            Headers = { { "X-Live-Interval-Seconds", "7" } },
        };

        var response = await _client.SendAsync(request);

        Assert.That(response.StatusCode, Is.EqualTo(HttpStatusCode.BadRequest));
    }

    [Test]
    public async Task SetLiveInterval_returns_400_when_header_missing()
    {
        var request = new HttpRequestMessage(HttpMethod.Post, "/aircraft/live-interval");

        var response = await _client.SendAsync(request);

        Assert.That(response.StatusCode, Is.EqualTo(HttpStatusCode.BadRequest));
    }

    [Test]
    public async Task GetAircraft_ignores_the_live_interval_header_entirely()
    {
        var aircraft = new List<Aircraft>
        {
            new("abc123", "TEST1", "Testland", 1, 2, 3, 4, 5, false, DateTimeOffset.UtcNow),
        };
        _snapshotProvider
            .GetSnapshotAsync(Arg.Any<BoundingBox>(), Arg.Any<CancellationToken>())
            .Returns(new AircraftSnapshot(aircraft, Stale: false));
        var request = new HttpRequestMessage(
            HttpMethod.Get,
            "/aircraft?lamin=10&lomin=10&lamax=20&lomax=20"
        )
        {
            Headers = { { "X-Live-Interval-Seconds", "30" } },
        };

        var response = await _client.SendAsync(request);
        var snapshot = await response.Content.ReadFromJsonAsync<AircraftSnapshot>(JsonOptions);

        Assert.That(response.StatusCode, Is.EqualTo(HttpStatusCode.OK));
        Assert.That(snapshot!.Aircraft, Has.Count.EqualTo(1));
        _liveIntervalSettings.DidNotReceive().Set(Arg.Any<TimeSpan>());
    }
}
