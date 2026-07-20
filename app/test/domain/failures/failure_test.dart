import 'package:flight_ops_app/domain/failures/failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Failure', () {
    test('same failure type and message are equal', () {
      const a = ServerFailure('boom');
      const b = ServerFailure('boom');

      expect(a, equals(b));
    });

    test(
      'different failure types are not equal even with the same message',
      () {
        const a = ServerFailure('boom');
        const b = NetworkFailure('boom');

        expect(a, isNot(equals(b)));
      },
    );

    test('default messages are provided', () {
      expect(const NetworkFailure().message, isNotEmpty);
      expect(const ServerFailure().message, isNotEmpty);
      expect(const NotFoundFailure().message, isNotEmpty);
      expect(const UnknownFailure().message, isNotEmpty);
    });
  });
}
