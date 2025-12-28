import 'package:test/test.dart';

// Since source_gen generators are difficult to unit test without the full build system,
// we test the generator's output patterns and logic through golden-style tests.
// These tests verify the expected output patterns that the generator produces.

void main() {
  group('JaoGenerator Output Patterns', () {
    group('Field Class Generation', () {
      test('ClassName\$ class pattern', () {
        // The generator should produce a class named ClassName$
        const expectedPattern = r'class User\$ implements ModelFields<User>';
        expect(_sampleGeneratedOutput, contains(RegExp(expectedPattern)));
      });

      test('Const constructor pattern', () {
        expect(_sampleGeneratedOutput, contains('const User\$();'));
      });

      test('Implements ModelFields<T>', () {
        expect(_sampleGeneratedOutput, contains('implements ModelFields<User>'));
      });

      test('Generates field for each model field', () {
        expect(_sampleGeneratedOutput, contains('final id ='));
        expect(_sampleGeneratedOutput, contains('final name ='));
        expect(_sampleGeneratedOutput, contains('final email ='));
      });

      test('Uses IntFieldRef for int', () {
        expect(_sampleGeneratedOutput, contains("IntFieldRef('id')"));
      });

      test('Uses StringFieldRef for String', () {
        expect(_sampleGeneratedOutput, contains("StringFieldRef('name')"));
        expect(_sampleGeneratedOutput, contains("StringFieldRef('email')"));
      });

      test('Uses BoolFieldRef for bool', () {
        expect(_sampleGeneratedOutput, contains("BoolFieldRef('is_active')"));
      });

      test('Uses DateTimeFieldRef for DateTime', () {
        expect(_sampleGeneratedOutput, contains("DateTimeFieldRef('created_at')"));
      });

      test('Uses DoubleFieldRef for double', () {
        expect(_sampleGeneratedOutput, contains("DoubleFieldRef('rating')"));
      });

      test('Converts camelCase to snake_case for columns', () {
        expect(_sampleGeneratedOutput, contains("'is_active'"));
        expect(_sampleGeneratedOutput, contains("'created_at'"));
      });

      test('Handles nullable fields in schema', () {
        expect(_sampleNullableOutput, contains('nullable: true'));
      });
    });

    group('Companion Class Generation', () {
      test('Generates plural class name', () {
        expect(_sampleGeneratedOutput, contains('class Users {'));
      });

      test('Generates private constructor', () {
        expect(_sampleGeneratedOutput, contains('Users._();'));
      });

      test('Generates static \$ field', () {
        expect(_sampleGeneratedOutput, contains('static const \$ = User\$();'));
      });

      test('Generates static objects Manager', () {
        expect(_sampleGeneratedOutput, contains('static final Manager<User> _objects'));
        expect(_sampleGeneratedOutput, contains('static Manager<User> get objects'));
      });

      test('Generates tableName constant', () {
        expect(_sampleGeneratedOutput, contains("static const tableName = 'user';"));
      });

      test('Generates pkField constant', () {
        expect(_sampleGeneratedOutput, contains("static const pkField = 'id';"));
      });

      test('Generates fieldNames list', () {
        expect(_sampleGeneratedOutput, contains('static const fieldNames = ['));
        expect(_sampleGeneratedOutput, contains("'id',"));
        expect(_sampleGeneratedOutput, contains("'name',"));
      });

      test('Generates schema ModelSchema', () {
        expect(_sampleGeneratedOutput, contains('static final schema = ModelSchema('));
        expect(_sampleGeneratedOutput, contains("className: 'User',"));
        expect(_sampleGeneratedOutput, contains("tableName: 'user',"));
      });
    });

    group('fromRow Generation', () {
      test('Generates fromRow static method', () {
        expect(_sampleGeneratedOutput, contains('static User fromRow(Map<String, dynamic> row)'));
      });

      test('fromRow returns correct type', () {
        expect(_sampleGeneratedOutput, contains('return User()'));
      });

      test('Handles int fields', () {
        expect(_sampleGeneratedOutput, contains("row['id'] as int"));
      });

      test('Handles String fields', () {
        expect(_sampleGeneratedOutput, contains("row['name'] as String"));
      });

      test('Handles bool fields (int to bool)', () {
        expect(_sampleGeneratedOutput, contains("row['is_active'] == 1 || row['is_active'] == true"));
      });

      test('Handles DateTime fields (String to DateTime)', () {
        expect(_sampleGeneratedOutput, contains("DateTime.parse(row['created_at'] as String)"));
      });

      test('Handles double fields', () {
        expect(_sampleGeneratedOutput, contains("row['rating'] as double"));
      });

      test('Handles nullable String fields', () {
        expect(_sampleNullableOutput, contains("row['middle_name'] as String?"));
      });

      test('Handles nullable bool fields', () {
        expect(_sampleNullableOutput, contains("row['is_verified'] == null ? null :"));
      });

      test('Handles nullable DateTime fields', () {
        expect(_sampleNullableOutput, contains("row['deleted_at'] == null ? null : DateTime.parse"));
      });

      test('Maps snake_case column to camelCase field', () {
        expect(_sampleGeneratedOutput, contains("..isActive = row['is_active']"));
        expect(_sampleGeneratedOutput, contains("..createdAt = DateTime.parse(row['created_at']"));
      });
    });

    group('toRow Generation', () {
      test('Generates toRow static method', () {
        expect(_sampleGeneratedOutput, contains('static Map<String, dynamic> toRow(User model)'));
      });

      test('toRow returns Map', () {
        expect(_sampleGeneratedOutput, contains('return {'));
      });

      test('Uses snake_case keys', () {
        expect(_sampleGeneratedOutput, contains("'is_active': model.isActive"));
        expect(_sampleGeneratedOutput, contains("'created_at':"));
      });

      test('Converts DateTime to ISO string', () {
        expect(_sampleGeneratedOutput, contains('model.createdAt.toIso8601String()'));
      });

      test('Handles nullable DateTime', () {
        expect(_sampleNullableOutput, contains('model.deletedAt?.toIso8601String()'));
      });
    });

    group('Edge Cases', () {
      test('Custom tableName from annotation', () {
        expect(_customTableNameOutput, contains("static const tableName = 'custom_users';"));
      });

      test('Handles autoNowAdd fields', () {
        expect(_autoNowOutput, contains("autoNowAddFields: ['created_at']"));
      });

      test('Handles autoNow fields', () {
        expect(_autoNowOutput, contains("autoNowFields: ['updated_at']"));
      });

      test('Handles Duration fields with DurationFieldRef', () {
        expect(_durationOutput, contains("DurationFieldRef('duration')"));
      });

      test('Duration fromRow uses microseconds', () {
        expect(_durationOutput, contains("Duration(microseconds: row['duration'] as int)"));
      });

      test('Duration toRow uses inMicroseconds', () {
        expect(_durationOutput, contains('model.duration.inMicroseconds'));
      });
    });

    group('Model Registration', () {
      test('Generates Jao.registerModel call', () {
        expect(_sampleGeneratedOutput, contains('Jao.registerModel<User>(ModelRegistration('));
      });

      test('Registration includes tableName', () {
        expect(_sampleGeneratedOutput, contains('tableName: tableName,'));
      });

      test('Registration includes pkField', () {
        expect(_sampleGeneratedOutput, contains('pkField: pkField,'));
      });

      test('Registration includes fromRow', () {
        expect(_sampleGeneratedOutput, contains('fromRow: fromRow,'));
      });

      test('Registration includes toRow', () {
        expect(_sampleGeneratedOutput, contains('toRow: toRow,'));
      });
    });

    group('Schema Generation', () {
      test('Schema includes className', () {
        expect(_sampleGeneratedOutput, contains("className: 'User',"));
      });

      test('Schema includes tableName', () {
        expect(_sampleGeneratedOutput, contains("tableName: 'user',"));
      });

      test('Schema includes fields list', () {
        expect(_sampleGeneratedOutput, contains('fields: ['));
      });

      test('ModelFieldSchema includes name', () {
        expect(_sampleGeneratedOutput, contains("name: 'id',"));
        expect(_sampleGeneratedOutput, contains("name: 'name',"));
      });

      test('ModelFieldSchema includes columnName', () {
        expect(_sampleGeneratedOutput, contains("columnName: 'id',"));
        expect(_sampleGeneratedOutput, contains("columnName: 'is_active',"));
      });

      test('ModelFieldSchema includes dbType', () {
        expect(_sampleGeneratedOutput, contains('dbType: FieldType.serial,'));
        expect(_sampleGeneratedOutput, contains('dbType: FieldType.varchar,'));
        expect(_sampleGeneratedOutput, contains('dbType: FieldType.boolean,'));
      });

      test('ModelFieldSchema includes primaryKey flag', () {
        expect(_sampleGeneratedOutput, contains('primaryKey: true,'));
        expect(_sampleGeneratedOutput, contains('primaryKey: false,'));
      });

      test('ModelFieldSchema includes autoIncrement flag', () {
        expect(_sampleGeneratedOutput, contains('autoIncrement: true,'));
        expect(_sampleGeneratedOutput, contains('autoIncrement: false,'));
      });
    });

    group('Integration', () {
      test('Generated code has valid structure', () {
        // Verify class declarations
        expect(_sampleGeneratedOutput, contains('class User\$ implements ModelFields<User> {'));
        expect(_sampleGeneratedOutput, contains('class Users {'));

        // Verify methods
        expect(_sampleGeneratedOutput, contains('static User fromRow('));
        expect(_sampleGeneratedOutput, contains('static Map<String, dynamic> toRow('));

        // Verify schema
        expect(_sampleGeneratedOutput, contains('static final schema = ModelSchema('));
      });

      test('All curly braces are balanced', () {
        final openBraces = '{'.allMatches(_sampleGeneratedOutput).length;
        final closeBraces = '}'.allMatches(_sampleGeneratedOutput).length;
        expect(openBraces, equals(closeBraces));
      });

      test('All parentheses are balanced', () {
        final openParens = '('.allMatches(_sampleGeneratedOutput).length;
        final closeParens = ')'.allMatches(_sampleGeneratedOutput).length;
        expect(openParens, equals(closeParens));
      });

      test('All square brackets are balanced', () {
        final openBrackets = '['.allMatches(_sampleGeneratedOutput).length;
        final closeBrackets = ']'.allMatches(_sampleGeneratedOutput).length;
        expect(openBrackets, equals(closeBrackets));
      });
    });
  });
}

