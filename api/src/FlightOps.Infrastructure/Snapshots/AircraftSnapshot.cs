using FlightOps.Domain;

namespace FlightOps.Infrastructure.Snapshots;

public sealed record AircraftSnapshot(IReadOnlyList<Aircraft> Aircraft, bool Stale);
