import 'package:jao/jao.dart';
import 'package:test/test.dart';

void main() {
  late SqlCompiler compiler;

  setUp(() {
    compiler = SqlCompiler(const SqliteDialect());
  });

  group('SELECT', () {
    test('generates basic SELECT *', () {
      final result = compiler.compileSelect(table: 'users', config: const QueryConfig());
      expect(result.sql, equals('SELECT * FROM "users"'));
      expect(result.parameters, isEmpty);
    });

    test('generates SELECT with specific columns', () {
      final result = compiler.compileSelect(table: 'users', config: const QueryConfig(), columns: ['id', 'name']);
      expect(result.sql, equals('SELECT "id", "name" FROM "users"'));
    });

    test('generates SELECT with only fields', () {
      final result = compiler.compileSelect(
        table: 'users',
        config: const QueryConfig(only: ['id', 'name']),
      );
      expect(result.sql, equals('SELECT "id", "name" FROM "users"'));
    });

    test('generates SELECT DISTINCT', () {
      final result = compiler.compileSelect(table: 'users', config: const QueryConfig(distinct: true));
      expect(result.sql, contains('SELECT DISTINCT *'));
    });

    test('generates SELECT with single filter', () {
      final config = QueryConfig(filters: [Q(Comparison(ColumnRef('age'), ComparisonOp.gte, Value(18)))]);
      final result = compiler.compileSelect(table: 'users', config: config);
      expect(result.sql, contains('WHERE'));
      expect(result.sql, contains('"age" >= ?1'));
      expect(result.parameters, equals([18]));
    });

    test('generates SELECT with multiple filters (AND)', () {
      final config = QueryConfig(
        filters: [
          Q(Comparison(ColumnRef('age'), ComparisonOp.gte, Value(18))),
          Q(Comparison(ColumnRef('is_active'), ComparisonOp.eq, Value(true))),
        ],
      );
      final result = compiler.compileSelect(table: 'users', config: config);
      expect(result.sql, contains('WHERE'));
      expect(result.sql, contains('AND'));
      expect(result.parameters.length, equals(2));
    });

    test('generates SELECT with exclude (NOT)', () {
      final config = QueryConfig(excludes: [Q(Comparison(ColumnRef('status'), ComparisonOp.eq, Value('deleted')))]);
      final result = compiler.compileSelect(table: 'users', config: config);
      expect(result.sql, contains('NOT'));
    });

    test('generates SELECT with OR condition', () {
      final orCondition = Q(
        BooleanExpr(
          Comparison(ColumnRef('status'), ComparisonOp.eq, Value('active')),
          BooleanOp.or,
          Comparison(ColumnRef('status'), ComparisonOp.eq, Value('pending')),
        ),
      );
      final config = QueryConfig(filters: [orCondition]);
      final result = compiler.compileSelect(table: 'users', config: config);
      expect(result.sql, contains('OR'));
    });

    test('generates SELECT with complex nested conditions', () {
      // (age >= 18 AND is_active = true) OR status = 'vip'
      final complex = Q(
        BooleanExpr(
          BooleanExpr(
            Comparison(ColumnRef('age'), ComparisonOp.gte, Value(18)),
            BooleanOp.and,
            Comparison(ColumnRef('is_active'), ComparisonOp.eq, Value(true)),
          ),
          BooleanOp.or,
          Comparison(ColumnRef('status'), ComparisonOp.eq, Value('vip')),
        ),
      );
      final config = QueryConfig(filters: [complex]);
      final result = compiler.compileSelect(table: 'users', config: config);
      expect(result.sql, contains('AND'));
      expect(result.sql, contains('OR'));
    });

    test('generates SELECT with ORDER BY single column', () {
      final config = QueryConfig(ordering: [OrderBy(ColumnRef('name'))]);
      final result = compiler.compileSelect(table: 'users', config: config);
      expect(result.sql, contains('ORDER BY "name" ASC'));
    });

    test('generates SELECT with ORDER BY multiple columns', () {
      final config = QueryConfig(
        ordering: [OrderBy(ColumnRef('is_active'), ascending: false), OrderBy(ColumnRef('name'))],
      );
      final result = compiler.compileSelect(table: 'users', config: config);
      expect(result.sql, contains('ORDER BY'));
      expect(result.sql, contains('"is_active" DESC'));
      expect(result.sql, contains('"name" ASC'));
    });

    test('generates SELECT with ORDER BY DESC', () {
      final config = QueryConfig(ordering: [OrderBy(ColumnRef('created_at'), ascending: false)]);
      final result = compiler.compileSelect(table: 'users', config: config);
      expect(result.sql, contains('"created_at" DESC'));
    });

    test('generates SELECT with ORDER BY NULLS FIRST', () {
      final config = QueryConfig(ordering: [const OrderBy(ColumnRef('bio')).nullsFirst()]);
      final result = compiler.compileSelect(table: 'users', config: config);
      expect(result.sql, contains('NULLS FIRST'));
    });

    test('generates SELECT with ORDER BY NULLS LAST', () {
      final config = QueryConfig(ordering: [const OrderBy(ColumnRef('bio')).nullsLast()]);
      final result = compiler.compileSelect(table: 'users', config: config);
      expect(result.sql, contains('NULLS LAST'));
    });

    test('generates SELECT with LIMIT', () {
      final result = compiler.compileSelect(table: 'users', config: const QueryConfig(limit: 10));
      expect(result.sql, contains('LIMIT 10'));
    });

    test('generates SELECT with OFFSET', () {
      final result = compiler.compileSelect(table: 'users', config: const QueryConfig(offset: 20));
      expect(result.sql, contains('OFFSET 20'));
    });

    test('generates SELECT with LIMIT and OFFSET', () {
      final result = compiler.compileSelect(table: 'users', config: const QueryConfig(limit: 10, offset: 20));
      expect(result.sql, contains('LIMIT 10'));
      expect(result.sql, contains('OFFSET 20'));
    });

    test('generates SELECT with annotations', () {
      final config = QueryConfig(
        annotations: {
          'total': FunctionCall('COUNT', [Value('*')]),
        },
      );
      final result = compiler.compileSelect(table: 'users', config: config);
      expect(result.sql, contains('COUNT'));
      expect(result.sql, contains('AS "total"'));
    });
  });

  group('INSERT', () {
    test('generates INSERT with values', () {
      final result = compiler.compileInsert(table: 'users', values: {'name': 'John', 'email': 'john@example.com'});
      expect(result.sql, contains('INSERT INTO "users"'));
      expect(result.sql, contains('"name", "email"'));
      expect(result.sql, contains('VALUES (?1, ?2)'));
      expect(result.parameters, equals(['John', 'john@example.com']));
    });

    test('generates INSERT with RETURNING (SQLite)', () {
      final result = compiler.compileInsert(table: 'users', values: {'name': 'John'}, returning: true);
      expect(result.sql, contains('RETURNING *'));
    });

    test('generates INSERT with specific RETURNING column', () {
      final result = compiler.compileInsert(
        table: 'users',
        values: {'name': 'John'},
        returning: true,
        returningColumn: 'id',
      );
      expect(result.sql, contains('RETURNING id'));
    });

    test('handles null values', () {
      final result = compiler.compileInsert(table: 'users', values: {'name': 'John', 'bio': null});
      expect(result.parameters, contains(null));
    });

    test('handles DateTime', () {
      final now = DateTime.now();
      final result = compiler.compileInsert(table: 'users', values: {'name': 'John', 'created_at': now});
      expect(result.parameters, contains(now));
    });

    test('handles bool', () {
      final result = compiler.compileInsert(table: 'users', values: {'name': 'John', 'is_active': true});
      expect(result.parameters, contains(true));
    });
  });

  group('Bulk INSERT', () {
    test('generates bulk INSERT with multiple rows', () {
      final result = compiler.compileBulkInsert(
        table: 'users',
        rows: [
          {'name': 'John', 'email': 'john@example.com'},
          {'name': 'Jane', 'email': 'jane@example.com'},
        ],
      );
      expect(result.sql, contains('INSERT INTO "users"'));
      expect(result.sql, contains('VALUES'));
      expect(result.sql, contains('(?1, ?2), (?3, ?4)'));
      expect(result.parameters.length, equals(4));
    });

    test('throws on empty list', () {
      expect(() => compiler.compileBulkInsert(table: 'users', rows: []), throwsA(isA<ArgumentError>()));
    });

    test('generates bulk INSERT with RETURNING', () {
      final result = compiler.compileBulkInsert(
        table: 'users',
        rows: [
          {'name': 'John'},
        ],
        returning: true,
      );
      expect(result.sql, contains('RETURNING *'));
    });
  });

  group('UPDATE', () {
    test('generates UPDATE with SET', () {
      final result = compiler.compileUpdate(table: 'users', config: const QueryConfig(), values: {'name': 'Jane'});
      expect(result.sql, equals('UPDATE "users" SET "name" = ?1'));
      expect(result.parameters, equals(['Jane']));
    });

    test('generates UPDATE with WHERE clause', () {
      final config = QueryConfig(filters: [Q(Comparison(ColumnRef('id'), ComparisonOp.eq, Value(1)))]);
      final result = compiler.compileUpdate(table: 'users', config: config, values: {'name': 'Jane'});
      expect(result.sql, contains('WHERE'));
      expect(result.sql, contains('"id" = ?2'));
    });

    test('generates UPDATE with multiple values', () {
      final result = compiler.compileUpdate(
        table: 'users',
        config: const QueryConfig(),
        values: {'name': 'Jane', 'age': 30},
      );
      expect(result.sql, contains('"name" = ?1'));
      expect(result.sql, contains('"age" = ?2'));
      expect(result.parameters, equals(['Jane', 30]));
    });

    test('handles null values', () {
      final result = compiler.compileUpdate(table: 'users', config: const QueryConfig(), values: {'bio': null});
      expect(result.parameters, equals([null]));
    });
  });

  group('DELETE', () {
    test('generates DELETE', () {
      final result = compiler.compileDelete(table: 'users', config: const QueryConfig());
      expect(result.sql, equals('DELETE FROM "users"'));
    });

    test('generates DELETE with WHERE clause', () {
      final config = QueryConfig(filters: [Q(Comparison(ColumnRef('id'), ComparisonOp.eq, Value(1)))]);
      final result = compiler.compileDelete(table: 'users', config: config);
      expect(result.sql, contains('WHERE'));
      expect(result.sql, contains('"id" = ?1'));
    });

    test('generates DELETE with complex WHERE', () {
      final config = QueryConfig(
        filters: [
          Q(Comparison(ColumnRef('status'), ComparisonOp.eq, Value('deleted'))),
          Q(Comparison(ColumnRef('created_at'), ComparisonOp.lt, Value('2020-01-01'))),
        ],
      );
      final result = compiler.compileDelete(table: 'users', config: config);
      expect(result.sql, contains('AND'));
    });
  });

  group('COUNT', () {
    test('generates SELECT COUNT(*)', () {
      final result = compiler.compileCount(table: 'users', config: const QueryConfig());
      expect(result.sql, equals('SELECT COUNT(*) FROM "users"'));
    });

    test('generates COUNT with filters', () {
      final config = QueryConfig(filters: [Q(Comparison(ColumnRef('is_active'), ComparisonOp.eq, Value(true)))]);
      final result = compiler.compileCount(table: 'users', config: config);
      expect(result.sql, contains('WHERE'));
    });
  });

  group('Aggregate', () {
    test('generates single aggregate', () {
      final result = compiler.compileAggregate(
        table: 'users',
        config: const QueryConfig(),
        aggregates: {
          'total': FunctionCall('COUNT', [Value('*')]),
        },
      );
      expect(result.sql, contains('COUNT'));
      expect(result.sql, contains('AS "total"'));
    });

    test('generates multiple aggregates', () {
      final result = compiler.compileAggregate(
        table: 'products',
        config: const QueryConfig(),
        aggregates: {
          'count': FunctionCall('COUNT', [Value('*')]),
          'avg_price': FunctionCall('AVG', [ColumnRef('price')]),
          'max_price': FunctionCall('MAX', [ColumnRef('price')]),
        },
      );
      expect(result.sql, contains('COUNT'));
      expect(result.sql, contains('AVG'));
      expect(result.sql, contains('MAX'));
    });

    test('generates aggregate with filters', () {
      final config = QueryConfig(
        filters: [Q(Comparison(ColumnRef('category'), ComparisonOp.eq, Value('electronics')))],
      );
      final result = compiler.compileAggregate(
        table: 'products',
        config: config,
        aggregates: {
          'total': FunctionCall('COUNT', [Value('*')]),
        },
      );
      expect(result.sql, contains('WHERE'));
    });
  });

  group('Parameters', () {
    test('parameters collected in order', () {
      final config = QueryConfig(
        filters: [
          Q(Comparison(ColumnRef('a'), ComparisonOp.eq, Value(1))),
          Q(Comparison(ColumnRef('b'), ComparisonOp.eq, Value(2))),
          Q(Comparison(ColumnRef('c'), ComparisonOp.eq, Value(3))),
        ],
      );
      compiler.compileSelect(table: 'test', config: config);
      expect(compiler.parameters, equals([1, 2, 3]));
    });

    test('reset() clears parameters', () {
      compiler.compileSelect(
        table: 'test',
        config: QueryConfig(filters: [Q(Comparison(ColumnRef('a'), ComparisonOp.eq, Value(1)))]),
      );
      expect(compiler.parameters, isNotEmpty);
      compiler.reset();
      expect(compiler.parameters, isEmpty);
    });

    test('parameter placeholders match SQLite dialect (?n)', () {
      final result = compiler.compileSelect(
        table: 'test',
        config: QueryConfig(
          filters: [
            Q(Comparison(ColumnRef('a'), ComparisonOp.eq, Value(1))),
            Q(Comparison(ColumnRef('b'), ComparisonOp.eq, Value(2))),
          ],
        ),
      );
      expect(result.sql, contains('?1'));
      expect(result.sql, contains('?2'));
    });
  });

  group('Expression compilation', () {
    test('compiles ColumnRef', () {
      final result = compiler.compileExpression(const ColumnRef('name'));
      expect(result, equals('"name"'));
    });

    test('compiles ColumnRef with table', () {
      final result = compiler.compileExpression(const ColumnRef('name', table: 'users'));
      expect(result, equals('"users"."name"'));
    });

    test('compiles Value', () {
      final result = compiler.compileExpression(const Value(42));
      expect(result, equals('?1'));
      expect(compiler.parameters, equals([42]));
    });

    test('compiles null Value', () {
      final result = compiler.compileExpression(const Value(null));
      expect(result, equals('NULL'));
    });

    test('compiles Comparison eq', () {
      final result = compiler.compileExpression(const Comparison(ColumnRef('age'), ComparisonOp.eq, Value(18)));
      expect(result, equals('"age" = ?1'));
    });

    test('compiles Comparison ne', () {
      final result = compiler.compileExpression(
        const Comparison(ColumnRef('status'), ComparisonOp.ne, Value('deleted')),
      );
      expect(result, equals('"status" != ?1'));
    });

    test('compiles Comparison lt', () {
      final result = compiler.compileExpression(const Comparison(ColumnRef('age'), ComparisonOp.lt, Value(18)));
      expect(result, equals('"age" < ?1'));
    });

    test('compiles Comparison lte', () {
      final result = compiler.compileExpression(const Comparison(ColumnRef('age'), ComparisonOp.lte, Value(18)));
      expect(result, equals('"age" <= ?1'));
    });

    test('compiles Comparison gt', () {
      final result = compiler.compileExpression(const Comparison(ColumnRef('age'), ComparisonOp.gt, Value(18)));
      expect(result, equals('"age" > ?1'));
    });

    test('compiles Comparison gte', () {
      final result = compiler.compileExpression(const Comparison(ColumnRef('age'), ComparisonOp.gte, Value(18)));
      expect(result, equals('"age" >= ?1'));
    });

    test('compiles Comparison LIKE', () {
      final result = compiler.compileExpression(
        const Comparison(ColumnRef('name'), ComparisonOp.like, Value('%john%')),
      );
      expect(result, equals('"name" LIKE ?1'));
    });

    test('compiles Comparison ILIKE (case-insensitive)', () {
      final result = compiler.compileExpression(
        const Comparison(ColumnRef('name'), ComparisonOp.ilike, Value('%john%')),
      );
      expect(result, contains('LOWER'));
    });

    test('compiles Comparison IS NULL', () {
      final result = compiler.compileExpression(const Comparison(ColumnRef('bio'), ComparisonOp.isNull, Value(null)));
      expect(result, equals('"bio" IS NULL'));
    });

    test('compiles Comparison IS NOT NULL', () {
      final result = compiler.compileExpression(
        const Comparison(ColumnRef('bio'), ComparisonOp.isNotNull, Value(null)),
      );
      expect(result, equals('"bio" IS NOT NULL'));
    });

    test('compiles Comparison IN list', () {
      final result = compiler.compileExpression(
        const Comparison(ColumnRef('status'), ComparisonOp.inList, Value(['active', 'pending'])),
      );
      expect(result, equals('"status" IN (?1, ?2)'));
      expect(compiler.parameters, equals(['active', 'pending']));
    });

    test('compiles BooleanExpr AND', () {
      final result = compiler.compileExpression(
        const BooleanExpr(
          Comparison(ColumnRef('a'), ComparisonOp.eq, Value(1)),
          BooleanOp.and,
          Comparison(ColumnRef('b'), ComparisonOp.eq, Value(2)),
        ),
      );
      expect(result, contains('AND'));
    });

    test('compiles BooleanExpr OR', () {
      final result = compiler.compileExpression(
        const BooleanExpr(
          Comparison(ColumnRef('a'), ComparisonOp.eq, Value(1)),
          BooleanOp.or,
          Comparison(ColumnRef('b'), ComparisonOp.eq, Value(2)),
        ),
      );
      expect(result, contains('OR'));
    });

    test('compiles NotExpr', () {
      final result = compiler.compileExpression(
        const NotExpr(Comparison(ColumnRef('active'), ComparisonOp.eq, Value(true))),
      );
      expect(result, startsWith('NOT'));
    });

    test('compiles ArithmeticExpr', () {
      final result = compiler.compileExpression(
        const ArithmeticExpr(ColumnRef('price'), ArithmeticOp.multiply, Value(1.1)),
      );
      expect(result, contains('*'));
    });

    test('compiles FunctionCall', () {
      final result = compiler.compileExpression(const FunctionCall('COUNT', [ColumnRef('id')]));
      expect(result, equals('COUNT("id")'));
    });

    test('compiles FunctionCall with DISTINCT', () {
      final result = compiler.compileExpression(const FunctionCall('COUNT', [ColumnRef('id')], distinct: true));
      expect(result, equals('COUNT(DISTINCT "id")'));
    });

    test('compiles F expression simple', () {
      final result = compiler.compileExpression(const F('price'));
      expect(result, equals('"price"'));
    });

    test('compiles F expression with path', () {
      final result = compiler.compileExpression(const F('author__name'));
      expect(result, equals('"author"."name"'));
    });

    test('compiles Q by unwrapping expression', () {
      final result = compiler.compileExpression(Q(const Comparison(ColumnRef('age'), ComparisonOp.eq, Value(18))));
      expect(result, equals('"age" = ?1'));
    });
  });

  group('CompiledQuery', () {
    test('stores sql and parameters', () {
      final query = CompiledQuery('SELECT * FROM users', [1, 'test']);
      expect(query.sql, equals('SELECT * FROM users'));
      expect(query.parameters, equals([1, 'test']));
    });

    test('toString shows both', () {
      final query = CompiledQuery('SELECT * FROM users', [1]);
      expect(query.toString(), contains('SELECT'));
    });

    test('toDebugString replaces placeholders', () {
      final query = CompiledQuery('SELECT * FROM users WHERE id = \$1 AND name = \$2', [1, 'John']);
      final debug = query.toDebugString();
      expect(debug, contains('1'));
      expect(debug, contains("'John'"));
    });
  });
}