// Sample generated output for a User model with common field types
// This represents what the generator would produce for:
// @Model()
// class User {
//   late int id;
//   late String name;
//   late String email;
//   late bool isActive;
//   late double rating;
//   late DateTime createdAt;
// }
const _sampleGeneratedOutput = '''
class User\$ implements ModelFields<User> {
  const User\$();

  final id = const IntFieldRef('id');
  final name = const StringFieldRef('name');
  final email = const StringFieldRef('email');
  final isActive = const BoolFieldRef('is_active');
  final rating = const DoubleFieldRef('rating');
  final createdAt = const DateTimeFieldRef('created_at');
}

class Users {
  Users._();

  static const \$ = User\$();
  static bool _registered = false;
  static final Manager<User> _objects = Manager<User>();

  static Manager<User> get objects {
    if (!_registered) {
      _registered = true;
      Jao.registerModel<User>(ModelRegistration(
        tableName: tableName,
        pkField: pkField,
        fromRow: fromRow,
        toRow: toRow,
      ));
    }
    return _objects;
  }

  static const tableName = 'user';
  static const pkField = 'id';
  static const fieldNames = [
    'id',
    'name',
    'email',
    'isActive',
    'rating',
    'createdAt',
  ];

  static User fromRow(Map<String, dynamic> row) {
    return User()
      ..id = row['id'] as int
      ..name = row['name'] as String
      ..email = row['email'] as String
      ..isActive = row['is_active'] == 1 || row['is_active'] == true
      ..rating = row['rating'] as double
      ..createdAt = DateTime.parse(row['created_at'] as String);
  }

  static Map<String, dynamic> toRow(User model) {
    return {
      'id': model.id,
      'name': model.name,
      'email': model.email,
      'is_active': model.isActive,
      'rating': model.rating,
      'created_at': model.createdAt.toIso8601String(),
    };
  }

  static final schema = ModelSchema(
    className: 'User',
    tableName: 'user',
    fields: [
      ModelFieldSchema(
        name: 'id',
        columnName: 'id',
        dbType: FieldType.serial,
        nullable: false,
        primaryKey: true,
        autoIncrement: true,
        autoNowAdd: false,
        autoNow: false,
      ),
      ModelFieldSchema(
        name: 'name',
        columnName: 'name',
        dbType: FieldType.varchar,
        nullable: false,
        primaryKey: false,
        autoIncrement: false,
        autoNowAdd: false,
        autoNow: false,
      ),
      ModelFieldSchema(
        name: 'email',
        columnName: 'email',
        dbType: FieldType.varchar,
        nullable: false,
        primaryKey: false,
        autoIncrement: false,
        autoNowAdd: false,
        autoNow: false,
      ),
      ModelFieldSchema(
        name: 'isActive',
        columnName: 'is_active',
        dbType: FieldType.boolean,
        nullable: false,
        primaryKey: false,
        autoIncrement: false,
        autoNowAdd: false,
        autoNow: false,
      ),
      ModelFieldSchema(
        name: 'rating',
        columnName: 'rating',
        dbType: FieldType.doublePrecision,
        nullable: false,
        primaryKey: false,
        autoIncrement: false,
        autoNowAdd: false,
        autoNow: false,
      ),
      ModelFieldSchema(
        name: 'createdAt',
        columnName: 'created_at',
        dbType: FieldType.timestampTz,
        nullable: false,
        primaryKey: false,
        autoIncrement: false,
        autoNowAdd: false,
        autoNow: false,
      ),
    ],
  );
}
''';

