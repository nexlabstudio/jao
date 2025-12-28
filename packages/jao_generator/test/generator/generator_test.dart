@TestOn('vm')
library;

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:jao_generator/jao_generator.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

void main() {
  group('JaoGenerator Tests', () {
    late JaoGenerator generator;

    setUp(() {
      generator = JaoGenerator();
    });

    test('generates output for simple model', () async {
      final result = await _generateForSource(generator, '''
@Model()
class User {
  late int id;
  late String name;
}
''');

      expect(result, contains('class User\$'));
      expect(result, contains('implements ModelFields<User>'));
      expect(result, contains('class Users'));
      expect(result, contains("IntFieldRef('id')"));
      expect(result, contains("StringFieldRef('name')"));
    });

    test('generates output with multiple field types', () async {
      final result = await _generateForSource(generator, '''
@Model()
class Product {
  late int id;
  late String name;
  late double price;
  late bool inStock;
  late DateTime createdAt;
}
''');

      expect(result, contains("IntFieldRef('id')"));
      expect(result, contains("StringFieldRef('name')"));
      expect(result, contains("DoubleFieldRef('price')"));
      expect(result, contains("BoolFieldRef('in_stock')"));
      expect(result, contains("DateTimeFieldRef('created_at')"));
    });

    test('respects custom tableName', () async {
      final result = await _generateForSource(generator, '''
@Model(tableName: 'app_users')
class User {
  late int id;
}
''');

      expect(result, contains("tableName = 'app_users'"));
    });

    test('handles nullable fields', () async {
      final result = await _generateForSource(generator, '''
@Model()
class User {
  late int id;
  String? nickname;
  DateTime? deletedAt;
}
''');

      expect(result, contains('nullable: true'));
      expect(result, contains("as String?"));
      expect(result, contains("row['deleted_at'] == null ? null : DateTime.parse"));
    });

    test('handles @AutoField annotation', () async {
      final result = await _generateForSource(generator, '''
@Model()
class User {
  @AutoField()
  late int id;
}
''');

      expect(result, contains('primaryKey: true'));
      expect(result, contains('autoIncrement: true'));
      expect(result, contains('dbType: FieldType.serial'));
    });

    test('handles @BigAutoField annotation', () async {
      final result = await _generateForSource(generator, '''
@Model()
class User {
  @BigAutoField()
  late int id;
}
''');

      expect(result, contains('primaryKey: true'));
      expect(result, contains('autoIncrement: true'));
      expect(result, contains('dbType: FieldType.bigSerial'));
    });

    test('handles @DateTimeField with autoNowAdd', () async {
      final result = await _generateForSource(generator, '''
@Model()
class User {
  late int id;
  @DateTimeField(autoNowAdd: true)
  late DateTime createdAt;
}
''');

      expect(result, contains('autoNowAdd: true'));
      expect(result, contains("autoNowAddFields:"));
      expect(result, contains("'created_at'"));
    });

    test('handles @DateTimeField with autoNow', () async {
      final result = await _generateForSource(generator, '''
@Model()
class User {
  late int id;
  @DateTimeField(autoNow: true)
  late DateTime updatedAt;
}
''');

      expect(result, contains('autoNow: true'));
      expect(result, contains("autoNowFields:"));
      expect(result, contains("'updated_at'"));
    });

    test('handles @CharField annotation', () async {
      final result = await _generateForSource(generator, '''
@Model()
class User {
  late int id;
  @CharField(maxLength: 100)
  late String name;
}
''');

      expect(result, contains("StringFieldRef('name')"));
      expect(result, contains('dbType: FieldType.varchar'));
    });

    test('handles @TextField annotation', () async {
      final result = await _generateForSource(generator, '''
@Model()
class User {
  late int id;
  @TextField()
  late String bio;
}
''');

      expect(result, contains("StringFieldRef('bio')"));
      expect(result, contains('dbType: FieldType.text'));
    });

    test('handles @IntegerField annotation', () async {
      final result = await _generateForSource(generator, '''
@Model()
class User {
  late int id;
  @IntegerField()
  late int age;
}
''');

      expect(result, contains("IntFieldRef('age')"));
      expect(result, contains('dbType: FieldType.integer'));
    });

    test('handles @BooleanField annotation', () async {
      final result = await _generateForSource(generator, '''
@Model()
class User {
  late int id;
  @BooleanField()
  late bool isActive;
}
''');

      expect(result, contains("BoolFieldRef('is_active')"));
      expect(result, contains('dbType: FieldType.boolean'));
    });

    test('handles @FloatField annotation', () async {
      final result = await _generateForSource(generator, '''
@Model()
class User {
  late int id;
  @FloatField()
  late double rating;
}
''');

      expect(result, contains("DoubleFieldRef('rating')"));
      expect(result, contains('dbType: FieldType.real'));
    });

    test('handles @DecimalField annotation', () async {
      final result = await _generateForSource(generator, '''
@Model()
class Product {
  late int id;
  @DecimalField(maxDigits: 10, decimalPlaces: 2)
  late double price;
}
''');

      expect(result, contains("DoubleFieldRef('price')"));
      expect(result, contains('dbType: FieldType.decimal'));
    });

    test('handles @DurationField annotation', () async {
      final result = await _generateForSource(generator, '''
@Model()
class Task {
  late int id;
  @DurationField()
  late Duration duration;
}
''');

      expect(result, contains("DurationFieldRef('duration')"));
      expect(result, contains('dbType: FieldType.interval'));
      expect(result, contains("Duration(microseconds: row['duration'] as int)"));
      expect(result, contains('.inMicroseconds'));
    });

    test('handles Duration type inference', () async {
      final result = await _generateForSource(generator, '''
@Model()
class Task {
  late int id;
  late Duration duration;
}
''');

      expect(result, contains("DurationFieldRef('duration')"));
    });

    test('converts camelCase to snake_case for column names', () async {
      final result = await _generateForSource(generator, '''
@Model()
class User {
  late int id;
  late String firstName;
  late String lastName;
  late bool isActive;
}
''');

      expect(result, contains("'first_name'"));
      expect(result, contains("'last_name'"));
      expect(result, contains("'is_active'"));
    });

    test('generates fromRow for bool fields correctly', () async {
      final result = await _generateForSource(generator, '''
@Model()
class User {
  late int id;
  late bool isActive;
}
''');

      expect(result, contains("row['is_active'] == 1 || row['is_active'] == true"));
    });

    test('generates fromRow for nullable bool fields correctly', () async {
      final result = await _generateForSource(generator, '''
@Model()
class User {
  late int id;
  bool? isActive;
}
''');

      expect(result, contains("row['is_active'] == null ? null :"));
    });

    test('generates toRow for DateTime fields correctly', () async {
      final result = await _generateForSource(generator, '''
@Model()
class User {
  late int id;
  late DateTime createdAt;
}
''');

      expect(result, contains('.toIso8601String()'));
    });

    test('generates toRow for nullable DateTime fields correctly', () async {
      final result = await _generateForSource(generator, '''
@Model()
class User {
  late int id;
  DateTime? deletedAt;
}
''');

      expect(result, contains('?.toIso8601String()'));
    });

    test('generates ModelSchema correctly', () async {
      final result = await _generateForSource(generator, '''
@Model()
class User {
  late int id;
  late String name;
}
''');

      expect(result, contains('static final schema = ModelSchema('));
      expect(result, contains("className: 'User'"));
      expect(result, contains("tableName: 'user'"));
      expect(result, contains('fields: ['));
      expect(result, contains('ModelFieldSchema('));
    });

    test('generates Jao.registerModel call correctly', () async {
      final result = await _generateForSource(generator, '''
@Model()
class User {
  late int id;
}
''');

      expect(result, contains('Jao.registerModel<User>('));
      expect(result, contains('ModelRegistration('));
      expect(result, contains('tableName: tableName'));
      expect(result, contains('pkField: pkField'));
      expect(result, contains('fromRow: fromRow'));
      expect(result, contains('toRow: toRow'));
    });

    test('generates fieldNames list correctly', () async {
      final result = await _generateForSource(generator, '''
@Model()
class User {
  late int id;
  late String name;
  late String email;
}
''');

      expect(result, contains("static const fieldNames = ["));
      expect(result, contains("'id',"));
      expect(result, contains("'name',"));
      expect(result, contains("'email',"));
    });

    test('identifies primary key field correctly', () async {
      final result = await _generateForSource(generator, '''
@Model()
class User {
  late int id;
  late String name;
}
''');

      expect(result, contains("static const pkField = 'id'"));
    });

    test('skips static fields', () async {
      final result = await _generateForSource(generator, '''
@Model()
class User {
  static const tableName = 'users';
  late int id;
  late String name;
}
''');

      expect(result, isNot(contains("'tableName',")));
      expect(result, contains("'id',"));
      expect(result, contains("'name',"));
    });
  });
}

