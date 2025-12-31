import 'package:test/test.dart';

/// Tests for cross-database type compatibility.
///
/// Issue: When using JAO with PostgreSQL, models with TIMESTAMP columns fail
/// at runtime because the generated fromRow() method expects String values
/// but PostgreSQL returns DateTime objects.
///
/// See: https://github.com/nexlabstudio/jao/issues/4
void main() {
  group('@DateTimeField - non-nullable', () {
    // Current generated code:
    // ..createdAt = DateTime.parse(row['created_at'] as String)
    DateTime generatedFromRow(Map<String, dynamic> row) {
      return DateTime.parse(row['created_at'] as String);
    }

    test('should work with SQLite (String timestamp)', () {
      final sqliteRow = {'created_at': '2024-01-15T10:30:00.000'};
      final result = generatedFromRow(sqliteRow);
      expect(result, equals(DateTime(2024, 1, 15, 10, 30, 0)));
    });

    test('should work with PostgreSQL (DateTime object)', () {
      final postgresRow = {'created_at': DateTime(2024, 1, 15, 10, 30, 0)};
      final result = generatedFromRow(postgresRow);
      expect(result, equals(DateTime(2024, 1, 15, 10, 30, 0)));
    });
  });

  group('@DateTimeField - nullable', () {
    // Current generated code:
    // ..deletedAt = row['deleted_at'] == null
    //     ? null
    //     : DateTime.parse(row['deleted_at'] as String)
    DateTime? generatedFromRowNullable(Map<String, dynamic> row) {
      return row['deleted_at'] == null
          ? null
          : DateTime.parse(row['deleted_at'] as String);
    }

    test('should work with SQLite (String timestamp)', () {
      final sqliteRow = {'deleted_at': '2024-01-15T10:30:00.000'};
      final result = generatedFromRowNullable(sqliteRow);
      expect(result, equals(DateTime(2024, 1, 15, 10, 30, 0)));
    });

    test('should work with null value', () {
      final row = {'deleted_at': null};
      expect(generatedFromRowNullable(row), isNull);
    });

    test('should work with PostgreSQL (DateTime object)', () {
      final postgresRow = {'deleted_at': DateTime(2024, 1, 15, 10, 30, 0)};
      final result = generatedFromRowNullable(postgresRow);
      expect(result, equals(DateTime(2024, 1, 15, 10, 30, 0)));
    });
  });

  group('@BooleanField - non-nullable', () {
    // Current generated code:
    // ..isActive = row['is_active'] as bool
    bool generatedFromRowBool(Map<String, dynamic> row) {
      return row['is_active'] as bool;
    }

    test('should work with PostgreSQL (bool value)', () {
      expect(generatedFromRowBool({'is_active': true}), isTrue);
      expect(generatedFromRowBool({'is_active': false}), isFalse);
    });

    test('should work with SQLite (int 0/1)', () {
      expect(generatedFromRowBool({'is_active': 1}), isTrue);
      expect(generatedFromRowBool({'is_active': 0}), isFalse);
    });
  });

  group('@BooleanField - nullable', () {
    // Current generated code:
    // ..isActive = row['is_active'] as bool?
    bool? generatedFromRowBoolNullable(Map<String, dynamic> row) {
      return row['is_active'] as bool?;
    }

    test('should work with PostgreSQL (bool value)', () {
      expect(generatedFromRowBoolNullable({'is_active': true}), isTrue);
      expect(generatedFromRowBoolNullable({'is_active': false}), isFalse);
    });

    test('should work with null value', () {
      expect(generatedFromRowBoolNullable({'is_active': null}), isNull);
    });

    test('should work with SQLite (int 0/1)', () {
      expect(generatedFromRowBoolNullable({'is_active': 1}), isTrue);
      expect(generatedFromRowBoolNullable({'is_active': 0}), isFalse);
    });
  });

  group('@IntegerField - non-nullable', () {
    // Current generated code:
    // ..age = row['age'] as int
    int generatedFromRowInt(Map<String, dynamic> row) {
      return row['age'] as int;
    }

    test('should work with int value', () {
      expect(generatedFromRowInt({'age': 42}), equals(42));
    });

    test('should work with String value (some drivers)', () {
      expect(generatedFromRowInt({'age': '42'}), equals(42));
    });

    test('should work with double value (some drivers return double for numeric)', () {
      expect(generatedFromRowInt({'age': 42.0}), equals(42));
    });
  });

  group('@IntegerField - nullable', () {
    // Current generated code:
    // ..age = row['age'] as int?
    int? generatedFromRowIntNullable(Map<String, dynamic> row) {
      return row['age'] as int?;
    }

    test('should work with int value', () {
      expect(generatedFromRowIntNullable({'age': 42}), equals(42));
    });

    test('should work with null value', () {
      expect(generatedFromRowIntNullable({'age': null}), isNull);
    });

    test('should work with String value (some drivers)', () {
      expect(generatedFromRowIntNullable({'age': '42'}), equals(42));
    });
  });

  group('@FloatField / @DecimalField - non-nullable', () {
    // Current generated code:
    // ..price = row['price'] as double
    double generatedFromRowDouble(Map<String, dynamic> row) {
      return row['price'] as double;
    }

    test('should work with double value', () {
      expect(generatedFromRowDouble({'price': 19.99}), equals(19.99));
    });

    test('should work with int value (whole numbers)', () {
      // Some drivers return int instead of double for whole numbers like 20.0
      expect(generatedFromRowDouble({'price': 20}), equals(20.0));
    });

    test('should work with String value (some drivers)', () {
      expect(generatedFromRowDouble({'price': '19.99'}), equals(19.99));
    });
  });

  group('@FloatField / @DecimalField - nullable', () {
    // Current generated code:
    // ..price = row['price'] as double?
    double? generatedFromRowDoubleNullable(Map<String, dynamic> row) {
      return row['price'] as double?;
    }

    test('should work with double value', () {
      expect(generatedFromRowDoubleNullable({'price': 19.99}), equals(19.99));
    });

    test('should work with null value', () {
      expect(generatedFromRowDoubleNullable({'price': null}), isNull);
    });

    test('should work with int value (whole numbers)', () {
      expect(generatedFromRowDoubleNullable({'price': 20}), equals(20.0));
    });
  });

  group('@DurationField - non-nullable', () {
    // Current generated code:
    // ..duration = Duration(microseconds: row['duration'] as int)
    Duration generatedFromRowDuration(Map<String, dynamic> row) {
      return Duration(microseconds: row['duration'] as int);
    }

    test('should work with int microseconds (SQLite)', () {
      final duration = generatedFromRowDuration({'duration': 5400000000});
      expect(duration, equals(const Duration(hours: 1, minutes: 30)));
    });

    test('should work with Duration object (PostgreSQL)', () {
      const expected = Duration(hours: 1, minutes: 30);
      final row = {'duration': expected};
      final result = generatedFromRowDuration(row);
      expect(result, equals(expected));
    });

    test('should work with String microseconds (some drivers)', () {
      final duration = generatedFromRowDuration({'duration': '5400000000'});
      expect(duration, equals(const Duration(hours: 1, minutes: 30)));
    });
  });

  group('@DurationField - nullable', () {
    // Current generated code:
    // ..duration = row['duration'] == null
    //     ? null
    //     : Duration(microseconds: row['duration'] as int)
    Duration? generatedFromRowDurationNullable(Map<String, dynamic> row) {
      return row['duration'] == null
          ? null
          : Duration(microseconds: row['duration'] as int);
    }

    test('should work with int microseconds (SQLite)', () {
      final duration = generatedFromRowDurationNullable({'duration': 5400000000});
      expect(duration, equals(const Duration(hours: 1, minutes: 30)));
    });

    test('should work with null value', () {
      expect(generatedFromRowDurationNullable({'duration': null}), isNull);
    });

    test('should work with Duration object (PostgreSQL)', () {
      const expected = Duration(hours: 1, minutes: 30);
      final row = {'duration': expected};
      final result = generatedFromRowDurationNullable(row);
      expect(result, equals(expected));
    });
  });
}
