import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../core/config/api_config.dart';
import '../../domain/entities/aircraft.dart';
import '../../domain/entities/aircraft_snapshot.dart';
import '../../domain/entities/bounding_box.dart';
import '../../domain/failures/failure.dart';
import '../../domain/failures/repository_exception.dart';
import 'dto/aircraft_dto.dart';
import 'dto/aircraft_snapshot_dto.dart';

@lazySingleton
class AircraftRemoteDataSource {
  AircraftRemoteDataSource(this._dio);

  // Must match the backend's allowed set exactly — the Settings slider's stops.
  static const allowedLiveIntervalSeconds = [1, 2, 5, 10, 30, 60, 120];
  static const _liveIntervalHeaderName = 'X-Live-Interval-Seconds';

  final Dio _dio;

  Future<AircraftSnapshot> fetchSnapshot(
    BoundingBox bbox, {
    required int liveIntervalSeconds,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConfig.aircraftPath,
        queryParameters: {
          ApiConfig.laMinParam: bbox.laMin.toString(),
          ApiConfig.loMinParam: bbox.loMin.toString(),
          ApiConfig.laMaxParam: bbox.laMax.toString(),
          ApiConfig.loMaxParam: bbox.loMax.toString(),
        },
        options: Options(
          headers: {_liveIntervalHeaderName: liveIntervalSeconds.toString()},
        ),
      );
      return AircraftSnapshotDto.fromJson(response.data!).toDomain();
    } on DioException catch (e) {
      throw RepositoryException(_mapDioException(e));
    }
  }

  Future<void> updateLiveInterval(int seconds) async {
    try {
      await _dio.post<void>(
        ApiConfig.liveIntervalPath,
        options: Options(
          headers: {_liveIntervalHeaderName: seconds.toString()},
        ),
      );
    } on DioException catch (e) {
      throw RepositoryException(_mapDioException(e));
    }
  }

  Future<Aircraft?> fetchDetail(String icao24) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConfig.aircraftDetailPath(icao24),
      );
      return AircraftDto.fromJson(response.data!).toDomain();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw RepositoryException(_mapDioException(e));
    }
  }

  Failure _mapDioException(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return const NetworkFailure();
    }
    if (e.response != null) {
      return const ServerFailure();
    }
    return const UnknownFailure();
  }
}
