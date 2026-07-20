namespace FlightOps.Domain;

public sealed record BoundingBox(double LaMin, double LoMin, double LaMax, double LoMax)
{
    public BoundingBox RoundToGrid(double gridDegrees)
    {
        double RoundDown(double value) => Math.Floor(value / gridDegrees) * gridDegrees;
        double RoundUp(double value) => Math.Ceiling(value / gridDegrees) * gridDegrees;

        return new BoundingBox(RoundDown(LaMin), RoundDown(LoMin), RoundUp(LaMax), RoundUp(LoMax));
    }

    public string CacheKey => $"{LaMin:F2}_{LoMin:F2}_{LaMax:F2}_{LoMax:F2}";
}
