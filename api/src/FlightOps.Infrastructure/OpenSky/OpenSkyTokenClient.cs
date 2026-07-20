using System.Net.Http.Json;
using System.Text.Json.Serialization;
using FlightOps.Infrastructure.Configuration;
using Microsoft.Extensions.Options;

namespace FlightOps.Infrastructure.OpenSky;

public sealed class OpenSkyTokenClient(HttpClient httpClient, IOptions<OpenSkySettings> settings)
    : IOpenSkyTokenClient
{
    private readonly OpenSkySettings _settings = settings.Value;

    public async Task<OpenSkyToken> FetchTokenAsync(CancellationToken cancellationToken)
    {
        var requestBody = new Dictionary<string, string>
        {
            ["grant_type"] = "client_credentials",
            ["client_id"] = _settings.ClientId,
            ["client_secret"] = _settings.ClientSecret,
        };

        using var response = await httpClient.PostAsync(
            _settings.TokenUrl,
            new FormUrlEncodedContent(requestBody),
            cancellationToken
        );
        response.EnsureSuccessStatusCode();

        var payload =
            await response.Content.ReadFromJsonAsync<TokenResponse>(
                cancellationToken: cancellationToken
            ) ?? throw new InvalidOperationException("OpenSky token response was empty.");

        return new OpenSkyToken(
            payload.AccessToken,
            DateTimeOffset.UtcNow.AddSeconds(payload.ExpiresIn)
        );
    }

    private sealed record TokenResponse(
        [property: JsonPropertyName("access_token")] string AccessToken,
        [property: JsonPropertyName("expires_in")] int ExpiresIn
    );
}
