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
      expect(result, contains("dbDateTimeOrNull(row['deleted_at'])"));
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
      expect(result, contains("dbDuration(row['duration'])"));
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

      expect(result, contains("dbBool(row['is_active'])"));
    });

    test('generates fromRow for nullable bool fields correctly', () async {
      final result = await _generateForSource(generator, '''
@Model()
class User {
  late int id;
  bool? isActive;
}
''');

      expect(result, contains("dbBoolOrNull(row['is_active'])"));
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

    test('emits maxLength in ModelFieldSchema for CharField', () async {
      final result = await _generateForSource(generator, '''
@Model()
class User {
  @AutoField()
  late int id;
  @CharField(maxLength: 100)
  late String name;
}
''');

      expect(result, contains('maxLength: 100'));
    });

    test('emits maxLength in ModelFieldSchema for EmailField', () async {
      final result = await _generateForSource(generator, '''
@Model()
class User {
  @AutoField()
  late int id;
  @EmailField(unique: true)
  late String email;
}
''');

      expect(result, contains('maxLength: 254'));
      expect(result, contains('unique: true'));
    });

    test('emits unique constraint in ModelFieldSchema', () async {
      final result = await _generateForSource(generator, '''
@Model()
class User {
  @AutoField()
  late int id;
  @CharField(maxLength: 255, unique: true)
  late String username;
}
''');

      expect(result, contains('unique: true'));
    });

    test('emits defaultValue in ModelFieldSchema for BooleanField', () async {
      final result = await _generateForSource(generator, '''
@Model()
class User {
  @AutoField()
  late int id;
  @BooleanField(defaultValue: false)
  late bool isActive;
}
''');

      expect(result, contains("defaultValue: false"));
    });

    test('emits defaultValue in ModelFieldSchema for CharField', () async {
      final result = await _generateForSource(generator, '''
@Model()
class User {
  @AutoField()
  late int id;
  @CharField(maxLength: 20, defaultValue: 'production')
  late String target;
}
''');

      expect(result, contains("defaultValue: 'production'"));
    });

    test('emits defaultValue in ModelFieldSchema for TextField', () async {
      final result = await _generateForSource(generator, '''
@Model()
class User {
  @AutoField()
  late int id;
  @TextField(defaultValue: '{}')
  late String meta;
}
''');

      expect(result, contains("defaultValue: '{}'"));
    });

    test('emits precision and scale in ModelFieldSchema for DecimalField', () async {
      final result = await _generateForSource(generator, '''
@Model()
class Product {
  @AutoField()
  late int id;
  @DecimalField(maxDigits: 12, decimalPlaces: 4)
  late double price;
}
''');

      expect(result, contains('precision: 12'));
      expect(result, contains('scale: 4'));
    });

    test('emits onDelete in ForeignKeyInfo', () async {
      final result = await _generateForSource(generator, '''
@Model()
class Post {
  @AutoField()
  late int id;
  @ForeignKey(User, onDelete: OnDelete.cascade)
  late int userId;
}

class User {}
''');

      expect(result, contains('onDelete: OnDeleteAction.cascade'));
    });

    test('emits ForeignKeyInfo with referencedTable and referencedColumn', () async {
      final result = await _generateForSource(generator, '''
@Model()
class Post {
  @AutoField()
  late int id;
  @ForeignKey(User)
  late int userId;
}

class User {}
''');

      expect(result, contains("referencedTable: 'user'"));
      expect(result, contains("referencedColumn: 'id'"));
      expect(result, contains('onDelete: OnDeleteAction.cascade'));
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
  final bool unique;
  final Object? defaultValue;
  const CharField({this.maxLength = 255, this.unique = false, this.defaultValue});
}

class TextField {
  final bool unique;
  final Object? defaultValue;
  const TextField({this.unique = false, this.defaultValue});
}

class EmailField {
  final int maxLength;
  final bool unique;
  final Object? defaultValue;
  const EmailField({this.maxLength = 254, this.unique = false, this.defaultValue});
}

class UrlField {
  final int maxLength;
  final bool unique;
  final Object? defaultValue;
  const UrlField({this.maxLength = 2048, this.unique = false, this.defaultValue});
}

class IntegerField {
  final bool unique;
  final Object? defaultValue;
  const IntegerField({this.unique = false, this.defaultValue});
}

class SmallIntegerField {
  final bool unique;
  final Object? defaultValue;
  const SmallIntegerField({this.unique = false, this.defaultValue});
}

class BigIntegerField {
  final bool unique;
  final Object? defaultValue;
  const BigIntegerField({this.unique = false, this.defaultValue});
}

class PositiveIntegerField {
  final bool unique;
  final Object? defaultValue;
  const PositiveIntegerField({this.unique = false, this.defaultValue});
}

class FloatField {
  final bool unique;
  final Object? defaultValue;
  const FloatField({this.unique = false, this.defaultValue});
}

class DecimalField {
  final int maxDigits;
  final int decimalPlaces;
  final bool unique;
  final Object? defaultValue;
  const DecimalField({this.maxDigits = 10, this.decimalPlaces = 2, this.unique = false, this.defaultValue});
}

class BooleanField {
  final Object? defaultValue;
  const BooleanField({this.defaultValue});
}

class DateField {
  final bool autoNowAdd;
  final bool autoNow;
  final Object? defaultValue;
  const DateField({this.autoNowAdd = false, this.autoNow = false, this.defaultValue});
}

class DateTimeField {
  final bool autoNowAdd;
  final bool autoNow;
  final Object? defaultValue;
  const DateTimeField({this.autoNowAdd = false, this.autoNow = false, this.defaultValue});
}

class DurationField {
  final Object? defaultValue;
  const DurationField({this.defaultValue});
}

class TimeField {
  final Object? defaultValue;
  const TimeField({this.defaultValue});
}

class UuidField {
  final bool autoGenerate;
  final bool unique;
  final Object? defaultValue;
  const UuidField({this.autoGenerate = false, this.unique = false, this.defaultValue});
}

class UuidPrimaryKey {
  const UuidPrimaryKey();
}

class JsonField {
  final Object? defaultValue;
  const JsonField({this.defaultValue});
}

class BinaryField {
  const BinaryField();
}

enum OnDelete { cascade, protect, setNull, setDefault, doNothing }

class ForeignKey {
  final Type to;
  final OnDelete onDelete;
  final bool unique;
  const ForeignKey(this.to, {this.onDelete = OnDelete.cascade, this.unique = false});
}

class OneToOneField {
  final Type to;
  final OnDelete onDelete;
  const OneToOneField(this.to, {this.onDelete = OnDelete.cascade});
}

class EnumField<T> {
  final bool storeAsInt;
  final bool unique;
  final Object? defaultValue;
  const EnumField({this.storeAsInt = false, this.unique = false, this.defaultValue});
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
