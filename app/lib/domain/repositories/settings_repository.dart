import '../settings/app_theme_mode.dart';
import '../settings/live_update_mode.dart';

abstract interface class SettingsRepository {
  LiveUpdateMode get currentLiveUpdateMode;

  /// Emits the current mode immediately, then every subsequent change.
  Stream<LiveUpdateMode> watchLiveUpdateMode();

  Future<void> setLiveUpdateMode(LiveUpdateMode mode);

  AppThemeMode get currentThemeMode;

  /// Emits the current theme immediately, then every subsequent change.
  Stream<AppThemeMode> watchThemeMode();

  Future<void> setThemeMode(AppThemeMode mode);

  int get currentLiveInterval;

  Future<void> setLiveInterval(int seconds);
}
