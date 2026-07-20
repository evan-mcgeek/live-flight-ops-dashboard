namespace FlightOps.Api.Hubs;

public class BroadcastSettings
{
    public const string ConfigurationSectionName = "Broadcast";

    public TimeSpan Interval { get; set; } = TimeSpan.FromSeconds(5);
}
