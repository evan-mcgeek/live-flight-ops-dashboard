import 'package:flight_ops_app/core/di/injection.dart';
import 'package:flight_ops_app/domain/repositories/aircraft_repository.dart';
import 'package:flight_ops_app/domain/repositories/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'configureDependencies resolves AircraftRepository and SettingsRepository',
    () async {
      // ponytail: SharedPreferences.getInstance() hits a platform channel with
      // no implementation under flutter test; every other test in this repo
      // that touches SharedPreferences mocks it the same way.
      SharedPreferences.setMockInitialValues({});
      await configureDependencies();

      expect(getIt<AircraftRepository>(), isNotNull);
      expect(getIt<SettingsRepository>(), isNotNull);

      await getIt.reset();
    },
  );
}