/// Stub of jao package with required annotations for testing.
const _jaoStub = '''
class Model {
  final String? tableName;
  const Model({this.tableName});
}

class AutoField {
  const AutoField();
}

class BigAutoField {
  const BigAutoField();
}

class CharField {
  final int maxLength;
  const CharField({this.maxLength = 255});
}

class TextField {
  const TextField();
}

class EmailField {
  final int maxLength;
  const EmailField({this.maxLength = 254});
}

class UrlField {
  final int maxLength;
  const UrlField({this.maxLength = 200});
}

class IntegerField {
  const IntegerField();
}

class SmallIntegerField {
  const SmallIntegerField();
}

class BigIntegerField {
  const BigIntegerField();
}

class PositiveIntegerField {
  const PositiveIntegerField();
}

class FloatField {
  const FloatField();
}

class DecimalField {
  final int maxDigits;
  final int decimalPlaces;
  const DecimalField({this.maxDigits = 10, this.decimalPlaces = 2});
}

class BooleanField {
  const BooleanField();
}

class DateField {
  final bool autoNowAdd;
  final bool autoNow;
  const DateField({this.autoNowAdd = false, this.autoNow = false});
}

class DateTimeField {
  final bool autoNowAdd;
  final bool autoNow;
  const DateTimeField({this.autoNowAdd = false, this.autoNow = false});
}

class DurationField {
  const DurationField();
}

class TimeField {
  const TimeField();
}

class UuidField {
  const UuidField();
}

class JsonField {
  const JsonField();
}

class BinaryField {
  const BinaryField();
}

class ForeignKey {
  final Type to;
  const ForeignKey(this.to);
}

class OneToOneField {
  final Type to;
  const OneToOneField(this.to);
}
''';

/// Helper to generate output by calling the generator directly.
/// This ensures coverage is captured.
Future<String> _generateForSource(JaoGenerator generator, String modelSource) async {
  final sources = {
    'jao|lib/jao.dart': _jaoStub,
    'pkg|lib/model.dart': '''
import 'package:jao/jao.dart';

$modelSource
''',
  };

  final library = await resolveSources(
    sources,
    (resolver) async {
      final assetId = AssetId('pkg', 'lib/model.dart');
      return resolver.libraryFor(assetId);
    },
  );

  final libraryReader = LibraryReader(library);
  final modelChecker = TypeChecker.fromUrl('package:jao/jao.dart#Model');

  final buffer = StringBuffer();
  for (final annotated in libraryReader.annotatedWith(modelChecker)) {
    buffer.writeln(generator.generateForAnnotatedElement(
      annotated.element,
      annotated.annotation,
      _FakeBuildStep(),
    ));
  }

  return buffer.toString();
}

/// Fake BuildStep for testing - generator doesn't actually use it.
class _FakeBuildStep implements BuildStep {
  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError('FakeBuildStep.${invocation.memberName}');
}
