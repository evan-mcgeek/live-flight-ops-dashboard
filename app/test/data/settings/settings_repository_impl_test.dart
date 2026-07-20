import 'package:flight_ops_app/data/settings/settings_repository_impl.dart';
import 'package:flight_ops_app/domain/settings/live_update_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsRepositoryImpl', () {
    test(
      'defaults to standard live-update mode and dark theme when nothing is stored',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final repository = SettingsRepositoryImpl(prefs);

        expect(repository.currentLiveUpdateMode, LiveUpdateMode.standard);
        expect(repository.currentThemeMode, ThemeMode.dark);
        expect(repository.currentLiveInterval, 5);
      },
    );

    test(
      'setLiveUpdateMode persists and is reflected in currentLiveUpdateMode',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final repository = SettingsRepositoryImpl(prefs);

        await repository.setLiveUpdateMode(LiveUpdateMode.realtime);

        expect(repository.currentLiveUpdateMode, LiveUpdateMode.realtime);
      },
    );

    test(
      'watchLiveUpdateMode emits the current value immediately, then subsequent changes',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final repository = SettingsRepositoryImpl(prefs);

        final emissions = <LiveUpdateMode>[];
        final subscription = repository.watchLiveUpdateMode().listen(
          emissions.add,
        );

        await Future<void>.delayed(Duration.zero);
        await repository.setLiveUpdateMode(LiveUpdateMode.realtime);
        await Future<void>.delayed(Duration.zero);

        expect(emissions, [LiveUpdateMode.standard, LiveUpdateMode.realtime]);
        await subscription.cancel();
      },
    );

    test(
      'setThemeMode persists and is reflected in currentThemeMode',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final repository = SettingsRepositoryImpl(prefs);

        await repository.setThemeMode(ThemeMode.light);

        expect(repository.currentThemeMode, ThemeMode.light);
      },
    );

    test(
      'setLiveInterval persists and is reflected in currentLiveInterval',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final repository = SettingsRepositoryImpl(prefs);

        await repository.setLiveInterval(30);

        expect(repository.currentLiveInterval, 30);
      },
    );
  });
}
