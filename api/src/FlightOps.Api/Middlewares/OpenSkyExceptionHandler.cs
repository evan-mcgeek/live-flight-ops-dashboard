using FlightOps.Infrastructure.OpenSky;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;

namespace FlightOps.Api.Middlewares;

public sealed class OpenSkyExceptionHandler : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(
        HttpContext httpContext,
        Exception exception,
        CancellationToken cancellationToken
    )
    {
        if (exception is not OpenSkyRateLimitedException)
        {
            return false;
        }

        httpContext.Response.StatusCode = StatusCodes.Status503ServiceUnavailable;
        await httpContext.Response.WriteAsJsonAsync(
            new ProblemDetails
            {
                Status = StatusCodes.Status503ServiceUnavailable,
                Title = "OpenSky rate limit exceeded and no cached data is available.",
            },
            cancellationToken
        );

        return true;
    }
}
