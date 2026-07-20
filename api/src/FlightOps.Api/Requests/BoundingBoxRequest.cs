namespace FlightOps.Api.Requests;

public sealed class BoundingBoxRequest
{
    public double LaMin { get; set; }

    public double LoMin { get; set; }

    public double LaMax { get; set; }

    public double LoMax { get; set; }
}
