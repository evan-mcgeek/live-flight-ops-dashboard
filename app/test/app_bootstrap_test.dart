import 'package:flight_ops_app/core/di/injection.dart';
import 'package:flight_ops_app/domain/entities/aircraft_snapshot.dart';
import 'package:flight_ops_app/domain/entities/bounding_box.dart';
import 'package:flight_ops_app/domain/repositories/aircraft_repository.dart';
import 'package:flight_ops_app/main.dart';
import 'package:flight_ops_app/presentation/active_region/bloc/active_region_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAircraftRepository extends Mock implements AircraftRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('FlightOpsApp builds and shows the initial Map route', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await configureDependencies();

    // Replace the eagerly-constructed real ActiveRegionBloc before the widget tree is built, so mounting Map doesn't drive a real poll loop.
    registerFallbackValue(
      const BoundingBox(laMin: 0, loMin: 0, laMax: 0, loMax: 0),
    );
    final repository = _FakeAircraftRepository();
    when(
      () => repository.watchSnapshot(any()),
    ).thenAnswer((_) => Stream<AircraftSnapshot>.empty());
    getIt.unregister<ActiveRegionBloc>();
    getIt.registerSingleton<ActiveRegionBloc>(ActiveRegionBloc(repository));

    await tester.pumpWidget(const FlightOpsApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);

    await getIt.reset();
  });
}
