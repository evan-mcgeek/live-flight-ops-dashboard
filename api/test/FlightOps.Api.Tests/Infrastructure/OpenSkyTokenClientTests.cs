using System.Net;
using System.Text;
using FlightOps.Infrastructure.Configuration;
using FlightOps.Infrastructure.OpenSky;
using Microsoft.Extensions.Options;
using NUnit.Framework;

namespace FlightOps.Api.Tests.Infrastructure;

[TestFixture]
public class OpenSkyTokenClientTests
{
    [Test]
    public async Task Parses_access_token_and_expiry_from_response()
    {
        var handler = new StubHandler(
            new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent(
                    """{"access_token":"abc123","expires_in":1800,"token_type":"bearer"}""",
                    Encoding.UTF8,
                    "application/json"
                ),
            }
        );
        using var httpClient = new HttpClient(handler);
        var settings = Options.Create(
            new OpenSkySettings
            {
                TokenUrl =
                    "https://auth.opensky-network.org/auth/realms/opensky-network/protocol/openid-connect/token",
                ClientId = "client",
                ClientSecret = "secret",
            }
        );
        var tokenClient = new OpenSkyTokenClient(httpClient, settings);

        var before = DateTimeOffset.UtcNow;
        var token = await tokenClient.FetchTokenAsync(CancellationToken.None);

        Assert.That(token.AccessToken, Is.EqualTo("abc123"));
        Assert.That(token.ExpiresAt, Is.GreaterThan(before.AddSeconds(1750)));
    }

    private sealed class StubHandler(HttpResponseMessage response) : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(
            HttpRequestMessage request,
            CancellationToken cancellationToken
        ) => Task.FromResult(response);
    }
}
