import 'package:flight_ops_app/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reportFlutterError does not rethrow', () {
    final details = FlutterErrorDetails(
      exception: Exception('boom'),
      stack: StackTrace.current,
    );

    expect(() => reportFlutterError(details), returnsNormally);
  });

  test('reportPlatformError marks the error as handled', () {
    final handled = reportPlatformError(Exception('boom'), StackTrace.current);

    expect(handled, isTrue);
  });
}
