import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_strings.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/aircraft.dart';
import '../map/widgets/aircraft_marker.dart';
import '../shared/connectivity_state_card.dart';
import 'bloc/aircraft_list_bloc.dart';
import 'widgets/aircraft_list_skeleton.dart';
import 'widgets/stale_data_banner.dart';

class AircraftListPage extends StatelessWidget {
  const AircraftListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AircraftListBloc>(),
      child: const _AircraftListView(),
    );
  }
}

class _AircraftListView extends StatelessWidget {
  const _AircraftListView();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<AircraftListBloc, AircraftListState>(
          builder: (context, state) {
            final visible = switch (state) {
              AircraftListLoaded() => state.visibleAircraft,
              _ => const <Aircraft>[],
            };
            final failure = switch (state) {
              AircraftListError(:final failure) => failure,
              _ => null,
            };
            final isRefreshing = switch (state) {
              AircraftListLoaded(:final isRefreshing) => isRefreshing,
              _ => false,
            };
            final stale = switch (state) {
              AircraftListLoaded(:final stale) => stale,
              _ => false,
            };
            final isLoading =
                state is AircraftListInitial || state is AircraftListLoading;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppStrings.aircraftListTitle,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Quiet spinner for in-flight region refetches (pan/zoom) —
                              // the full skeleton below only applies to the first load.
                              if (isRefreshing) ...[
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                failure != null
                                    ? AppStrings.error
                                    : '${visible.length} aircraft',
                                style: AppTextStyles.body(colors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (stale) const StaleDataBanner(),
                      const SizedBox(height: 12),
                      TextField(
                        onChanged: (value) => context
                            .read<AircraftListBloc>()
                            .add(AircraftListSearchChanged(value)),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: AppStrings.searchHint,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: isLoading
                      ? const AircraftListSkeleton()
                      : failure != null
                      ? ConnectivityStateCard(
                          bordered: false,
                          icon: Icons.error_outline,
                          title: AppStrings.somethingWentWrong,
                          subtitle: AppStrings.errorLoadingAircraft,
                          buttonLabel: AppStrings.tryAgain,
                          onRetry: () => context.read<AircraftListBloc>().add(
                            const AircraftListRetryRequested(),
                          ),
                        )
                      : visible.isEmpty
                      ? Center(
                          child: Text(
                            AppStrings.noAircraftInArea,
                            style: AppTextStyles.body(colors.textPrimary),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: visible.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: colors.line),
                          itemBuilder: (context, index) {
                            final aircraft = visible[index];
                            return ListTile(
                              onTap: () =>
                                  context.push('/detail/${aircraft.icao24}'),
                              leading: AircraftMarker(
                                headingDegrees: aircraft.heading ?? 0,
                                onGround: aircraft.onGround,
                                size: 20,
                              ),
                              title: Text(
                                aircraft.callsign ?? aircraft.icao24,
                                style: AppTheme.monospace(
                                  color: colors.textPrimary,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(aircraft.originCountry),
                              trailing: Text(
                                aircraft.onGround
                                    ? AppStrings.onGroundTrailing
                                    : '${aircraft.altitude?.round() ?? '—'} m',
                                style: AppTheme.monospace(
                                  color: colors.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
