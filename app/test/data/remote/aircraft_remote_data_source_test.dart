import 'package:dio/dio.dart';
import 'package:flight_ops_app/data/remote/aircraft_remote_data_source.dart';
import 'package:flight_ops_app/domain/entities/bounding_box.dart';
import 'package:flight_ops_app/domain/failures/failure.dart';
import 'package:flight_ops_app/domain/failures/repository_exception.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dio_adapter.dart';

void main() {
  group('AircraftRemoteDataSource', () {
    const bbox = BoundingBox(laMin: 10, loMin: 20, laMax: 30, loMax: 40);

    late Dio dio;
    late DioAdapter adapter;
    late AircraftRemoteDataSource dataSource;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      adapter = DioAdapter();
      dio.httpClientAdapter = adapter;
      dataSource = AircraftRemoteDataSource(dio);
    });

    test(
      'fetchSnapshot builds the query string from the bbox and maps the response',
      () async {
        adapter.respond(
          path: '/aircraft',
          queryParameters: {
            'lamin': '10.0',
            'lomin': '20.0',
            'lamax': '30.0',
            'lomax': '40.0',
          },
          statusCode: 200,
          data: {
            'aircraft': [
              {
                'icao24': 'abc123',
                'callsign': 'TEST1',
                'originCountry': 'Testland',
                'longitude': 1.0,
                'latitude': 2.0,
                'altitude': 3.0,
                'velocity': 4.0,
                'heading': 5.0,
                'onGround': false,
                'lastUpdate': '2026-01-01T12:00:00Z',
              },
            ],
            'stale': false,
          },
        );

        final snapshot = await dataSource.fetchSnapshot(
          bbox,
          liveIntervalSeconds: 5,
        );

        expect(snapshot.aircraft, hasLength(1));
        expect(snapshot.stale, false);
      },
    );

    test(
      'fetchSnapshot attaches the live-interval header with the requested value',
      () async {
        adapter.respond(
          path: '/aircraft',
          statusCode: 200,
          data: {'aircraft': <Map<String, dynamic>>[], 'stale': false},
        );

        await dataSource.fetchSnapshot(bbox, liveIntervalSeconds: 30);

        expect(adapter.lastRequestHeaders?['X-Live-Interval-Seconds'], '30');
      },
    );

    test(
      'fetchSnapshot throws RepositoryException(NetworkFailure) on connection error',
      () async {
        adapter.throwConnectionError(path: '/aircraft');

        expect(
          () => dataSource.fetchSnapshot(bbox, liveIntervalSeconds: 5),
          throwsA(
            isA<RepositoryException>().having(
              (e) => e.failure,
              'failure',
              isA<NetworkFailure>(),
            ),
          ),
        );
      },
    );

    test(
      'fetchSnapshot throws RepositoryException(ServerFailure) on 500',
      () async {
        adapter.respond(
          path: '/aircraft',
          statusCode: 500,
          data: {'title': 'boom'},
        );

        expect(
          () => dataSource.fetchSnapshot(bbox, liveIntervalSeconds: 5),
          throwsA(
            isA<RepositoryException>().having(
              (e) => e.failure,
              'failure',
              isA<ServerFailure>(),
            ),
          ),
        );
      },
    );

    test('fetchDetail returns the aircraft on 200', () async {
      adapter.respond(
        path: '/aircraft/abc123',
        statusCode: 200,
        data: {
          'icao24': 'abc123',
          'callsign': 'TEST1',
          'originCountry': 'Testland',
          'longitude': 1.0,
          'latitude': 2.0,
          'altitude': 3.0,
          'velocity': 4.0,
          'heading': 5.0,
          'onGround': false,
          'lastUpdate': '2026-01-01T12:00:00Z',
        },
      );

      final aircraft = await dataSource.fetchDetail('abc123');

      expect(aircraft, isNotNull);
      expect(aircraft!.icao24, 'abc123');
    });

    test('fetchDetail returns null on 404', () async {
      adapter.respond(
        path: '/aircraft/missing',
        statusCode: 404,
        data: {'title': 'not found'},
      );

      final aircraft = await dataSource.fetchDetail('missing');

      expect(aircraft, isNull);
    });

    test(
      'updateLiveInterval posts to /aircraft/live-interval with the live-interval header',
      () async {
        adapter.respond(
          path: '/aircraft/live-interval',
          statusCode: 200,
          data: {'intervalSeconds': 30},
        );

        await dataSource.updateLiveInterval(30);

        expect(adapter.lastRequestHeaders?['X-Live-Interval-Seconds'], '30');
      },
    );

    test(
      'updateLiveInterval throws RepositoryException(ServerFailure) on 400',
      () async {
        adapter.respond(
          path: '/aircraft/live-interval',
          statusCode: 400,
          data: {'title': 'bad interval'},
        );

        expect(
          () => dataSource.updateLiveInterval(7),
          throwsA(
            isA<RepositoryException>().having(
              (e) => e.failure,
              'failure',
              isA<ServerFailure>(),
            ),
          ),
        );
      },
    );
  });
}
