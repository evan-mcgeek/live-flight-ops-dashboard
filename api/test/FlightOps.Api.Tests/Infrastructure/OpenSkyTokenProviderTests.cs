using System.Net;
using FlightOps.Infrastructure.Configuration;
using FlightOps.Infrastructure.OpenSky;
using Microsoft.Extensions.Options;
using NSubstitute;
using NUnit.Framework;

namespace FlightOps.Api.Tests.Infrastructure;

[TestFixture]
public class OpenSkyTokenProviderTests
{
    private IOpenSkyTokenClient _tokenClient = null!;
    private RecordingHandler _innerHandler = null!;
    private HttpClient _httpClient = null!;

    [SetUp]
    public void SetUp()
    {
        _tokenClient = Substitute.For<IOpenSkyTokenClient>();
        _innerHandler = new RecordingHandler();
        var provider = new OpenSkyTokenProvider(_tokenClient, Options.Create(new TokenSettings()))
        {
            InnerHandler = _innerHandler,
        };
        _httpClient = new HttpClient(provider)
        {
            BaseAddress = new Uri("https://opensky-network.org"),
        };
    }

    [TearDown]
    public void TearDown()
    {
        _httpClient.Dispose();
        _innerHandler?.Dispose();
    }

    [Test]
    public async Task Attaches_bearer_token_from_token_client_on_first_request()
    {
        _tokenClient
            .FetchTokenAsync(Arg.Any<CancellationToken>())
            .Returns(new OpenSkyToken("token-1", DateTimeOffset.UtcNow.AddMinutes(30)));

        await _httpClient.GetAsync("/api/states/all");

        Assert.That(
            _innerHandler.LastRequest!.Headers.Authorization!.Parameter,
            Is.EqualTo("token-1")
        );
        await _tokenClient.Received(1).FetchTokenAsync(Arg.Any<CancellationToken>());
    }

    [Test]
    public async Task Reuses_cached_token_when_not_near_expiry()
    {
        _tokenClient
            .FetchTokenAsync(Arg.Any<CancellationToken>())
            .Returns(new OpenSkyToken("token-1", DateTimeOffset.UtcNow.AddMinutes(30)));

        await _httpClient.GetAsync("/api/states/all");
        await _httpClient.GetAsync("/api/states/all");

        await _tokenClient.Received(1).FetchTokenAsync(Arg.Any<CancellationToken>());
    }

    [Test]
    public async Task Refreshes_token_when_near_expiry()
    {
        _tokenClient
            .FetchTokenAsync(Arg.Any<CancellationToken>())
            .Returns(
                new OpenSkyToken("token-1", DateTimeOffset.UtcNow.AddSeconds(30)),
                new OpenSkyToken("token-2", DateTimeOffset.UtcNow.AddMinutes(30))
            );

        await _httpClient.GetAsync("/api/states/all");
        await _httpClient.GetAsync("/api/states/all");

        Assert.That(
            _innerHandler.LastRequest!.Headers.Authorization!.Parameter,
            Is.EqualTo("token-2")
        );
        await _tokenClient.Received(2).FetchTokenAsync(Arg.Any<CancellationToken>());
    }

    private sealed class RecordingHandler : DelegatingHandler
    {
        public HttpRequestMessage? LastRequest { get; private set; }

        protected override Task<HttpResponseMessage> SendAsync(
            HttpRequestMessage request,
            CancellationToken cancellationToken
        )
        {
            LastRequest = request;
            return Task.FromResult(new HttpResponseMessage(HttpStatusCode.OK));
        }
    }
}
