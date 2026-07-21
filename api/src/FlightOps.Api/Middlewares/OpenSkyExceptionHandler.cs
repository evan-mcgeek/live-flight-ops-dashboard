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
        var (statusCode, title) = exception switch
        {
            OpenSkyRateLimitedException => (
                StatusCodes.Status503ServiceUnavailable,
                "OpenSky rate limit exceeded and no cached data is available."
            ),
            OpenSkyMalformedResponseException => (
                StatusCodes.Status502BadGateway,
                "OpenSky returned a response this API could not parse."
            ),
            _ => (0, (string?)null),
        };

        if (title is null)
        {
            return false;
        }

        httpContext.Response.StatusCode = statusCode;
        await httpContext.Response.WriteAsJsonAsync(
            new ProblemDetails { Status = statusCode, Title = title },
            cancellationToken
        );

        return true;
    }
}
