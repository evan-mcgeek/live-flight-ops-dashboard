import 'dart:convert';

import 'package:dio/dio.dart';

/// Minimal fake HttpClientAdapter for exercising Dio-based data sources
/// without a real network call. Supports one canned response or thrown
/// error per registered path; good enough for this project's two endpoints.
class DioAdapter implements HttpClientAdapter {
  final Map<String, _Canned> _responses = {};

  /// Headers of the most recent request that went through [fetch] — good
  /// enough for a test to assert a specific header made it onto the wire.
  Map<String, dynamic>? lastRequestHeaders;

  void respond({
    required String path,
    required int statusCode,
    required Object data,
    Map<String, String>? queryParameters,
  }) {
    _responses[path] = _Canned(statusCode: statusCode, data: data);
  }

  void throwConnectionError({required String path}) {
    _responses[path] = _Canned(
      statusCode: null,
      data: null,
      error: DioException.connectionError(
        requestOptions: RequestOptions(path: path),
        reason: 'simulated connection error',
      ),
    );
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequestHeaders = options.headers;
    final canned = _responses[options.path];
    if (canned == null) {
      throw StateError(
        'No canned response registered for path ${options.path}',
      );
    }
    if (canned.error != null) {
      throw canned.error!;
    }
    final bytes = utf8.encode(jsonEncode(canned.data));
    return ResponseBody.fromBytes(
      bytes,
      canned.statusCode!,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _Canned {
  _Canned({required this.statusCode, required this.data, this.error});

  final int? statusCode;
  final Object? data;
  final DioException? error;
}