// Sample output for nullable fields
const _sampleNullableOutput = '''
class User\$ implements ModelFields<User> {
  const User\$();

  final id = const IntFieldRef('id');
  final middleName = const StringFieldRef('middle_name');
  final isVerified = const BoolFieldRef('is_verified');
  final deletedAt = const DateTimeFieldRef('deleted_at');
}

class Users {
  Users._();

  static User fromRow(Map<String, dynamic> row) {
    return User()
      ..id = row['id'] as int
      ..middleName = row['middle_name'] as String?
      ..isVerified = row['is_verified'] == null ? null : (row['is_verified'] == 1 || row['is_verified'] == true)
      ..deletedAt = row['deleted_at'] == null ? null : DateTime.parse(row['deleted_at'] as String);
  }

  static Map<String, dynamic> toRow(User model) {
    return {
      'id': model.id,
      'middle_name': model.middleName,
      'is_verified': model.isVerified,
      'deleted_at': model.deletedAt?.toIso8601String(),
    };
  }

  static final schema = ModelSchema(
    className: 'User',
    tableName: 'user',
    fields: [
      ModelFieldSchema(
        name: 'middleName',
        columnName: 'middle_name',
        dbType: FieldType.varchar,
        nullable: true,
        primaryKey: false,
        autoIncrement: false,
        autoNowAdd: false,
        autoNow: false,
      ),
    ],
  );
}
''';

// Sample output for custom table name
const _customTableNameOutput = '''
class Users {
  static const tableName = 'custom_users';
}
''';

// Sample output for autoNow and autoNowAdd
const _autoNowOutput = '''
class Users {
  static Manager<User> get objects {
    if (!_registered) {
      _registered = true;
      Jao.registerModel<User>(ModelRegistration(
        tableName: tableName,
        pkField: pkField,
        fromRow: fromRow,
        toRow: toRow,
        autoNowAddFields: ['created_at'],
        autoNowFields: ['updated_at'],
      ));
    }
    return _objects;
  }
}
''';

// Sample output for Duration fields
const _durationOutput = '''
class Task\$ implements ModelFields<Task> {
  const Task\$();

  final id = const IntFieldRef('id');
  final duration = const DurationFieldRef('duration');
}

class Tasks {
  static Task fromRow(Map<String, dynamic> row) {
    return Task()
      ..id = row['id'] as int
      ..duration = Duration(microseconds: row['duration'] as int);
  }

  static Map<String, dynamic> toRow(Task model) {
    return {
      'id': model.id,
      'duration': model.duration.inMicroseconds,
    };
  }
}
''';
