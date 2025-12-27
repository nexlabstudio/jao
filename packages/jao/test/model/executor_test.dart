import 'package:jao/jao.dart';
import 'package:test/test.dart';

// Simple test model
class Author {
  final int? id;
  final String name;
  final int age;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Author({this.id, required this.name, required this.age, this.createdAt, this.updatedAt});

  static Author fromRow(Map<String, dynamic> row) {
    return Author(
      id: row['id'] as int?,
      name: row['name'] as String,
      age: row['age'] as int,
      createdAt: row['created_at'] != null ? DateTime.parse(row['created_at'] as String) : null,
      updatedAt: row['updated_at'] != null ? DateTime.parse(row['updated_at'] as String) : null,
    );
  }

  static Map<String, dynamic> toRow(Author author) {
    return {
      if (author.id != null) 'id': author.id,
      'name': author.name,
      'age': author.age,
      if (author.createdAt != null) 'created_at': author.createdAt!.toIso8601String(),
      if (author.updatedAt != null) 'updated_at': author.updatedAt!.toIso8601String(),
    };
  }
}

void main() {
  group('ModelExecutor', () {
    late SqliteAdapter adapter;
    late ConnectionPool pool;
    late SqlCompiler compiler;
    late ModelExecutor<Author> executor;

    setUp(() async {
      final config = DatabaseConfig.sqliteMemory();
      adapter = const SqliteAdapter();
      pool = await adapter.createPool(config);
      compiler = SqlCompiler(adapter.dialect);

      // Create the authors table
      await pool.withConnection((conn) async {
        await conn.execute('''
          CREATE TABLE authors (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            age INTEGER NOT NULL,
            created_at TEXT,
            updated_at TEXT
          )
        ''');
      });

      executor = ModelExecutor<Author>(
        pool: pool,
        compiler: compiler,
        tableName: 'authors',
        pkField: 'id',
        fromRow: Author.fromRow,
        toRow: Author.toRow,
      );
    });

    tearDown(() async {
      await pool.close();
    });

    group('create()', () {
      test('creates a new record', () async {
        final author = await executor.create({'name': 'John', 'age': 30});

        expect(author.id, isNotNull);
        expect(author.name, equals('John'));
        expect(author.age, equals(30));
      });

      test('returns created record with ID', () async {
        final author1 = await executor.create({'name': 'Alice', 'age': 25});
        final author2 = await executor.create({'name': 'Bob', 'age': 35});

        expect(author1.id, equals(1));
        expect(author2.id, equals(2));
      });
    });

    group('bulkCreate()', () {
      test('creates multiple records', () async {
        final authors = await executor.bulkCreate([
          {'name': 'Alice', 'age': 25},
          {'name': 'Bob', 'age': 30},
          {'name': 'Charlie', 'age': 35},
        ]);

        expect(authors.length, equals(3));
        expect(authors[0].name, equals('Alice'));
        expect(authors[1].name, equals('Bob'));
        expect(authors[2].name, equals('Charlie'));
      });

      test('returns empty list for empty input', () async {
        final authors = await executor.bulkCreate([]);
        expect(authors, isEmpty);
      });
    });

    group('execute()', () {
      test('returns all records when no filters', () async {
        await executor.create({'name': 'Alice', 'age': 25});
        await executor.create({'name': 'Bob', 'age': 30});

        final authors = await executor.execute(const QueryConfig());

        expect(authors.length, equals(2));
      });

      test('filters records', () async {
        await executor.create({'name': 'Alice', 'age': 25});
        await executor.create({'name': 'Bob', 'age': 30});
        await executor.create({'name': 'Charlie', 'age': 25});

        final config = QueryConfig(filters: [Q(const Comparison(ColumnRef('age'), ComparisonOp.eq, Value(25)))]);
        final authors = await executor.execute(config);

        expect(authors.length, equals(2));
        expect(authors.every((a) => a.age == 25), isTrue);
      });

      test('limits records', () async {
        await executor.bulkCreate([
          {'name': 'Alice', 'age': 25},
          {'name': 'Bob', 'age': 30},
          {'name': 'Charlie', 'age': 35},
        ]);

        final config = const QueryConfig(limit: 2);
        final authors = await executor.execute(config);

        expect(authors.length, equals(2));
      });

      test('offsets records', () async {
        await executor.bulkCreate([
          {'name': 'Alice', 'age': 25},
          {'name': 'Bob', 'age': 30},
          {'name': 'Charlie', 'age': 35},
        ]);

        final config = const QueryConfig(offset: 1, ordering: [OrderBy(ColumnRef('id'))]);
        final authors = await executor.execute(config);

        expect(authors.length, equals(2));
        expect(authors[0].name, equals('Bob'));
      });

      test('orders records', () async {
        await executor.bulkCreate([
          {'name': 'Charlie', 'age': 35},
          {'name': 'Alice', 'age': 25},
          {'name': 'Bob', 'age': 30},
        ]);

        final config = const QueryConfig(ordering: [OrderBy(ColumnRef('name'))]);
        final authors = await executor.execute(config);

        expect(authors[0].name, equals('Alice'));
        expect(authors[1].name, equals('Bob'));
        expect(authors[2].name, equals('Charlie'));
      });

      test('orders descending', () async {
        await executor.bulkCreate([
          {'name': 'Alice', 'age': 25},
          {'name': 'Bob', 'age': 30},
          {'name': 'Charlie', 'age': 35},
        ]);

        final config = const QueryConfig(ordering: [OrderBy(ColumnRef('age'), ascending: false)]);
        final authors = await executor.execute(config);

        expect(authors[0].age, equals(35));
        expect(authors[1].age, equals(30));
        expect(authors[2].age, equals(25));
      });
    });

    group('count()', () {
      test('returns total count', () async {
        await executor.bulkCreate([
          {'name': 'Alice', 'age': 25},
          {'name': 'Bob', 'age': 30},
          {'name': 'Charlie', 'age': 35},
        ]);

        final count = await executor.count(const QueryConfig());
        expect(count, equals(3));
      });

      test('returns filtered count', () async {
        await executor.bulkCreate([
          {'name': 'Alice', 'age': 25},
          {'name': 'Bob', 'age': 30},
          {'name': 'Charlie', 'age': 25},
        ]);

        final config = QueryConfig(filters: [Q(const Comparison(ColumnRef('age'), ComparisonOp.eq, Value(25)))]);
        final count = await executor.count(config);

        expect(count, equals(2));
      });

      test('returns 0 for empty table', () async {
        final count = await executor.count(const QueryConfig());
        expect(count, equals(0));
      });
    });

    group('aggregate()', () {
      test('calculates sum', () async {
        await executor.bulkCreate([
          {'name': 'Alice', 'age': 25},
          {'name': 'Bob', 'age': 30},
          {'name': 'Charlie', 'age': 35},
        ]);

        final result = await executor.aggregate(const QueryConfig(), {'total_age': Sum(ColumnRef('age'))});

        expect(result['total_age'], equals(90));
      });

      test('calculates avg', () async {
        await executor.bulkCreate([
          {'name': 'Alice', 'age': 20},
          {'name': 'Bob', 'age': 30},
          {'name': 'Charlie', 'age': 40},
        ]);

        final result = await executor.aggregate(const QueryConfig(), {'avg_age': Avg(ColumnRef('age'))});

        expect(result['avg_age'], equals(30.0));
      });

      test('calculates min and max', () async {
        await executor.bulkCreate([
          {'name': 'Alice', 'age': 25},
          {'name': 'Bob', 'age': 30},
          {'name': 'Charlie', 'age': 35},
        ]);

        final result = await executor.aggregate(const QueryConfig(), {
          'min_age': Min(const ColumnRef('age')),
          'max_age': Max(const ColumnRef('age')),
        });

        expect(result['min_age'], equals(25));
        expect(result['max_age'], equals(35));
      });
    });

    group('update()', () {
      test('updates matching records', () async {
        await executor.bulkCreate([
          {'name': 'Alice', 'age': 25},
          {'name': 'Bob', 'age': 30},
        ]);

        final config = QueryConfig(filters: [Q(const Comparison(ColumnRef('name'), ComparisonOp.eq, Value('Alice')))]);
        final affected = await executor.update(config, {'age': 26});

        expect(affected, equals(1));

        final authors = await executor.execute(const QueryConfig(ordering: [OrderBy(ColumnRef('id'))]));
        expect(authors[0].age, equals(26));
        expect(authors[1].age, equals(30));
      });

      test('updates multiple records', () async {
        await executor.bulkCreate([
          {'name': 'Alice', 'age': 25},
          {'name': 'Bob', 'age': 25},
          {'name': 'Charlie', 'age': 30},
        ]);

        final config = QueryConfig(filters: [Q(const Comparison(ColumnRef('age'), ComparisonOp.eq, Value(25)))]);
        final affected = await executor.update(config, {'age': 26});

        expect(affected, equals(2));
      });

      test('returns 0 when no match', () async {
        await executor.create({'name': 'Alice', 'age': 25});

        final config = QueryConfig(
          filters: [Q(const Comparison(ColumnRef('name'), ComparisonOp.eq, Value('NonExistent')))],
        );
        final affected = await executor.update(config, {'age': 30});

        expect(affected, equals(0));
      });
    });

    group('delete()', () {
      test('deletes matching records', () async {
        await executor.bulkCreate([
          {'name': 'Alice', 'age': 25},
          {'name': 'Bob', 'age': 30},
        ]);

        final config = QueryConfig(filters: [Q(const Comparison(ColumnRef('name'), ComparisonOp.eq, Value('Alice')))]);
        final affected = await executor.delete(config);

        expect(affected, equals(1));

        final count = await executor.count(const QueryConfig());
        expect(count, equals(1));
      });

      test('deletes multiple records', () async {
        await executor.bulkCreate([
          {'name': 'Alice', 'age': 25},
          {'name': 'Bob', 'age': 25},
          {'name': 'Charlie', 'age': 30},
        ]);

        final config = QueryConfig(filters: [Q(const Comparison(ColumnRef('age'), ComparisonOp.eq, Value(25)))]);
        final affected = await executor.delete(config);

        expect(affected, equals(2));

        final count = await executor.count(const QueryConfig());
        expect(count, equals(1));
      });

      test('returns 0 when no match', () async {
        await executor.create({'name': 'Alice', 'age': 25});

        final config = QueryConfig(
          filters: [Q(const Comparison(ColumnRef('name'), ComparisonOp.eq, Value('NonExistent')))],
        );
        final affected = await executor.delete(config);

        expect(affected, equals(0));
      });
    });

    group('stream()', () {
      test('streams records', () async {
        await executor.bulkCreate([
          {'name': 'Alice', 'age': 25},
          {'name': 'Bob', 'age': 30},
          {'name': 'Charlie', 'age': 35},
        ]);

        final authors = await executor.stream(const QueryConfig()).toList();

        expect(authors.length, equals(3));
      });

      test('streams filtered records', () async {
        await executor.bulkCreate([
          {'name': 'Alice', 'age': 25},
          {'name': 'Bob', 'age': 30},
          {'name': 'Charlie', 'age': 25},
        ]);

        final config = QueryConfig(filters: [Q(const Comparison(ColumnRef('age'), ComparisonOp.eq, Value(25)))]);
        final authors = await executor.stream(config).toList();

        expect(authors.length, equals(2));
      });
    });

    group('rawQuery()', () {
      test('executes raw SQL', () async {
        await executor.bulkCreate([
          {'name': 'Alice', 'age': 25},
          {'name': 'Bob', 'age': 30},
        ]);

        final rows = await executor.rawQuery('SELECT * FROM authors ORDER BY age');

        expect(rows.length, equals(2));
        expect(rows[0]['name'], equals('Alice'));
        expect(rows[1]['name'], equals('Bob'));
      });

      test('executes raw SQL with parameters', () async {
        await executor.bulkCreate([
          {'name': 'Alice', 'age': 25},
          {'name': 'Bob', 'age': 30},
        ]);

        final rows = await executor.rawQuery('SELECT * FROM authors WHERE age > ?', [25]);

        expect(rows.length, equals(1));
        expect(rows[0]['name'], equals('Bob'));
      });
    });

    group('transaction()', () {
      test('commits on success', () async {
        await executor.transaction((tx) async {
          await tx.create({'name': 'Alice', 'age': 25});
          await tx.create({'name': 'Bob', 'age': 30});
        });

        final count = await executor.count(const QueryConfig());
        expect(count, equals(2));
      });

      test('rolls back on error', () async {
        try {
          await executor.transaction((tx) async {
            await tx.create({'name': 'Alice', 'age': 25});
            throw Exception('Simulated error');
          });
        } catch (_) {}

        final count = await executor.count(const QueryConfig());
        expect(count, equals(0));
      });

      test('can query within transaction', () async {
        await executor.create({'name': 'Existing', 'age': 40});

        await executor.transaction((tx) async {
          await tx.create({'name': 'New', 'age': 25});

          final authors = await tx.query(const QueryConfig());
          expect(authors.length, equals(2));
        });
      });

      test('can update within transaction', () async {
        await executor.create({'name': 'Alice', 'age': 25});

        await executor.transaction((tx) async {
          final config = QueryConfig(
            filters: [Q(const Comparison(ColumnRef('name'), ComparisonOp.eq, Value('Alice')))],
          );
          await tx.update(config, {'age': 26});
        });

        final authors = await executor.execute(const QueryConfig());
        expect(authors[0].age, equals(26));
      });

      test('can delete within transaction', () async {
        await executor.create({'name': 'Alice', 'age': 25});

        await executor.transaction((tx) async {
          final config = QueryConfig(
            filters: [Q(const Comparison(ColumnRef('name'), ComparisonOp.eq, Value('Alice')))],
          );
          await tx.delete(config);
        });

        final count = await executor.count(const QueryConfig());
        expect(count, equals(0));
      });

      test('bulkCreate within transaction', () async {
        await executor.transaction((tx) async {
          await tx.bulkCreate([
            {'name': 'Alice', 'age': 25},
            {'name': 'Bob', 'age': 30},
          ]);
        });

        final count = await executor.count(const QueryConfig());
        expect(count, equals(2));
      });
    });

    group('autoNow fields', () {
      late ModelExecutor<Author> executorWithTimestamps;

      setUp(() {
        executorWithTimestamps = ModelExecutor<Author>(
          pool: pool,
          compiler: compiler,
          tableName: 'authors',
          pkField: 'id',
          fromRow: Author.fromRow,
          toRow: Author.toRow,
          autoNowAddFields: ['created_at'],
          autoNowFields: ['updated_at'],
        );
      });

      test('sets autoNowAdd fields on create', () async {
        final author = await executorWithTimestamps.create({'name': 'Alice', 'age': 25});

        expect(author.createdAt, isNotNull);
      });

      test('sets autoNow fields on create', () async {
        final author = await executorWithTimestamps.create({'name': 'Alice', 'age': 25});

        expect(author.updatedAt, isNotNull);
      });

      test('sets autoNow fields on update', () async {
        final author = await executorWithTimestamps.create({'name': 'Alice', 'age': 25});
        final originalUpdatedAt = author.updatedAt;

        // Small delay to ensure timestamp changes
        await Future.delayed(const Duration(milliseconds: 10));

        final config = QueryConfig(filters: [Q(const Comparison(ColumnRef('id'), ComparisonOp.eq, Value(1)))]);
        await executorWithTimestamps.update(config, {'age': 26});

        final authors = await executorWithTimestamps.execute(config);
        expect(authors[0].updatedAt, isNot(equals(originalUpdatedAt)));
      });

      test('does not override explicit autoNowAdd values', () async {
        final explicitTime = DateTime(2020, 1, 1).toIso8601String();
        final author = await executorWithTimestamps.create({'name': 'Alice', 'age': 25, 'created_at': explicitTime});

        expect(author.createdAt?.year, equals(2020));
      });
    });
  });

  group('Manager', () {
    late SqliteAdapter adapter;
    late ConnectionPool pool;
    late SqlCompiler compiler;
    late ModelExecutor<Author> executor;
    late Manager<Author> manager;

    setUp(() async {
      final config = DatabaseConfig.sqliteMemory();
      adapter = const SqliteAdapter();
      pool = await adapter.createPool(config);
      compiler = SqlCompiler(adapter.dialect);

      await pool.withConnection((conn) async {
        await conn.execute('''
          CREATE TABLE authors (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            age INTEGER NOT NULL,
            created_at TEXT,
            updated_at TEXT
          )
        ''');
      });

      executor = ModelExecutor<Author>(
        pool: pool,
        compiler: compiler,
        tableName: 'authors',
        pkField: 'id',
        fromRow: Author.fromRow,
        toRow: Author.toRow,
      );

      manager = Manager<Author>(executor: executor);
    });

    tearDown(() async {
      await pool.close();
    });

    group('all()', () {
      test('returns all records', () async {
        await executor.bulkCreate([
          {'name': 'Alice', 'age': 25},
          {'name': 'Bob', 'age': 30},
        ]);

        final authors = await manager.all().toList();
        expect(authors.length, equals(2));
      });
    });

    group('filter()', () {
      test('filters by condition', () async {
        await executor.bulkCreate([
          {'name': 'Alice', 'age': 25},
          {'name': 'Bob', 'age': 30},
        ]);

        final authors = await manager
            .filter(Q(const Comparison(ColumnRef('age'), ComparisonOp.eq, Value(25))))
            .toList();
        expect(authors.length, equals(1));
        expect(authors[0].name, equals('Alice'));
      });
    });

    group('exclude()', () {
      test('excludes by condition', () async {
        await executor.bulkCreate([
          {'name': 'Alice', 'age': 25},
          {'name': 'Bob', 'age': 30},
        ]);

        final authors = await manager
            .exclude(Q(const Comparison(ColumnRef('age'), ComparisonOp.eq, Value(25))))
            .toList();
        expect(authors.length, equals(1));
        expect(authors[0].name, equals('Bob'));
      });
    });

    group('orderBy()', () {
      test('orders results', () async {
        await executor.bulkCreate([
          {'name': 'Charlie', 'age': 35},
          {'name': 'Alice', 'age': 25},
          {'name': 'Bob', 'age': 30},
        ]);

        final authors = await manager.orderBy(const OrderBy(ColumnRef('name'))).toList();
        expect(authors[0].name, equals('Alice'));
        expect(authors[1].name, equals('Bob'));
        expect(authors[2].name, equals('Charlie'));
      });
    });

    group('limit()', () {
      test('limits results', () async {
        await executor.bulkCreate([
          {'name': 'Alice', 'age': 25},
          {'name': 'Bob', 'age': 30},
          {'name': 'Charlie', 'age': 35},
        ]);

        final authors = await manager.limit(2).toList();
        expect(authors.length, equals(2));
      });
    });

    group('offset()', () {
      test('offsets results', () async {
        await executor.bulkCreate([
          {'name': 'Alice', 'age': 25},
          {'name': 'Bob', 'age': 30},
          {'name': 'Charlie', 'age': 35},
        ]);

        final authors = await manager.orderBy(const OrderBy(ColumnRef('id'))).offset(1).toList();
        expect(authors.length, equals(2));
        expect(authors[0].name, equals('Bob'));
      });
    });

    group('get()', () {
      test('gets by primary key', () async {
        await executor.create({'name': 'Alice', 'age': 25});

        final author = await manager.get(1);
        expect(author.name, equals('Alice'));
      });

      test('throws on not found', () async {
        expect(() => manager.get(999), throwsStateError);
      });
    });

    group('getOrNull()', () {
      test('returns null when not found', () async {
        final author = await manager.getOrNull(999);
        expect(author, isNull);
      });

      test('returns record when found', () async {
        await executor.create({'name': 'Alice', 'age': 25});

        final author = await manager.getOrNull(1);
        expect(author?.name, equals('Alice'));
      });
    });

    group('first()', () {
      test('returns first record', () async {
        await executor.bulkCreate([
          {'name': 'Alice', 'age': 25},
          {'name': 'Bob', 'age': 30},
        ]);

        final author = await manager.first();
        expect(author, isNotNull);
      });

      test('returns null when empty', () async {
        final author = await manager.first();
        expect(author, isNull);
      });
    });

    group('exists()', () {
      test('returns true when records exist', () async {
        await executor.create({'name': 'Alice', 'age': 25});

        final exists = await manager.exists();
        expect(exists, isTrue);
      });

      test('returns false when no records', () async {
        final exists = await manager.exists();
        expect(exists, isFalse);
      });
    });

    group('count()', () {
      test('returns count', () async {
        await executor.bulkCreate([
          {'name': 'Alice', 'age': 25},
          {'name': 'Bob', 'age': 30},
        ]);

        final count = await manager.count();
        expect(count, equals(2));
      });
    });

    group('create()', () {
      test('creates new record', () async {
        final author = await manager.create({'name': 'Alice', 'age': 25});

        expect(author.id, isNotNull);
        expect(author.name, equals('Alice'));
      });
    });

    group('bulkCreate()', () {
      test('creates multiple records', () async {
        final authors = await manager.bulkCreate([
          {'name': 'Alice', 'age': 25},
          {'name': 'Bob', 'age': 30},
        ]);

        expect(authors.length, equals(2));
      });
    });

    group('update()', () {
      test('updates matching records', () async {
        await executor.create({'name': 'Alice', 'age': 25});

        final affected = await manager.update(Q(const Comparison(ColumnRef('name'), ComparisonOp.eq, Value('Alice'))), {
          'age': 26,
        });

        expect(affected, equals(1));
      });
    });

    group('delete()', () {
      test('deletes matching records', () async {
        await executor.create({'name': 'Alice', 'age': 25});

        final affected = await manager.delete(Q(const Comparison(ColumnRef('name'), ComparisonOp.eq, Value('Alice'))));

        expect(affected, equals(1));
        expect(await manager.count(), equals(0));
      });
    });

    group('aggregate()', () {
      test('calculates aggregates', () async {
        await executor.bulkCreate([
          {'name': 'Alice', 'age': 25},
          {'name': 'Bob', 'age': 35},
        ]);

        final result = await manager.aggregate({'avg_age': Avg(const ColumnRef('age'))});
        expect(result['avg_age'], equals(30.0));
      });
    });

    group('raw()', () {
      test('executes raw SQL', () async {
        await executor.create({'name': 'Alice', 'age': 25});

        final rows = await manager.raw('SELECT * FROM authors');
        expect(rows.length, equals(1));
      });
    });

    group('getOrCreate()', () {
      test('creates when not exists', () async {
        final (author, created) = await manager.getOrCreate(
          condition: Q(const Comparison(ColumnRef('name'), ComparisonOp.eq, Value('Alice'))),
          defaults: {'name': 'Alice', 'age': 25},
        );

        expect(created, isTrue);
        expect(author.name, equals('Alice'));
      });

      test('gets when exists', () async {
        await executor.create({'name': 'Alice', 'age': 25});

        final (author, created) = await manager.getOrCreate(
          condition: Q(const Comparison(ColumnRef('name'), ComparisonOp.eq, Value('Alice'))),
          defaults: {'name': 'Alice', 'age': 30},
        );

        expect(created, isFalse);
        expect(author.age, equals(25)); // Original value, not defaults
      });
    });

    group('updateOrCreate()', () {
      test('creates when not exists', () async {
        final (author, created) = await manager.updateOrCreate(
          condition: Q(const Comparison(ColumnRef('name'), ComparisonOp.eq, Value('Alice'))),
          defaults: {'name': 'Alice', 'age': 25},
        );

        expect(created, isTrue);
        expect(author.name, equals('Alice'));
      });

      test('updates when exists', () async {
        await executor.create({'name': 'Alice', 'age': 25});

        final (author, created) = await manager.updateOrCreate(
          condition: Q(const Comparison(ColumnRef('name'), ComparisonOp.eq, Value('Alice'))),
          defaults: {'name': 'Alice', 'age': 30},
        );

        expect(created, isFalse);
        expect(author.age, equals(30)); // Updated value
      });
    });
  });

  group('FilteredManager', () {
    late SqliteAdapter adapter;
    late ConnectionPool pool;
    late SqlCompiler compiler;
    late ModelExecutor<Author> executor;

    setUp(() async {
      final config = DatabaseConfig.sqliteMemory();
      adapter = const SqliteAdapter();
      pool = await adapter.createPool(config);
      compiler = SqlCompiler(adapter.dialect);

      await pool.withConnection((conn) async {
        await conn.execute('''
          CREATE TABLE authors (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            age INTEGER NOT NULL,
            created_at TEXT,
            updated_at TEXT
          )
        ''');
      });

      executor = ModelExecutor<Author>(
        pool: pool,
        compiler: compiler,
        tableName: 'authors',
        pkField: 'id',
        fromRow: Author.fromRow,
        toRow: Author.toRow,
      );
    });

    tearDown(() async {
      await pool.close();
    });

    test('applies base filter', () async {
      await executor.bulkCreate([
        {'name': 'Alice', 'age': 25},
        {'name': 'Bob', 'age': 30},
        {'name': 'Charlie', 'age': 25},
      ]);

      final manager = FilteredManager<Author>(
        baseFilter: Q(const Comparison(ColumnRef('age'), ComparisonOp.eq, Value(25))),
        executor: executor,
      );

      final authors = await manager.all().toList();
      expect(authors.length, equals(2));
      expect(authors.every((a) => a.age == 25), isTrue);
    });

    test('combines base filter with additional filters', () async {
      await executor.bulkCreate([
        {'name': 'Alice', 'age': 25},
        {'name': 'Amy', 'age': 25},
        {'name': 'Bob', 'age': 25},
      ]);

      final manager = FilteredManager<Author>(
        baseFilter: Q(const Comparison(ColumnRef('age'), ComparisonOp.eq, Value(25))),
        executor: executor,
      );

      final authors = await manager
          .filter(Q(const Comparison(ColumnRef('name'), ComparisonOp.like, Value('A%'))))
          .toList();
      expect(authors.length, equals(2));
    });
  });

  group('Jao', () {
    tearDown(() {
      Jao.reset();
    });

    test('isInitialized returns false initially', () {
      expect(Jao.isInitialized, isFalse);
    });

    test('instance throws when not initialized', () {
      expect(() => Jao.instance, throwsStateError);
    });

    test('configure initializes Jao', () async {
      final adapter = const SqliteAdapter();
      final config = DatabaseConfig.sqliteMemory();

      await Jao.configure(adapter: adapter, config: config);

      expect(Jao.isInitialized, isTrue);
    });

    test('reset clears instance', () async {
      final adapter = const SqliteAdapter();
      final config = DatabaseConfig.sqliteMemory();

      await Jao.configure(adapter: adapter, config: config);
      Jao.reset();

      expect(Jao.isInitialized, isFalse);
    });

    test('registerModel and executor work together', () async {
      final adapter = const SqliteAdapter();
      final config = DatabaseConfig.sqliteMemory();

      await Jao.configure(adapter: adapter, config: config);

      Jao.registerModel<Author>(
        ModelRegistration<Author>(tableName: 'authors', pkField: 'id', fromRow: Author.fromRow, toRow: Author.toRow),
      );

      final executor = Jao.instance.executor<Author>();
      expect(executor, isNotNull);
      expect(executor, isA<ModelExecutor<Author>>());
    });

    test('executor returns null for unregistered model', () async {
      final adapter = const SqliteAdapter();
      final config = DatabaseConfig.sqliteMemory();

      await Jao.configure(adapter: adapter, config: config);

      final executor = Jao.instance.executor<String>();
      expect(executor, isNull);
    });

    test('executor caches created executors', () async {
      final adapter = const SqliteAdapter();
      final config = DatabaseConfig.sqliteMemory();

      await Jao.configure(adapter: adapter, config: config);

      Jao.registerModel<Author>(
        ModelRegistration<Author>(tableName: 'authors', pkField: 'id', fromRow: Author.fromRow, toRow: Author.toRow),
      );

      final executor1 = Jao.instance.executor<Author>();
      final executor2 = Jao.instance.executor<Author>();

      expect(identical(executor1, executor2), isTrue);
    });
  });

  group('Model exceptions', () {
    test('ObjectDoesNotExist toString with lookup value', () {
      const exception = ObjectDoesNotExist(Author, 123);
      expect(exception.toString(), contains('Author'));
      expect(exception.toString(), contains('123'));
    });

    test('ObjectDoesNotExist toString without lookup value', () {
      const exception = ObjectDoesNotExist(Author);
      expect(exception.toString(), contains('Author'));
      expect(exception.toString(), contains('does not exist'));
    });

    test('MultipleObjectsReturned toString', () {
      const exception = MultipleObjectsReturned(Author, 5);
      expect(exception.toString(), contains('Author'));
      expect(exception.toString(), contains('5'));
    });

    test('ValidationError toString', () {
      const exception = ValidationError({
        'name': ['Name is required'],
        'age': ['Must be positive'],
      });
      expect(exception.toString(), contains('name'));
      expect(exception.toString(), contains('Name is required'));
    });

    test('ValidationError.forField factory', () {
      final exception = ValidationError.forField('email', 'Invalid email');
      expect(exception.errors['email'], contains('Invalid email'));
    });
  });
}
