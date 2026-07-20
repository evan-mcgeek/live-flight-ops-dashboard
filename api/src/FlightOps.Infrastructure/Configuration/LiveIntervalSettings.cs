namespace FlightOps.Infrastructure.Configuration;

// Global, runtime-mutable SignalR broadcast interval — one shared value for every connected client, not per-client.
public interface ILiveIntervalSettings
{
    TimeSpan Interval { get; }
    void Set(TimeSpan interval);
}

public sealed class LiveIntervalSettings : ILiveIntervalSettings
{
    private readonly object _gate = new();
    private TimeSpan _interval;

    public LiveIntervalSettings(TimeSpan initial) => _interval = initial;

    public TimeSpan Interval
    {
        get
        {
            lock (_gate)
                return _interval;
        }
    }

    public void Set(TimeSpan interval)
    {
        lock (_gate)
            _interval = interval;
    }
}
