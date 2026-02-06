import 'package:jao/src/utils/uuid.dart';
import 'package:test/test.dart';

void main() {
  group('UUID Generation', () {
    test('generateUuidV4 returns valid UUID format', () {
      final uuid = generateUuidV4();

      // UUID v4 format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
      // where x is any hex digit and y is one of 8, 9, a, or b
      expect(uuid.length, equals(36));
      expect(uuid[8], equals('-'));
      expect(uuid[13], equals('-'));
      expect(uuid[18], equals('-'));
      expect(uuid[23], equals('-'));

      // Check version (4)
      expect(uuid[14], equals('4'));

      // Check variant (8, 9, a, or b)
      expect(['8', '9', 'a', 'b'], contains(uuid[19]));
    });

    test('generateUuidV4 returns unique values', () {
      final uuids = List.generate(100, (_) => generateUuidV4());
      final uniqueUuids = uuids.toSet();

      expect(uniqueUuids.length, equals(100));
    });

    test('generateUuidV4 returns lowercase hex', () {
      final uuid = generateUuidV4();
      final hexParts = uuid.replaceAll('-', '');

      expect(hexParts, matches(RegExp(r'^[0-9a-f]{32}$')));
    });
  });
}
