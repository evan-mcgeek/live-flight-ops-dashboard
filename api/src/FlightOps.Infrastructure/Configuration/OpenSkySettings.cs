namespace FlightOps.Infrastructure.Configuration;

public class OpenSkySettings
{
    public const string ConfigurationSectionName = "OpenSkySettings";

    public string TokenUrl { get; set; } = string.Empty;

    public string ApiBaseUrl { get; set; } = string.Empty;

    public string ClientId { get; set; } = string.Empty;

    public string ClientSecret { get; set; } = string.Empty;
}
