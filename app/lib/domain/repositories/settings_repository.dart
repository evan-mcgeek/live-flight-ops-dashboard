import 'package:flutter/material.dart' show ThemeMode;

import '../settings/live_update_mode.dart';

abstract interface class SettingsRepository {
  LiveUpdateMode get currentLiveUpdateMode;

  /// Emits the current mode immediately, then every subsequent change.
  Stream<LiveUpdateMode> watchLiveUpdateMode();

  Future<void> setLiveUpdateMode(LiveUpdateMode mode);

  ThemeMode get currentThemeMode;

  /// Emits the current theme immediately, then every subsequent change.
  Stream<ThemeMode> watchThemeMode();

  Future<void> setThemeMode(ThemeMode mode);

  int get currentLiveInterval;

  Future<void> setLiveInterval(int seconds);
}
