@TestOn('vm')
library;

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:jao_generator/jao_generator.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

/// Integration tests that run the actual generator and verify output.
/// These tests require the full build system and jao package.
void main() {
  group('JaoGenerator Integration', () {
    test('Generator produces output for @Model annotated class', () async {
      final sources = await _createSourcesWithJao('''
@Model()
class User {
  late int id;
  late String name;
}
''');

      final result = await _runGenerator(sources);

      // Should generate field class
      expect(result, contains('class User\$'));
      expect(result, contains('implements ModelFields<User>'));

      // Should generate companion class
      expect(result, contains('class Users'));
    });

    test('Generator handles multiple fields with different types', () async {
      final sources = await _createSourcesWithJao('''
@Model()
class Product {
  late int id;
  late String name;
  late double price;
  late bool inStock;
  late DateTime createdAt;
}
''');

      final result = await _runGenerator(sources);

      expect(result, contains("IntFieldRef('id')"));
      expect(result, contains("StringFieldRef('name')"));
      expect(result, contains("DoubleFieldRef('price')"));
      expect(result, contains("BoolFieldRef('in_stock')"));
      expect(result, contains("DateTimeFieldRef('created_at')"));
    });

    test('Generator respects custom tableName', () async {
      final sources = await _createSourcesWithJao('''
@Model(tableName: 'app_users')
class User {
  late int id;
}
''');

      final result = await _runGenerator(sources);

      expect(result, contains("tableName = 'app_users'"));
    });

    test('Generator handles nullable fields', () async {
      final sources = await _createSourcesWithJao('''
@Model()
class User {
  late int id;
  String? nickname;
  DateTime? deletedAt;
}
''');

      final result = await _runGenerator(sources);

      expect(result, contains('nullable: true'));
      expect(result, contains("as String?"));
    });

    test('Generator handles @AutoField annotation', () async {
      final sources = await _createSourcesWithJao('''
@Model()
class User {
  @AutoField()
  late int id;
}
''');

      final result = await _runGenerator(sources);

      expect(result, contains('primaryKey: true'));
      expect(result, contains('autoIncrement: true'));
    });

    test('Generator handles @DateTimeField with autoNowAdd', () async {
      final sources = await _createSourcesWithJao('''
@Model()
class User {
  late int id;
  @DateTimeField(autoNowAdd: true)
  late DateTime createdAt;
}
''');

      final result = await _runGenerator(sources);

      expect(result, contains('autoNowAdd: true'));
      expect(result, contains("autoNowAddFields:"));
    });

    test('Generator handles @DateTimeField with autoNow', () async {
      final sources = await _createSourcesWithJao('''
@Model()
class User {
  late int id;
  @DateTimeField(autoNow: true)
  late DateTime updatedAt;
}
''');

      final result = await _runGenerator(sources);

      expect(result, contains('autoNow: true'));
      expect(result, contains("autoNowFields:"));
    });

    test('Generator creates proper fromRow for bool fields', () async {
      final sources = await _createSourcesWithJao('''
@Model()
class User {
  late int id;
  late bool isActive;
}
''');

      final result = await _runGenerator(sources);

      // Should handle SQLite int-to-bool conversion
      expect(result, contains("row['is_active'] == 1 || row['is_active'] == true"));
    });

    test('Generator creates proper toRow for DateTime fields', () async {
      final sources = await _createSourcesWithJao('''
@Model()
class User {
  late int id;
  late DateTime createdAt;
}
''');

      final result = await _runGenerator(sources);

      expect(result, contains('.toIso8601String()'));
    });

    test('Generator converts camelCase to snake_case for column names', () async {
      final sources = await _createSourcesWithJao('''
@Model()
class User {
  late int id;
  late String firstName;
  late String lastName;
  late bool isActive;
}
''');

      final result = await _runGenerator(sources);

      expect(result, contains("'first_name'"));
      expect(result, contains("'last_name'"));
      expect(result, contains("'is_active'"));
    });

    test('Generator generates ModelSchema', () async {
      final sources = await _createSourcesWithJao('''
@Model()
class User {
  late int id;
  late String name;
}
''');

      final result = await _runGenerator(sources);

      expect(result, contains('static final schema = ModelSchema('));
      expect(result, contains("className: 'User'"));
      expect(result, contains('fields: ['));
      expect(result, contains('ModelFieldSchema('));
    });

    test('Generator generates Jao.registerModel call', () async {
      final sources = await _createSourcesWithJao('''
@Model()
class User {
  late int id;
}
''');

      final result = await _runGenerator(sources);

      expect(result, contains('Jao.registerModel<User>(ModelRegistration('));
      expect(result, contains('fromRow: fromRow'));
      expect(result, contains('toRow: toRow'));
    });
  }, skip: 'Integration tests require full build system setup');
}

