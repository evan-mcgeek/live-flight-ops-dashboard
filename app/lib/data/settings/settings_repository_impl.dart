import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/settings_repository.dart';
import '../../domain/settings/app_theme_mode.dart';
import '../../domain/settings/live_update_mode.dart';

@LazySingleton(as: SettingsRepository)
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._prefs)
    : _liveUpdateMode = _readLiveUpdateMode(_prefs),
      _themeMode = _readThemeMode(_prefs),
      _liveInterval =
          _prefs.getInt(_liveIntervalKey) ?? _defaultLiveIntervalSeconds;

  static const _liveUpdateModeKey = 'live_update_mode';
  static const _themeModeKey = 'theme_mode';
  static const _liveIntervalKey = 'live_interval_seconds';
  static const _defaultLiveIntervalSeconds = 5;

  final SharedPreferences _prefs;
  LiveUpdateMode _liveUpdateMode;
  AppThemeMode _themeMode;
  int _liveInterval;

  final StreamController<LiveUpdateMode> _liveUpdateModeChanges =
      StreamController<LiveUpdateMode>.broadcast();
  final StreamController<AppThemeMode> _themeModeChanges =
      StreamController<AppThemeMode>.broadcast();

  static LiveUpdateMode _readLiveUpdateMode(SharedPreferences prefs) {
    final stored = prefs.getString(_liveUpdateModeKey);
    return LiveUpdateMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => LiveUpdateMode.standard,
    );
  }

  static AppThemeMode _readThemeMode(SharedPreferences prefs) {
    final stored = prefs.getString(_themeModeKey);
    return AppThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => AppThemeMode.dark,
    );
  }

  @override
  LiveUpdateMode get currentLiveUpdateMode => _liveUpdateMode;

  @override
  Stream<LiveUpdateMode> watchLiveUpdateMode() async* {
    yield _liveUpdateMode;
    yield* _liveUpdateModeChanges.stream;
  }

  @override
  Future<void> setLiveUpdateMode(LiveUpdateMode mode) async {
    _liveUpdateMode = mode;
    await _prefs.setString(_liveUpdateModeKey, mode.name);
    _liveUpdateModeChanges.add(mode);
  }

  @override
  AppThemeMode get currentThemeMode => _themeMode;

  @override
  Stream<AppThemeMode> watchThemeMode() async* {
    yield _themeMode;
    yield* _themeModeChanges.stream;
  }

  @override
  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setString(_themeModeKey, mode.name);
    _themeModeChanges.add(mode);
  }

  @override
  int get currentLiveInterval => _liveInterval;

  @override
  Future<void> setLiveInterval(int seconds) async {
    _liveInterval = seconds;
    await _prefs.setInt(_liveIntervalKey, seconds);
  }
}
