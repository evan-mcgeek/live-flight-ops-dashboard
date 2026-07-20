namespace FlightOps.Infrastructure.Configuration;

public class TokenSettings
{
    public const string ConfigurationSectionName = "Token";

    public TimeSpan RefreshMargin { get; set; } = TimeSpan.FromSeconds(60);
}
