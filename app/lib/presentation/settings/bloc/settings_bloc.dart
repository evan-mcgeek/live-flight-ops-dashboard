import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/failures/failure.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/settings/live_update_mode.dart';
import '../../active_region/bloc/active_region_bloc.dart';

part 'settings_event.dart';
part 'settings_state.dart';

// dispose required: without it, getIt.reset() leaks the subscription to ActiveRegionBloc's stream.
@Singleton(dispose: disposeSettingsBloc)
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc(this._repository, this._activeRegionBloc)
    : super(
        SettingsState(
          liveUpdateMode: _repository.currentLiveUpdateMode,
          themeMode: _repository.currentThemeMode,
          liveInterval: _repository.currentLiveInterval,
        ),
      ) {
    on<ThemeModeChanged>(_onThemeModeChanged);
    on<SettingsRegionUpdated>(
      (event, emit) => emit(
        state.copyWith(
          connectionStatus: switch (event.regionState) {
            ActiveRegionInitial() => const ConnectionConnecting(),
            ActiveRegionLoading() => const ConnectionConnecting(),
            ActiveRegionLoaded() => const ConnectionConnected(),
            ActiveRegionError(:final failure) => ConnectionError(failure),
          },
        ),
      ),
    );

    // Seed with the current state — .stream only emits future changes.
    add(SettingsRegionUpdated(_activeRegionBloc.state));
    _subscription = _activeRegionBloc.stream.listen(
      (regionState) => add(SettingsRegionUpdated(regionState)),
    );
  }

  final SettingsRepository _repository;
  final ActiveRegionBloc _activeRegionBloc;
  late final StreamSubscription<ActiveRegionState> _subscription;

  Future<void> _onThemeModeChanged(
    ThemeModeChanged event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.setThemeMode(event.mode);
    emit(state.copyWith(themeMode: event.mode));
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}

FutureOr<void> disposeSettingsBloc(SettingsBloc instance) => instance.close();
