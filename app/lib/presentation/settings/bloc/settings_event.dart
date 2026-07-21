part of 'settings_bloc.dart';

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class ThemeModeChanged extends SettingsEvent {
  const ThemeModeChanged(this.mode);

  final AppThemeMode mode;

  @override
  List<Object?> get props => [mode];
}

class LiveUpdateSettingsChanged extends SettingsEvent {
  const LiveUpdateSettingsChanged(this.mode, this.interval);

  final LiveUpdateMode mode;
  final int interval;

  @override
  List<Object?> get props => [mode, interval];
}

class SettingsRegionUpdated extends SettingsEvent {
  const SettingsRegionUpdated(this.regionState);

  final ActiveRegionState regionState;

  @override
  List<Object?> get props => [regionState];
}
