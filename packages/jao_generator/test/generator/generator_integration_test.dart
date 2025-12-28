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
          'pkg|lib/user.jao.dart': decodedMatches(contains("row['is_active'] == 1 || row['is_active'] == true")),
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
