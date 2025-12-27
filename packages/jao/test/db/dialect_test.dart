import 'package:jao/jao.dart';
import 'package:test/test.dart';

void main() {
  group('PostgresDialect', () {
    const dialect = PostgresDialect();

    group('parameterPlaceholder', () {
      test('returns \$1, \$2, ...', () {
        expect(dialect.parameterPlaceholder(1), equals('\$1'));
        expect(dialect.parameterPlaceholder(2), equals('\$2'));
        expect(dialect.parameterPlaceholder(10), equals('\$10'));
      });
    });

    group('quoteIdentifier', () {
      test('returns "name"', () {
        expect(dialect.quoteIdentifier('users'), equals('"users"'));
        expect(dialect.quoteIdentifier('created_at'), equals('"created_at"'));
      });
    });

    group('sqlType', () {
      test('maps FieldType.integer to INTEGER', () {
        expect(dialect.sqlType(FieldType.integer), equals('INTEGER'));
      });

      test('maps FieldType.varchar to VARCHAR', () {
        expect(dialect.sqlType(FieldType.varchar), equals('VARCHAR'));
      });

      test('maps FieldType.text to TEXT', () {
        expect(dialect.sqlType(FieldType.text), equals('TEXT'));
      });

      test('maps FieldType.boolean to BOOLEAN', () {
        expect(dialect.sqlType(FieldType.boolean), equals('BOOLEAN'));
      });

      test('maps FieldType.timestampTz to TIMESTAMPTZ', () {
        expect(dialect.sqlType(FieldType.timestampTz), equals('TIMESTAMPTZ'));
      });

      test('maps FieldType.decimal to DECIMAL', () {
        expect(dialect.sqlType(FieldType.decimal), equals('DECIMAL'));
      });

      test('maps FieldType.jsonb to JSONB', () {
        expect(dialect.sqlType(FieldType.jsonb), equals('JSONB'));
      });

      test('maps FieldType.uuid to UUID', () {
        expect(dialect.sqlType(FieldType.uuid), equals('UUID'));
      });

      test('maps FieldType.serial to SERIAL', () {
        expect(dialect.sqlType(FieldType.serial), equals('SERIAL'));
      });

      test('maps FieldType.bigSerial to BIGSERIAL', () {
        expect(dialect.sqlType(FieldType.bigSerial), equals('BIGSERIAL'));
      });
    });

    group('booleanLiteral', () {
      test('returns TRUE/FALSE', () {
        expect(dialect.booleanLiteral(true), equals('TRUE'));
        expect(dialect.booleanLiteral(false), equals('FALSE'));
      });
    });

    group('feature flags', () {
      test('supportsReturning is true', () {
        expect(dialect.supportsReturning, isTrue);
      });
    });

    group('autoIncrement', () {
      test('returns SERIAL', () {
        expect(dialect.autoIncrement(), equals('SERIAL'));
      });
    });

    group('currentTimestamp', () {
      test('returns CURRENT_TIMESTAMP', () {
        expect(dialect.currentTimestamp(), equals('CURRENT_TIMESTAMP'));
      });
    });

    group('concat', () {
      test('uses || operator', () {
        expect(dialect.concat(['a', 'b', 'c']), equals('a || b || c'));
      });
    });

    group('limitOffset', () {
      test('generates LIMIT only', () {
        expect(dialect.limitOffset(10, null), equals(' LIMIT 10'));
      });

      test('generates OFFSET only', () {
        expect(dialect.limitOffset(null, 20), equals(' OFFSET 20'));
      });

      test('generates LIMIT and OFFSET', () {
        expect(dialect.limitOffset(10, 20), equals(' LIMIT 10 OFFSET 20'));
      });

      test('returns empty for no limit/offset', () {
        expect(dialect.limitOffset(null, null), equals(''));
      });
    });

    group('caseInsensitiveLike', () {
      test('uses ILIKE', () {
        expect(dialect.caseInsensitiveLike('"name"', '?1'), equals('"name" ILIKE ?1'));
      });
    });
  });

  group('MySqlDialect', () {
    const dialect = MySqlDialect();

    group('parameterPlaceholder', () {
      test('returns ?', () {
        expect(dialect.parameterPlaceholder(1), equals('?'));
        expect(dialect.parameterPlaceholder(2), equals('?'));
        expect(dialect.parameterPlaceholder(10), equals('?'));
      });
    });

    group('quoteIdentifier', () {
      test('returns `name` (backticks)', () {
        expect(dialect.quoteIdentifier('users'), equals('`users`'));
        expect(dialect.quoteIdentifier('created_at'), equals('`created_at`'));
      });
    });

    group('sqlType', () {
      test('maps FieldType.integer to INT', () {
        expect(dialect.sqlType(FieldType.integer), equals('INT'));
      });

      test('maps FieldType.boolean to TINYINT(1)', () {
        expect(dialect.sqlType(FieldType.boolean), equals('TINYINT(1)'));
      });

      test('maps FieldType.serial to INT AUTO_INCREMENT', () {
        expect(dialect.sqlType(FieldType.serial), equals('INT AUTO_INCREMENT'));
      });

      test('maps FieldType.uuid to CHAR(36)', () {
        expect(dialect.sqlType(FieldType.uuid), equals('CHAR(36)'));
      });

      test('maps FieldType.json to JSON', () {
        expect(dialect.sqlType(FieldType.json), equals('JSON'));
      });

      test('maps FieldType.timestamp to DATETIME', () {
        expect(dialect.sqlType(FieldType.timestamp), equals('DATETIME'));
      });
    });

    group('booleanLiteral', () {
      test('returns 1/0', () {
        expect(dialect.booleanLiteral(true), equals('1'));
        expect(dialect.booleanLiteral(false), equals('0'));
      });
    });

    group('feature flags', () {
      test('supportsReturning is false', () {
        expect(dialect.supportsReturning, isFalse);
      });
    });

    group('autoIncrement', () {
      test('returns AUTO_INCREMENT', () {
        expect(dialect.autoIncrement(), equals('AUTO_INCREMENT'));
      });
    });

    group('currentTimestamp', () {
      test('returns NOW()', () {
        expect(dialect.currentTimestamp(), equals('NOW()'));
      });
    });

    group('concat', () {
      test('uses CONCAT function', () {
        expect(dialect.concat(['a', 'b', 'c']), equals('CONCAT(a, b, c)'));
      });
    });

    group('limitOffset', () {
      test('generates LIMIT only', () {
        expect(dialect.limitOffset(10, null), equals(' LIMIT 10'));
      });

      test('generates OFFSET with large LIMIT (MySQL requirement)', () {
        final result = dialect.limitOffset(null, 20);
        expect(result, contains('LIMIT'));
        expect(result, contains('OFFSET 20'));
      });

      test('generates LIMIT and OFFSET', () {
        expect(dialect.limitOffset(10, 20), equals(' LIMIT 10 OFFSET 20'));
      });

      test('returns empty for no limit/offset', () {
        expect(dialect.limitOffset(null, null), equals(''));
      });
    });

    group('caseInsensitiveLike', () {
      test('uses LIKE (MySQL is case-insensitive by default)', () {
        expect(dialect.caseInsensitiveLike('`name`', '?'), equals('`name` LIKE ?'));
      });
    });

    group('upsert', () {
      test('uses ON DUPLICATE KEY UPDATE', () {
        final result = dialect.upsert('users', ['id', 'name', 'email'], ['id']);
        expect(result, contains('ON DUPLICATE KEY UPDATE'));
        expect(result, contains('`name`'));
        expect(result, contains('`email`'));
      });
    });
  });

  group('SqliteDialect', () {
    const dialect = SqliteDialect();

    group('parameterPlaceholder', () {
      test('returns ?1, ?2, ...', () {
        expect(dialect.parameterPlaceholder(1), equals('?1'));
        expect(dialect.parameterPlaceholder(2), equals('?2'));
        expect(dialect.parameterPlaceholder(10), equals('?10'));
      });
    });

    group('quoteIdentifier', () {
      test('returns "name" (double quotes)', () {
        expect(dialect.quoteIdentifier('users'), equals('"users"'));
        expect(dialect.quoteIdentifier('created_at'), equals('"created_at"'));
      });
    });

    group('sqlType', () {
      test('maps FieldType.integer to INTEGER', () {
        expect(dialect.sqlType(FieldType.integer), equals('INTEGER'));
      });

      test('maps FieldType.varchar to TEXT', () {
        expect(dialect.sqlType(FieldType.varchar), equals('TEXT'));
      });

      test('maps FieldType.text to TEXT', () {
        expect(dialect.sqlType(FieldType.text), equals('TEXT'));
      });

      test('maps FieldType.boolean to INTEGER', () {
        expect(dialect.sqlType(FieldType.boolean), equals('INTEGER'));
      });

      test('maps FieldType.timestamp to TEXT', () {
        expect(dialect.sqlType(FieldType.timestamp), equals('TEXT'));
      });

      test('maps FieldType.json to TEXT', () {
        expect(dialect.sqlType(FieldType.json), equals('TEXT'));
      });

      test('maps FieldType.uuid to TEXT', () {
        expect(dialect.sqlType(FieldType.uuid), equals('TEXT'));
      });

      test('maps FieldType.serial to INTEGER PRIMARY KEY AUTOINCREMENT', () {
        expect(dialect.sqlType(FieldType.serial), equals('INTEGER PRIMARY KEY AUTOINCREMENT'));
      });

      test('maps FieldType.blob to BLOB', () {
        expect(dialect.sqlType(FieldType.blob), equals('BLOB'));
      });

      test('maps FieldType.real to REAL', () {
        expect(dialect.sqlType(FieldType.real), equals('REAL'));
      });
    });

    group('booleanLiteral', () {
      test('returns 1/0', () {
        expect(dialect.booleanLiteral(true), equals('1'));
        expect(dialect.booleanLiteral(false), equals('0'));
      });
    });

    group('feature flags', () {
      test('supportsReturning is true (SQLite 3.35+)', () {
        expect(dialect.supportsReturning, isTrue);
      });
    });

    group('autoIncrement', () {
      test('returns AUTOINCREMENT', () {
        expect(dialect.autoIncrement(), equals('AUTOINCREMENT'));
      });
    });

    group('currentTimestamp', () {
      test('returns datetime(\'now\')', () {
        expect(dialect.currentTimestamp(), equals("datetime('now')"));
      });
    });

    group('concat', () {
      test('uses || operator', () {
        expect(dialect.concat(['a', 'b', 'c']), equals('a || b || c'));
      });
    });

    group('limitOffset', () {
      test('generates LIMIT only', () {
        expect(dialect.limitOffset(10, null), equals(' LIMIT 10'));
      });

      test('generates OFFSET with LIMIT -1', () {
        expect(dialect.limitOffset(null, 20), equals(' LIMIT -1 OFFSET 20'));
      });

      test('generates LIMIT and OFFSET', () {
        expect(dialect.limitOffset(10, 20), equals(' LIMIT 10 OFFSET 20'));
      });

      test('returns empty for no limit/offset', () {
        expect(dialect.limitOffset(null, null), equals(''));
      });
    });

    group('caseInsensitiveLike', () {
      test('uses LOWER() for case-insensitive matching', () {
        final result = dialect.caseInsensitiveLike('"name"', '?1');
        expect(result, contains('LOWER'));
        expect(result, contains('LIKE'));
      });
    });

    group('upsert', () {
      test('uses ON CONFLICT DO UPDATE', () {
        final result = dialect.upsert('users', ['id', 'name', 'email'], ['id']);
        expect(result, contains('ON CONFLICT'));
        expect(result, contains('DO UPDATE SET'));
        expect(result, contains('"name"'));
        expect(result, contains('"email"'));
      });
    });
  });

  group('Cross-dialect comparison', () {
    const sqlite = SqliteDialect();
    const postgres = PostgresDialect();
    const mysql = MySqlDialect();

    test('all dialects handle parameterPlaceholder differently', () {
      expect(sqlite.parameterPlaceholder(1), isNot(equals(postgres.parameterPlaceholder(1))));
      expect(postgres.parameterPlaceholder(1), isNot(equals(mysql.parameterPlaceholder(1))));
    });

    test('all dialects quote identifiers', () {
      expect(sqlite.quoteIdentifier('test'), isNotEmpty);
      expect(postgres.quoteIdentifier('test'), isNotEmpty);
      expect(mysql.quoteIdentifier('test'), isNotEmpty);
    });

    test('MySQL and SQLite use different quoting', () {
      expect(sqlite.quoteIdentifier('test'), isNot(equals(mysql.quoteIdentifier('test'))));
    });

    test('PostgreSQL and SQLite use same quoting style', () {
      expect(sqlite.quoteIdentifier('test'), equals(postgres.quoteIdentifier('test')));
    });

    test('all dialects have consistent limitOffset behavior', () {
      // All should return empty for null/null
      expect(sqlite.limitOffset(null, null), equals(''));
      expect(postgres.limitOffset(null, null), equals(''));
      expect(mysql.limitOffset(null, null), equals(''));

      // All should handle LIMIT 10
      expect(sqlite.limitOffset(10, null), contains('LIMIT 10'));
      expect(postgres.limitOffset(10, null), contains('LIMIT 10'));
      expect(mysql.limitOffset(10, null), contains('LIMIT 10'));
    });
  });
}
