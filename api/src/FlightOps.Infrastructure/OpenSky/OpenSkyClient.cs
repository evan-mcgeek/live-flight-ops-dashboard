using System.Net;
using System.Text.Json;
using FlightOps.Domain;
using Microsoft.Extensions.Logging;

namespace FlightOps.Infrastructure.OpenSky;

public sealed class OpenSkyClient(HttpClient httpClient, ILogger<OpenSkyClient> logger)
    : IOpenSkyClient
{
    public async Task<IReadOnlyList<Aircraft>> GetStatesAsync(
        BoundingBox bbox,
        CancellationToken cancellationToken
    )
    {
        var url =
            $"/api/states/all?lamin={bbox.LaMin}&lomin={bbox.LoMin}&lamax={bbox.LaMax}&lomax={bbox.LoMax}";
        using var response = await SendAsync(url, cancellationToken);

        await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken);
        using var document = await JsonDocument.ParseAsync(
            stream,
            cancellationToken: cancellationToken
        );

        if (
            !document.RootElement.TryGetProperty("states", out var states)
            || states.ValueKind != JsonValueKind.Array
        )
        {
            return [];
        }

        var aircraft = new List<Aircraft>(states.GetArrayLength());
        foreach (var state in states.EnumerateArray())
        {
            aircraft.Add(OpenSkyStateMapper.Map(state));
        }
        return aircraft;
    }

    public async Task<Aircraft?> GetStateByIcao24Async(
        string icao24,
        CancellationToken cancellationToken
    )
    {
        using var response = await SendAsync(
            $"/api/states/all?icao24={Uri.EscapeDataString(icao24)}",
            cancellationToken
        );

        await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken);
        using var document = await JsonDocument.ParseAsync(
            stream,
            cancellationToken: cancellationToken
        );

        if (
            !document.RootElement.TryGetProperty("states", out var states)
            || states.ValueKind != JsonValueKind.Array
            || states.GetArrayLength() == 0
        )
        {
            return null;
        }

        return OpenSkyStateMapper.Map(states[0]);
    }

    private async Task<HttpResponseMessage> SendAsync(
        string url,
        CancellationToken cancellationToken
    )
    {
        var response = await httpClient.GetAsync(url, cancellationToken);

        if (response.StatusCode == HttpStatusCode.TooManyRequests)
        {
            throw new OpenSkyRateLimitedException();
        }
        response.EnsureSuccessStatusCode();

        if (response.Headers.TryGetValues("X-Rate-Limit-Remaining", out var remaining))
        {
            logger.LogInformation(
                "OpenSky quota remaining: {Remaining}",
                remaining.FirstOrDefault()
            );
        }

        return response;
    }
}
