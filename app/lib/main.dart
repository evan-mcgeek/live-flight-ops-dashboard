import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'domain/repositories/aircraft_repository.dart';
import 'domain/repositories/settings_repository.dart';
import 'presentation/settings/bloc/settings_bloc.dart';
import 'presentation/splash/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  _notifyBackendOfPersistedInterval();
  runApp(const RestartWidget(child: FlightOpsApp()));
}

// One-shot at startup, not on every slider drag — the live-interval setting only takes effect on restart.
void _notifyBackendOfPersistedInterval() {
  final seconds = getIt<SettingsRepository>().currentLiveInterval;
  getIt<AircraftRepository>()
      .updateLiveInterval(seconds)
      .catchError((e) => debugPrint('updateLiveInterval($seconds) failed: $e'));
}

/// Forces a full subtree rebuild (new DI container, fresh blocs) without an OS process kill.
class RestartWidget extends StatefulWidget {
  const RestartWidget({super.key, required this.child});

  final Widget child;

  static Future<void> restartApp(BuildContext context) async {
    final state = context.findAncestorStateOfType<_RestartWidgetState>();
    await getIt.reset();
    await configureDependencies();
    _notifyBackendOfPersistedInterval();
    appRouter = buildAppRouter()..go('/map');
    state?._restart();
  }

  @override
  State<RestartWidget> createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key _key = UniqueKey();

  void _restart() => setState(() => _key = UniqueKey());

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: _key, child: widget.child);
}

class FlightOpsApp extends StatelessWidget {
  const FlightOpsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<SettingsBloc>(),
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          return MaterialApp.router(
            title: 'Live Flight Ops Dashboard',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settingsState.themeMode,
            routerConfig: appRouter,
            builder: (context, child) => SplashPage(child: child!),
          );
        },
      ),
    );
  }
}
