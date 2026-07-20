import 'package:go_router/go_router.dart';

import '../../presentation/detail/aircraft_detail_page.dart';
import '../../presentation/list/aircraft_list_page.dart';
import '../../presentation/map/map_page.dart';
import '../../presentation/settings/settings_page.dart';
import '../../presentation/shell/app_shell.dart';

// Rebuilt (not reused) on app restart — a fresh GoRouter always starts at initialLocation with no leftover state.
GoRouter appRouter = buildAppRouter();

GoRouter buildAppRouter() => GoRouter(
  initialLocation: '/map',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/map', builder: (context, state) => const MapPage()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/list',
              builder: (context, state) => const AircraftListPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/detail/:icao24',
      builder: (context, state) =>
          AircraftDetailPage(icao24: state.pathParameters['icao24']!),
    ),
  ],
);
