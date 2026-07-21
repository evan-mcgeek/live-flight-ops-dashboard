import 'package:flight_ops_app/core/theme/app_theme.dart';
import 'package:flight_ops_app/domain/failures/failure.dart';
import 'package:flight_ops_app/domain/settings/app_theme_mode.dart';
import 'package:flight_ops_app/domain/settings/live_update_mode.dart';
import 'package:flight_ops_app/presentation/settings/bloc/settings_bloc.dart';
import 'package:flight_ops_app/presentation/settings/widgets/connection_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, SettingsState state) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(body: ConnectionIndicator(state: state)),
        ),
      );

  testWidgets('shows a spinner and "Connecting…" while connecting', (
    tester,
  ) async {
    await pump(
      tester,
      const SettingsState(
        liveUpdateMode: LiveUpdateMode.standard,
        themeMode: AppThemeMode.dark,
        liveInterval: 5,
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Connecting…'), findsOneWidget);
  });

  testWidgets('shows a dot and "Connected" when connected', (tester) async {
    await pump(
      tester,
      const SettingsState(
        liveUpdateMode: LiveUpdateMode.standard,
        themeMode: AppThemeMode.dark,
        liveInterval: 5,
        connectionStatus: ConnectionConnected(),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Connected'), findsOneWidget);
  });

  testWidgets('shows no indicator and "Error" on connection error', (
    tester,
  ) async {
    await pump(
      tester,
      const SettingsState(
        liveUpdateMode: LiveUpdateMode.standard,
        themeMode: AppThemeMode.dark,
        liveInterval: 5,
        connectionStatus: ConnectionError(NetworkFailure()),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Error'), findsOneWidget);
  });
}
