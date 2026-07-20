part of 'aircraft_list_bloc.dart';

sealed class AircraftListState extends Equatable {
  const AircraftListState({required this.query});

  // Search text — orthogonal to load status, so it's carried on every variant.
  final String query;
}

class AircraftListInitial extends AircraftListState {
  const AircraftListInitial({super.query = ''});

  @override
  List<Object?> get props => [query];
}

class AircraftListLoading extends AircraftListState {
  const AircraftListLoading({super.query = ''});

  @override
  List<Object?> get props => [query];
}

class AircraftListLoaded extends AircraftListState {
  const AircraftListLoaded({
    required this.allAircraft,
    this.stale = false,
    this.isRefreshing = false,
    super.query = '',
  });

  final List<Aircraft> allAircraft;
  final bool stale;

  // True only while a region change (pan/zoom) is refetching after this data landed.
  final bool isRefreshing;

  List<Aircraft> get visibleAircraft {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return allAircraft;
    return allAircraft
        .where(
          (a) =>
              (a.callsign?.toLowerCase().contains(normalized) ?? false) ||
              a.originCountry.toLowerCase().contains(normalized),
        )
        .toList();
  }

  @override
  List<Object?> get props => [allAircraft, stale, isRefreshing, query];
}

class AircraftListError extends AircraftListState {
  const AircraftListError({
    required this.failure,
    this.staleAircraft,
    super.query = '',
  });

  final Failure failure;
  final List<Aircraft>? staleAircraft;

  @override
  List<Object?> get props => [failure, staleAircraft, query];
}