/// Create source files with the jao package stubs
Future<Map<String, String>> _createSourcesWithJao(String modelSource) async {
  return {
    'jao|lib/jao.dart': '''
library jao;

export 'src/model/model.dart';
export 'src/fields/fields.dart';
export 'src/manager.dart';
export 'src/jao.dart';
export 'src/migrations/generator.dart';
''',
    'jao|lib/src/model/model.dart': '''
class Model {
  final String? tableName;
  final bool abstract;
  const Model({this.tableName, this.abstract = false});
}

abstract class ModelFields<T> {
  const ModelFields();
}
''',
    'jao|lib/src/fields/fields.dart': '''
class FieldRef<T> {
  final String column;
  const FieldRef(this.column);
}

class IntFieldRef extends FieldRef<int> {
  const IntFieldRef(super.column);
}

class StringFieldRef extends FieldRef<String> {
  const StringFieldRef(super.column);
}

class BoolFieldRef extends FieldRef<bool> {
  const BoolFieldRef(super.column);
}

class DateTimeFieldRef extends FieldRef<DateTime> {
  const DateTimeFieldRef(super.column);
}

class DoubleFieldRef extends FieldRef<double> {
  const DoubleFieldRef(super.column);
}

class DurationFieldRef extends FieldRef<Duration> {
  const DurationFieldRef(super.column);
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
  const EmailField();
}

class IntegerField {
  const IntegerField();
}

class BooleanField {
  const BooleanField();
}

class FloatField {
  const FloatField();
}

class DecimalField {
  final int precision;
  final int scale;
  const DecimalField({this.precision = 10, this.scale = 2});
}

class DateTimeField {
  final bool autoNowAdd;
  final bool autoNow;
  const DateTimeField({this.autoNowAdd = false, this.autoNow = false});
}

class DateField {
  const DateField();
}

class DurationField {
  const DurationField();
}

class ForeignKey {
  final Type model;
  final String? onDelete;
  const ForeignKey(this.model, {this.onDelete});
}
''',
    'jao|lib/src/manager.dart': '''
class Manager<T> {
  const Manager();
}
''',
    'jao|lib/src/jao.dart': '''
class Jao {
  static void registerModel<T>(ModelRegistration<T> registration) {}
}

class ModelRegistration<T> {
  final String tableName;
  final String pkField;
  final T Function(Map<String, dynamic>) fromRow;
  final Map<String, dynamic> Function(T) toRow;
  final List<String>? autoNowAddFields;
  final List<String>? autoNowFields;

  const ModelRegistration({
    required this.tableName,
    required this.pkField,
    required this.fromRow,
    required this.toRow,
    this.autoNowAddFields,
    this.autoNowFields,
  });
}
''',
    'jao|lib/src/migrations/generator.dart': '''
class ModelSchema {
  final String className;
  final String tableName;
  final List<ModelFieldSchema> fields;

  const ModelSchema({
    required this.className,
    required this.tableName,
    required this.fields,
  });
}

class ModelFieldSchema {
  final String name;
  final String columnName;
  final FieldType dbType;
  final bool nullable;
  final bool primaryKey;
  final bool autoIncrement;
  final bool autoNowAdd;
  final bool autoNow;

  const ModelFieldSchema({
    required this.name,
    required this.columnName,
    required this.dbType,
    this.nullable = false,
    this.primaryKey = false,
    this.autoIncrement = false,
    this.autoNowAdd = false,
    this.autoNow = false,
  });
}

enum FieldType {
  serial,
  bigSerial,
  integer,
  bigInt,
  smallInt,
  varchar,
  text,
  boolean,
  real,
  doublePrecision,
  decimal,
  date,
  timestampTz,
  interval,
  jsonb,
  bytea,
  uuid,
  time,
}
''',
    'pkg|lib/model.dart':
        '''
import 'package:jao/jao.dart';

part 'model.jao.dart';

$modelSource
''',
  };
}

/// Run the generator and return the output
Future<String> _runGenerator(Map<String, String> sources) async {
  final writer = InMemoryAssetWriter();
  await testBuilder(
    SharedPartBuilder([JaoGenerator()], 'jao'),
    sources,
    rootPackage: 'pkg',
    writer: writer,
    reader: await PackageAssetReader.currentIsolate(),
  );

  final outputId = AssetId('pkg', 'lib/model.jao.dart');
  final outputBytes = writer.assets[outputId];
  if (outputBytes == null) {
    throw StateError('No output generated. Assets: ${writer.assets.keys}');
  }
  return String.fromCharCodes(outputBytes);
}
