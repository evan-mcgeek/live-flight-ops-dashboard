using System.Net.Http.Headers;
using FlightOps.Infrastructure.Configuration;
using Microsoft.Extensions.Options;

namespace FlightOps.Infrastructure.OpenSky;

public sealed class OpenSkyTokenProvider(
    IOpenSkyTokenClient tokenClient,
    IOptions<TokenSettings> tokenSettings
) : DelegatingHandler
{
    private readonly SemaphoreSlim _lock = new(1, 1);
    private OpenSkyToken? _cachedToken;

    protected override async Task<HttpResponseMessage> SendAsync(
        HttpRequestMessage request,
        CancellationToken cancellationToken
    )
    {
        var token = await GetValidTokenAsync(cancellationToken);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token.AccessToken);
        return await base.SendAsync(request, cancellationToken);
    }

    private async Task<OpenSkyToken> GetValidTokenAsync(CancellationToken cancellationToken)
    {
        var refreshMargin = tokenSettings.Value.RefreshMargin;

        if (
            _cachedToken is { } current
            && current.ExpiresAt - refreshMargin > DateTimeOffset.UtcNow
        )
        {
            return current;
        }

        await _lock.WaitAsync(cancellationToken);
        try
        {
            if (
                _cachedToken is { } stillCurrent
                && stillCurrent.ExpiresAt - refreshMargin > DateTimeOffset.UtcNow
            )
            {
                return stillCurrent;
            }

            _cachedToken = await tokenClient.FetchTokenAsync(cancellationToken);
            return _cachedToken;
        }
        finally
        {
            _lock.Release();
        }
    }
}
