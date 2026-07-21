using Polly;
using Polly.Extensions.Http;

namespace FlightOps.Infrastructure.OpenSky;

public static class OpenSkyResiliencePolicy
{
    // HandleTransientHttpError covers 5xx, 408, and HttpRequestException — it
    // deliberately excludes 429, which OpenSkyClient.SendAsync already handles.
    public static IAsyncPolicy<HttpResponseMessage> RetryPolicy() =>
        HttpPolicyExtensions
            .HandleTransientHttpError()
            .WaitAndRetryAsync(
                retryCount: 3,
                sleepDurationProvider: attempt =>
                    TimeSpan.FromMilliseconds(200 * Math.Pow(2, attempt - 1))
            );
}
