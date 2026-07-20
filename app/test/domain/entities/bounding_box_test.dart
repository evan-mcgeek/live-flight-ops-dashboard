import 'package:flight_ops_app/domain/entities/bounding_box.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BoundingBox', () {
    test('two boxes with the same coordinates are equal', () {
      const a = BoundingBox(laMin: 1, loMin: 2, laMax: 3, loMax: 4);
      const b = BoundingBox(laMin: 1, loMin: 2, laMax: 3, loMax: 4);

      expect(a, equals(b));
    });

    test('boxes with different coordinates are not equal', () {
      const a = BoundingBox(laMin: 1, loMin: 2, laMax: 3, loMax: 4);
      const b = BoundingBox(laMin: 1, loMin: 2, laMax: 3, loMax: 5);

      expect(a, isNot(equals(b)));
    });
  });
}
