@TestOn('vm')
library;

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:jao_generator/jao_generator.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

/// Integration tests that run the actual generator using testBuilder.
/// These tests verify the generator produces valid output for real Dart sources.
void main() {
  group('JaoGenerator Integration', () {
    late Builder builder;

    setUp(() {
      builder = LibraryBuilder(JaoGenerator(), generatedExtension: '.jao.dart');
    });

    test('Generator produces output for @Model annotated class', () async {
      await testBuilder(
        builder,
        {
          'jao|lib/jao.dart': _jaoStub,
          'pkg|lib/user.dart': '''
import 'package:jao/jao.dart';

@Model()
class User {
  late int id;
  late String name;
}
''',
        },
        outputs: {
          'pkg|lib/user.jao.dart': decodedMatches(
            allOf([contains('class User\$'), contains('implements ModelFields<User>'), contains('class Users')]),
          ),
        },
      );
    });

    test('Generator handles multiple fields with different types', () async {
      await testBuilder(
        builder,
        {
          'jao|lib/jao.dart': _jaoStub,
          'pkg|lib/product.dart': '''
import 'package:jao/jao.dart';

@Model()
class Product {
  late int id;
  late String name;
  late double price;
  late bool inStock;
  late DateTime createdAt;
}
''',
        },
        outputs: {
          'pkg|lib/product.jao.dart': decodedMatches(
            allOf([
              contains("IntFieldRef('id')"),
              contains("StringFieldRef('name')"),
              contains("DoubleFieldRef('price')"),
              contains("BoolFieldRef('in_stock')"),
              contains("DateTimeFieldRef('created_at')"),
            ]),
          ),
        },
      );
    });

    test('Generator respects custom tableName', () async {
      await testBuilder(
        builder,
        {
          'jao|lib/jao.dart': _jaoStub,
          'pkg|lib/user.dart': '''
import 'package:jao/jao.dart';

@Model(tableName: 'app_users')
class User {
  late int id;
}
''',
        },
        outputs: {'pkg|lib/user.jao.dart': decodedMatches(contains("tableName = 'app_users'"))},
      );
    });

    test('Generator handles nullable fields', () async {
      await testBuilder(
        builder,
        {
          'jao|lib/jao.dart': _jaoStub,
          'pkg|lib/user.dart': '''
import 'package:jao/jao.dart';

@Model()
class User {
  late int id;
  String? nickname;
  DateTime? deletedAt;
}
''',
        },
        outputs: {
          'pkg|lib/user.jao.dart': decodedMatches(allOf([contains('nullable: true'), contains("as String?")])),
        },
      );
    });

    test('Generator handles @AutoField annotation', () async {
      await testBuilder(
        builder,
        {
          'jao|lib/jao.dart': _jaoStub,
          'pkg|lib/user.dart': '''
import 'package:jao/jao.dart';

@Model()
class User {
  @AutoField()
  late int id;
}
''',
        },
        outputs: {
          'pkg|lib/user.jao.dart': decodedMatches(
            allOf([contains('primaryKey: true'), contains('autoIncrement: true')]),
          ),
        },
      );
    });

    test('Generator handles @DateTimeField with autoNowAdd', () async {
      await testBuilder(
        builder,
        {
          'jao|lib/jao.dart': _jaoStub,
          'pkg|lib/user.dart': '''
import 'package:jao/jao.dart';

@Model()
class User {
  late int id;
  @DateTimeField(autoNowAdd: true)
  late DateTime createdAt;
}
''',
        },
        outputs: {
          'pkg|lib/user.jao.dart': decodedMatches(allOf([contains('autoNowAdd: true'), contains("autoNowAddFields:")])),
        },
      );
    });

    test('Generator handles @DateTimeField with autoNow', () async {
      await testBuilder(
        builder,
        {
          'jao|lib/jao.dart': _jaoStub,
          'pkg|lib/user.dart': '''
import 'package:jao/jao.dart';

@Model()
class User {
  late int id;
  @DateTimeField(autoNow: true)
  late DateTime updatedAt;
}
''',
        },
        outputs: {
          'pkg|lib/user.jao.dart': decodedMatches(allOf([contains('autoNow: true'), contains("autoNowFields:")])),
        },
      );
    });

    test('Generator creates proper fromRow for bool fields', () async {
      await testBuilder(
        builder,
        {
          'jao|lib/jao.dart': _jaoStub,
          'pkg|lib/user.dart': '''
import 'package:jao/jao.dart';

@Model()
class User {
  late int id;
  late bool isActive;
}
''',
        },
        outputs: {
          'pkg|lib/user.jao.dart': decodedMatches(contains("dbBool(row['is_active'])")),
        },
      );
    });

    test('Generator creates proper toRow for DateTime fields', () async {
      await testBuilder(
        builder,
        {
          'jao|lib/jao.dart': _jaoStub,
          'pkg|lib/user.dart': '''
import 'package:jao/jao.dart';

@Model()
class User {
  late int id;
  late DateTime createdAt;
}
''',
        },
        outputs: {'pkg|lib/user.jao.dart': decodedMatches(contains('.toIso8601String()'))},
      );
    });

    test('Generator converts camelCase to snake_case for column names', () async {
      await testBuilder(
        builder,
        {
          'jao|lib/jao.dart': _jaoStub,
          'pkg|lib/user.dart': '''
import 'package:jao/jao.dart';

@Model()
class User {
  late int id;
  late String firstName;
  late String lastName;
  late bool isActive;
}
''',
        },
        outputs: {
          'pkg|lib/user.jao.dart': decodedMatches(
            allOf([contains("'first_name'"), contains("'last_name'"), contains("'is_active'")]),
          ),
        },
      );
    });

    test('Generator generates ModelSchema', () async {
      await testBuilder(
        builder,
        {
          'jao|lib/jao.dart': _jaoStub,
          'pkg|lib/user.dart': '''
import 'package:jao/jao.dart';

@Model()
class User {
  late int id;
  late String name;
}
''',
        },
        outputs: {
          'pkg|lib/user.jao.dart': decodedMatches(
            allOf([
              contains('static final schema = ModelSchema('),
              contains("className: 'User'"),
              contains('fields: ['),
              contains('ModelFieldSchema('),
            ]),
          ),
        },
      );
    });

    test('Generator generates Jao.registerModel call', () async {
      await testBuilder(
        builder,
        {
          'jao|lib/jao.dart': _jaoStub,
          'pkg|lib/user.dart': '''
import 'package:jao/jao.dart';

@Model()
class User {
  late int id;
}
''',
        },
        outputs: {
          'pkg|lib/user.jao.dart': decodedMatches(
            allOf([
              contains('Jao.registerModel<User>('),
              contains('ModelRegistration('),
              contains('fromRow: fromRow'),
              contains('toRow: toRow'),
            ]),
          ),
        },
      );
    });

    test('Generator handles @ForeignKey and generates relation metadata', () async {
      await testBuilder(
        builder,
        {
          'jao|lib/jao.dart': _jaoStub,
          'pkg|lib/models.dart': '''
import 'package:jao/jao.dart';

@Model()
class Author {
  late int id;
  late String name;
}

@Model()
class Post {
  late int id;
  late String title;
  @ForeignKey(Author)
  late int author;
}
''',
        },
        outputs: {
          'pkg|lib/models.jao.dart': decodedMatches(
            allOf([
              contains('_registerMetadata()'),
              contains('ModelRegistry.instance.register'),
              contains('relations: {'),
              contains("RelationMeta("),
              contains("fieldName: 'author'"),
              contains("relatedModel: Author"),
              contains("RelationType.foreignKey"),
            ]),
          ),
        },
      );
    });

    test('Generator handles @OneToOneField with relation type', () async {
      await testBuilder(
        builder,
        {
          'jao|lib/jao.dart': _jaoStub,
          'pkg|lib/models.dart': '''
import 'package:jao/jao.dart';

@Model()
class User {
  late int id;
}

@Model()
class Profile {
  late int id;
  @OneToOneField(User)
  late int user;
}
''',
        },
        outputs: {
          'pkg|lib/models.jao.dart': decodedMatches(
            allOf([
              contains("RelationMeta("),
              contains("fieldName: 'user'"),
              contains("relatedModel: User"),
              contains("RelationType.oneToOne"),
            ]),
          ),
        },
      );
    });

    test('Generator handles Duration field fromRow/toRow', () async {
      await testBuilder(
        builder,
        {
          'jao|lib/jao.dart': _jaoStub,
          'pkg|lib/task.dart': '''
import 'package:jao/jao.dart';

@Model()
class Task {
  late int id;
  late Duration estimatedTime;
  Duration? actualTime;
}
''',
        },
        outputs: {
          'pkg|lib/task.jao.dart': decodedMatches(
            allOf([
              contains("DurationFieldRef('estimated_time')"),
              contains("dbDuration(row['estimated_time'])"),
              contains("dbDurationOrNull(row['actual_time'])"),
              contains(".inMicroseconds"),
            ]),
          ),
        },
      );
    });

    test('Generator handles @DurationField annotation', () async {
      await testBuilder(
        builder,
        {
          'jao|lib/jao.dart': _jaoStub,
          'pkg|lib/task.dart': '''
import 'package:jao/jao.dart';

@Model()
class Task {
  late int id;
  @DurationField()
  late Duration duration;
}
''',
        },
        outputs: {
          'pkg|lib/task.jao.dart': decodedMatches(
            allOf([
              contains("DurationFieldRef('duration')"),
              contains('dbType: FieldType.interval'),
            ]),
          ),
        },
      );
    });

    test('Generator handles @UuidField annotation', () async {
      await testBuilder(
        builder,
        {
          'jao|lib/jao.dart': _jaoStub,
          'pkg|lib/entity.dart': '''
import 'package:jao/jao.dart';

@Model()
class Entity {
  late int id;
  @UuidField()
  late String uuid;
}
''',
        },
        outputs: {
          'pkg|lib/entity.jao.dart': decodedMatches(
            allOf([
              contains("StringFieldRef('uuid')"),
              contains('dbType: FieldType.uuid'),
            ]),
          ),
        },
      );
    });

    test('Generator handles @JsonField annotation', () async {
      await testBuilder(
        builder,
        {
          'jao|lib/jao.dart': _jaoStub,
          'pkg|lib/config.dart': '''
import 'package:jao/jao.dart';

@Model()
class Config {
  late int id;
  @JsonField()
  late dynamic settings;
}
''',
        },
        outputs: {
          'pkg|lib/config.jao.dart': decodedMatches(
            allOf([
              contains("FieldRef('settings')"),
              contains('dbType: FieldType.jsonb'),
            ]),
          ),
        },
      );
    });

    test('Generator handles @BinaryField annotation', () async {
      await testBuilder(
        builder,
        {
          'jao|lib/jao.dart': _jaoStub,
          'pkg|lib/file.dart': '''
import 'package:jao/jao.dart';

@Model()
class File {
  late int id;
  @BinaryField()
  late List<int> content;
}
''',
        },
        outputs: {
          'pkg|lib/file.jao.dart': decodedMatches(
            allOf([
              contains("FieldRef('content')"),
              contains('dbType: FieldType.bytea'),
            ]),
          ),
        },
      );
    });

    test('Generator handles @TimeField annotation', () async {
      await testBuilder(
        builder,
        {
          'jao|lib/jao.dart': _jaoStub,
          'pkg|lib/schedule.dart': '''
import 'package:jao/jao.dart';

@Model()
class Schedule {
  late int id;
  @TimeField()
  late Duration startTime;
}
''',
        },
        outputs: {
          'pkg|lib/schedule.jao.dart': decodedMatches(
            allOf([
              contains("DurationFieldRef('start_time')"),
              contains('dbType: FieldType.time'),
            ]),
          ),
        },
      );
    });

    test('Generator handles @BigAutoField annotation', () async {
      await testBuilder(
        builder,
        {
          'jao|lib/jao.dart': _jaoStub,
          'pkg|lib/bigmodel.dart': '''
import 'package:jao/jao.dart';

@Model()
class BigModel {
  @BigAutoField()
  late int id;
}
''',
        },
        outputs: {
          'pkg|lib/bigmodel.jao.dart': decodedMatches(
            allOf([
              contains('primaryKey: true'),
              contains('autoIncrement: true'),
              contains('dbType: FieldType.bigSerial'),
            ]),
          ),
        },
      );
    });

    test('Generator handles various field annotations', () async {
      await testBuilder(
        builder,
        {
          'jao|lib/jao.dart': _jaoStub,
          'pkg|lib/allfields.dart': '''
import 'package:jao/jao.dart';

@Model()
class AllFields {
  late int id;
  @CharField()
  late String charField;
  @TextField()
  late String textField;
  @EmailField()
  late String email;
  @UrlField()
  late String url;
  @IntegerField()
  late int intField;
  @SmallIntegerField()
  late int smallInt;
  @BigIntegerField()
  late int bigInt;
  @PositiveIntegerField()
  late int positiveInt;
  @FloatField()
  late double floatField;
  @DecimalField()
  late double decimalField;
  @BooleanField()
  late bool boolField;
  @DateField()
  late DateTime dateField;
}
''',
        },
        outputs: {
          'pkg|lib/allfields.jao.dart': decodedMatches(
            allOf([
              contains('FieldType.varchar'),
              contains('FieldType.text'),
              contains('FieldType.integer'),
              contains('FieldType.smallInt'),
              contains('FieldType.bigInt'),
              contains('FieldType.real'),
              contains('FieldType.decimal'),
              contains('FieldType.boolean'),
              contains('FieldType.date'),
            ]),
          ),
        },
      );
    });

    test('Generator handles @ManyToManyField with relation type', () async {
      await testBuilder(
        builder,
        {
          'jao|lib/jao.dart': _jaoStub,
          'pkg|lib/models.dart': '''
import 'package:jao/jao.dart';

@Model()
class Tag {
  late int id;
  late String name;
}

@Model()
class Article {
  late int id;
  @ManyToManyField(Tag)
  late int tags;
}
''',
        },
        outputs: {
          'pkg|lib/models.jao.dart': decodedMatches(
            allOf([
              contains("RelationMeta("),
              contains("fieldName: 'tags'"),
              contains("relatedModel: Tag"),
              contains("RelationType.manyToMany"),
            ]),
          ),
        },
      );
    });

    test('Generator handles @ForeignKey to model with @UuidPrimaryKey', () async {
      await testBuilder(
        builder,
        {
          'jao|lib/jao.dart': _jaoStub,
          'pkg|lib/models.dart': '''
import 'package:jao/jao.dart';

@Model()
class Organization {
  @UuidPrimaryKey()
  late String id;
  late String name;
}

@Model()
class Employee {
  @AutoField()
  late int id;
  @ForeignKey(Organization)
  late String orgId;
}
''',
        },
        outputs: {
          'pkg|lib/models.jao.dart': decodedMatches(
            allOf([
              contains("final orgId = const StringFieldRef('org_id')"),
              contains("RelationMeta("),
              contains("relatedModel: Organization"),
            ]),
          ),
        },
      );
    });

    test('Generator handles @ForeignKey to model with @AutoField', () async {
      await testBuilder(
        builder,
        {
          'jao|lib/jao.dart': _jaoStub,
          'pkg|lib/models.dart': '''
import 'package:jao/jao.dart';

@Model()
class Author {
  @AutoField()
  late int id;
  late String name;
}

@Model()
class Post {
  @AutoField()
  late int id;
  @ForeignKey(Author)
  late int authorId;
}
''',
        },
        outputs: {
          'pkg|lib/models.jao.dart': decodedMatches(
            allOf([
              contains("final authorId = const IntFieldRef('author_id')"),
              contains("RelationMeta("),
              contains("relatedModel: Author"),
            ]),
          ),
        },
      );
    });

    test('Generator outputs ForeignKeyInfo in schema for FK fields', () async {
      await testBuilder(
        builder,
        {
          'jao|lib/jao.dart': _jaoStub,
          'pkg|lib/models.dart': '''
import 'package:jao/jao.dart';

@Model()
class User {
  @AutoField()
  late int id;
  late String name;
}

@Model()
class Book {
  @AutoField()
  late int id;
  late String title;
  @ForeignKey(User)
  int? creatorId;
}
''',
        },
        outputs: {
          'pkg|lib/models.jao.dart': decodedMatches(
            allOf([
              // Verify schema includes ForeignKeyInfo for FK fields
              contains('foreignKey: ForeignKeyInfo('),
              contains("referencedTable: 'user'"),
              contains("referencedColumn: 'id'"),
              // Verify nullable is true for nullable FK
              contains('nullable: true'),
            ]),
          ),
        },
      );
    });

    test('Generator handles nullable int and double fields', () async {
      await testBuilder(
        builder,
        {
          'jao|lib/jao.dart': _jaoStub,
          'pkg|lib/nullable_model.dart': '''
import 'package:jao/jao.dart';

@Model()
class NullableModel {
  late int id;
  int? nullableInt;
  double? nullableDouble;
}
''',
        },
        outputs: {
          'pkg|lib/nullable_model.jao.dart': decodedMatches(
            allOf([
              contains("dbIntOrNull(row['nullable_int'])"),
              contains("dbDoubleOrNull(row['nullable_double'])"),
            ]),
          ),
        },
      );
    });

    test('Generator handles model without explicit pk uses first field', () async {
      await testBuilder(
        builder,
        {
          'jao|lib/jao.dart': _jaoStub,
          'pkg|lib/uuid_model.dart': '''
import 'package:jao/jao.dart';

@Model()
class UuidModel {
  late String uuid;
  late String name;
}
''',
        },
        outputs: {
          'pkg|lib/uuid_model.jao.dart': decodedMatches(
            allOf([
              contains("pkField = 'uuid'"),
            ]),
          ),
        },
      );
    });

    test('Generator handles nullable BinaryField with default cast', () async {
      await testBuilder(
        builder,
        {
          'jao|lib/jao.dart': _jaoStub,
          'pkg|lib/file_data.dart': '''
import 'package:jao/jao.dart';

@Model()
class FileData {
  late int id;
  @BinaryField()
  List<int>? content;
}
''',
        },
        outputs: {
          'pkg|lib/file_data.jao.dart': decodedMatches(
            allOf([
              contains("as List<int>?"),
            ]),
          ),
        },
      );
    });

    test('Generator handles fields with defaultValue', () async {
      await testBuilder(
        builder,
        {
          'jao|lib/jao.dart': _jaoStub,
          'pkg|lib/article.dart': '''
import 'package:jao/jao.dart';

@Model()
class Article {
  late int id;
  late String title;
  @CharField(maxLength: 50, defaultValue: 'draft')
  late String status;
  @IntegerField(defaultValue: 0)
  late int views;
  @BooleanField(defaultValue: false)
  late bool featured;
  @FloatField(defaultValue: 0.0)
  late double rating;
}
''',
        },
        outputs: {
          'pkg|lib/article.jao.dart': decodedMatches(
            allOf([
              contains("defaultValues: {"),
              contains("'status': 'draft'"),
              contains("'views': 0"),
              contains("'featured': false"),
              contains("'rating': 0.0"),
            ]),
          ),
        },
      );
    });
  });
}

/// Stub of jao package with required annotations for testing.
/// This provides the minimal definitions needed by the generator.
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
  final Object? defaultValue;
  const CharField({this.maxLength = 255, this.defaultValue});
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
  final Object? defaultValue;
  const IntegerField({this.defaultValue});
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
  final Object? defaultValue;
  const FloatField({this.defaultValue});
}

class DecimalField {
  final int maxDigits;
  final int decimalPlaces;
  const DecimalField({this.maxDigits = 10, this.decimalPlaces = 2});
}

class BooleanField {
  final Object? defaultValue;
  const BooleanField({this.defaultValue});
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

class UuidPrimaryKey extends UuidField {
  const UuidPrimaryKey();
}

class JsonField {
  const JsonField();
}

class BinaryField {
  const BinaryField();
}

class ForeignKey {
  final Type to;
  final String toColumn;
  const ForeignKey(this.to, {this.toColumn = 'id'});
}

class OneToOneField {
  final Type to;
  final String toColumn;
  const OneToOneField(this.to, {this.toColumn = 'id'});
}

class ManyToManyField {
  final Type to;
  final String toColumn;
  const ManyToManyField(this.to, {this.toColumn = 'id'});
}
''';
