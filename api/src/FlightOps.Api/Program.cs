using FlightOps.Api.Hubs;
using FlightOps.Api.Middlewares;
using FlightOps.Infrastructure.Configuration;
using FlightOps.Infrastructure.OpenSky;
using FlightOps.Infrastructure.Snapshots;
using FluentValidation;
using Microsoft.Extensions.Options;

var builder = WebApplication.CreateBuilder(args);

builder.Configuration.AddJsonFile("appsettings.secrets.json", optional: true, reloadOnChange: true);

AddOpenSkyServices(builder.Services, builder.Configuration);
AddSignalRServices(builder.Services, builder.Configuration);
AddApiServices(builder.Services);

var app = builder.Build();

app.UseExceptionHandler();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.MapControllers();
app.MapHub<AircraftHub>("/hubs/aircraft");

app.Run();

static void AddOpenSkyServices(IServiceCollection services, IConfiguration configuration)
{
    services.Configure<OpenSkySettings>(
        configuration.GetSection(OpenSkySettings.ConfigurationSectionName)
    );
    services.Configure<TokenSettings>(
        configuration.GetSection(TokenSettings.ConfigurationSectionName)
    );

    services.AddTransient<OpenSkyTokenProvider>();
    services.AddHttpClient<IOpenSkyTokenClient, OpenSkyTokenClient>();

    services
        .AddHttpClient<IOpenSkyClient, OpenSkyClient>(
            (sp, client) =>
            {
                var settings = sp.GetRequiredService<IOptions<OpenSkySettings>>().Value;
                client.BaseAddress = new Uri(settings.ApiBaseUrl);
                client.Timeout = TimeSpan.FromSeconds(10);
            }
        )
        .AddHttpMessageHandler<OpenSkyTokenProvider>()
        // Added last so a retry re-runs the whole pipeline, including auth.
        .AddPolicyHandler(OpenSkyResiliencePolicy.RetryPolicy());

    services.AddSingleton<IAircraftSnapshotProvider, DirectSnapshotProvider>();
}

static void AddSignalRServices(IServiceCollection services, IConfiguration configuration)
{
    services.Configure<BroadcastSettings>(
        configuration.GetSection(BroadcastSettings.ConfigurationSectionName)
    );

    services.AddSingleton<ILiveIntervalSettings>(sp =>
    {
        var seed = sp.GetRequiredService<IOptions<BroadcastSettings>>().Value.Interval;
        return new LiveIntervalSettings(seed);
    });

    services.AddSignalR();
    services.AddSingleton<IActiveBoundingBoxRegistry, ActiveBoundingBoxRegistry>();
    services.AddHostedService<AircraftBroadcastService>();
}

static void AddApiServices(IServiceCollection services)
{
    services.AddControllers();
    services.AddValidatorsFromAssemblyContaining<Program>();
    services.AddExceptionHandler<OpenSkyExceptionHandler>();
    services.AddProblemDetails();
    services.AddSwaggerGen();
}

public partial class Program;
