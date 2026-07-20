import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/injection.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_strings.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../shared/connectivity_state_card.dart';
import 'bloc/aircraft_detail_bloc.dart';
import 'widgets/data_card.dart';
import 'widgets/freshness_indicator.dart';
import 'widgets/record_row.dart';

class AircraftDetailPage extends StatelessWidget {
  const AircraftDetailPage({super.key, required this.icao24});

  final String icao24;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AircraftDetailBloc>(param1: icao24),
      child: const _AircraftDetailView(),
    );
  }
}

class _AircraftDetailView extends StatelessWidget {
  const _AircraftDetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(), body: const AircraftDetailContent());
  }
}

// Shared by the full page and the map's bottom sheet — needs its own
// AircraftDetailBloc instance since the bloc is per-instance (@factoryParam).
class AircraftDetailContent extends StatelessWidget {
  const AircraftDetailContent({super.key});

  String? _flightLevel(double? altitudeMeters) {
    if (altitudeMeters == null) return null;
    final flightLevel = (altitudeMeters * 3.28084 / 100).round();
    return 'FL$flightLevel · baro';
  }

  String? _knots(double? velocityMetersPerSecond) {
    if (velocityMetersPerSecond == null) return null;
    final knots = (velocityMetersPerSecond * 1.94384).round();
    return '≈ $knots kt';
  }

  // Hand-rolled — a single fixed local format doesn't need the intl package.
  String _formatLocalTimestamp(DateTime utc) {
    final local = utc.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return BlocBuilder<AircraftDetailBloc, AircraftDetailState>(
      builder: (context, state) {
        return switch (state) {
          AircraftDetailLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          AircraftDetailNotFound() => Center(
            child: Text(
              AppStrings.aircraftNotFound,
              style: AppTextStyles.body(colors.textPrimary),
            ),
          ),
          AircraftDetailError() => ConnectivityStateCard(
            icon: Icons.error_outline,
            title: AppStrings.somethingWentWrong,
            subtitle: AppStrings.errorLoadingDetail,
            buttonLabel: AppStrings.tryAgain,
            onRetry: () => context.read<AircraftDetailBloc>().add(
              const AircraftDetailRequested(),
            ),
          ),
          AircraftDetailLoaded(:final aircraft) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Text(
                    aircraft.callsign ?? aircraft.icao24,
                    style: AppTheme.monospace(
                      color: colors.textPrimary,
                      fontSize: 34,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: colors.accentDim,
                      border: Border.all(
                        color: aircraft.onGround
                            ? colors.ground
                            : colors.accent,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      aircraft.onGround
                          ? AppStrings.onGround
                          : AppStrings.airborne,
                      style: AppTextStyles.badge(
                        aircraft.onGround ? colors.ground : colors.accent,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                aircraft.originCountry,
                style: AppTextStyles.body(colors.textSecondary),
              ),
              const SizedBox(height: 6),
              FreshnessIndicator(lastUpdate: aircraft.lastUpdate),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: DataCard(
                      label: AppStrings.labelAltitude,
                      value: '${aircraft.altitude?.round() ?? '—'} m',
                      subtext: _flightLevel(aircraft.altitude),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DataCard(
                      label: AppStrings.labelVelocity,
                      value: '${aircraft.velocity?.round() ?? '—'} m/s',
                      subtext: _knots(aircraft.velocity),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DataCard(
                label: AppStrings.labelHeading,
                value: '${aircraft.heading?.round() ?? '—'}°',
              ),
              const SizedBox(height: 20),
              RecordRow(label: AppStrings.labelIcao24, value: aircraft.icao24),
              RecordRow(
                label: AppStrings.labelOriginCountry,
                value: aircraft.originCountry,
              ),
              RecordRow(
                label: AppStrings.labelOnGround,
                value: '${aircraft.onGround}',
              ),
              RecordRow(
                label: AppStrings.labelPosition,
                value:
                    '${aircraft.latitude?.toStringAsFixed(3) ?? '—'}, ${aircraft.longitude?.toStringAsFixed(3) ?? '—'}',
              ),
              RecordRow(
                label: AppStrings.labelLastUpdate,
                value: _formatLocalTimestamp(aircraft.lastUpdate),
              ),
            ],
          ),
        };
      },
    );
  }
}
