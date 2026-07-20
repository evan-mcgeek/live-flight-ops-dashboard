using System.Text.RegularExpressions;
using FlightOps.Api.Requests;
using FlightOps.Domain;
using FlightOps.Infrastructure.Configuration;
using FlightOps.Infrastructure.OpenSky;
using FlightOps.Infrastructure.Snapshots;
using FluentValidation;
using Microsoft.AspNetCore.Mvc;

namespace FlightOps.Api.Controllers;

[ApiController]
[Route("aircraft")]
public sealed class AircraftController(
    IAircraftSnapshotProvider snapshotProvider,
    IOpenSkyClient openSkyClient,
    IValidator<BoundingBoxRequest> validator,
    ILiveIntervalSettings liveIntervalSettings
) : ControllerBase
{
    private static readonly int[] AllowedLiveIntervalSeconds = [1, 2, 5, 10, 30, 60, 120];
    private const string LiveIntervalHeaderName = "X-Live-Interval-Seconds";

    [HttpGet]
    public async Task<IActionResult> GetAircraft(
        [FromQuery] BoundingBoxRequest request,
        CancellationToken cancellationToken
    )
    {
        var validationResult = await validator.ValidateAsync(request, cancellationToken);
        if (!validationResult.IsValid)
        {
            foreach (var error in validationResult.Errors)
            {
                ModelState.AddModelError(error.PropertyName, error.ErrorMessage);
            }
            return ValidationProblem(ModelState);
        }

        if (TryReadValidLiveInterval(out var seconds))
        {
            liveIntervalSettings.Set(TimeSpan.FromSeconds(seconds));
        }

        var bbox = new BoundingBox(request.LaMin, request.LoMin, request.LaMax, request.LoMax);
        var snapshot = await snapshotProvider.GetSnapshotAsync(bbox, cancellationToken);
        return Ok(snapshot);
    }

    [HttpPost("live-interval")]
    public IActionResult SetLiveInterval()
    {
        if (!TryReadValidLiveInterval(out var seconds))
        {
            ModelState.AddModelError(
                LiveIntervalHeaderName,
                $"Header '{LiveIntervalHeaderName}' must be present and one of: {string.Join(", ", AllowedLiveIntervalSeconds)}."
            );
            return ValidationProblem(ModelState);
        }

        liveIntervalSettings.Set(TimeSpan.FromSeconds(seconds));
        return Ok(new { intervalSeconds = seconds });
    }

    private bool TryReadValidLiveInterval(out int seconds)
    {
        seconds = 0;
        return Request.Headers.TryGetValue(LiveIntervalHeaderName, out var values)
            && int.TryParse(values.ToString(), out seconds)
            && AllowedLiveIntervalSeconds.Contains(seconds);
    }

    [HttpGet("{icao24}")]
    public async Task<IActionResult> GetAircraftDetail(
        string icao24,
        CancellationToken cancellationToken
    )
    {
        if (!Regex.IsMatch(icao24, "^[0-9a-fA-F]{6}$"))
        {
            ModelState.AddModelError(
                nameof(icao24),
                "icao24 must be a 6-character hexadecimal aircraft address."
            );
            return ValidationProblem(ModelState);
        }

        var aircraft = await openSkyClient.GetStateByIcao24Async(icao24, cancellationToken);
        return aircraft is null ? NotFound() : Ok(aircraft);
    }
}
