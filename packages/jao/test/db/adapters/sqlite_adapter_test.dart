import 'package:jao/jao.dart';
import 'package:test/test.dart';

void main() {
  group('SqliteAdapter', () {
    const adapter = SqliteAdapter();

    test('name is sqlite', () {
      expect(adapter.name, equals('sqlite'));
    });

    test('dialect is SqliteDialect', () {
      expect(adapter.dialect, isA<SqliteDialect>());
    });
  });

  group('SqliteConnection', () {
    late SqliteConnectionPool pool;
    late DatabaseConnection conn;

    setUp(() async {
      pool = await SqliteConnectionPool.create(DatabaseConfig.sqliteMemory());
      conn = await pool.acquire();
    });

    tearDown(() async {
      await pool.release(conn);
      await pool.close();
    });

    group('Connection Tests', () {
      test('connect creates connection', () {
        expect(conn.isOpen, isTrue);
      });

      test('connection executes raw SQL', () async {
        final result = await conn.execute('SELECT 1 + 1 as result');
        expect(result.rows, isNotEmpty);
        expect(result.rows.first['result'], equals(2));
      });

      test('connection returns query results', () async {
        await conn.execute('CREATE TABLE test_users (id INTEGER PRIMARY KEY, name TEXT)');
        await conn.execute("INSERT INTO test_users (name) VALUES ('Alice')");
        await conn.execute("INSERT INTO test_users (name) VALUES ('Bob')");

        final result = await conn.query('SELECT * FROM test_users ORDER BY id');
        expect(result.length, equals(2));
        expect(result[0]['name'], equals('Alice'));
        expect(result[1]['name'], equals('Bob'));
      });

      test('connection handles parameters', () async {
        await conn.execute('CREATE TABLE params_test (id INTEGER PRIMARY KEY, value TEXT)');
        await conn.execute('INSERT INTO params_test (value) VALUES (?)', ['test_value']);

        final result = await conn.query('SELECT * FROM params_test WHERE value = ?', ['test_value']);
        expect(result.length, equals(1));
        expect(result.first['value'], equals('test_value'));
      });

      test('scalar returns single value', () async {
        final result = await conn.scalar<int>('SELECT 42 as answer');
        expect(result, equals(42));
      });

      test('scalar returns null for empty result', () async {
        await conn.execute('CREATE TABLE empty_test (id INTEGER PRIMARY KEY)');
        final result = await conn.scalar<int>('SELECT id FROM empty_test LIMIT 1');
        expect(result, isNull);
      });
    });

    group('CRUD Tests', () {
      setUp(() async {
        await conn.execute('''
          CREATE TABLE crud_test (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            age INTEGER,
            active INTEGER DEFAULT 1
          )
        ''');
      });

      test('INSERT returns affected rows', () async {
        final result = await conn.execute("INSERT INTO crud_test (name, age) VALUES (?, ?)", ['John', 30]);
        expect(result.affectedRows, equals(1));
      });

      test('INSERT with RETURNING returns row', () async {
        final result = await conn.execute("INSERT INTO crud_test (name, age) VALUES (?, ?) RETURNING *", ['Jane', 25]);
        expect(result.rows, isNotEmpty);
        expect(result.rows.first['name'], equals('Jane'));
        expect(result.rows.first['id'], isNotNull);
      });

      test('SELECT returns rows as maps', () async {
        await conn.execute("INSERT INTO crud_test (name, age) VALUES (?, ?)", ['Alice', 28]);
        await conn.execute("INSERT INTO crud_test (name, age) VALUES (?, ?)", ['Bob', 32]);

        final rows = await conn.query('SELECT * FROM crud_test ORDER BY name');
        expect(rows.length, equals(2));
        expect(rows[0], isA<Map<String, dynamic>>());
        expect(rows[0]['name'], equals('Alice'));
      });

      test('SELECT with empty result', () async {
        final rows = await conn.query('SELECT * FROM crud_test WHERE id = 9999');
        expect(rows, isEmpty);
      });

      test('UPDATE returns affected count', () async {
        await conn.execute("INSERT INTO crud_test (name, age) VALUES (?, ?)", ['Test', 20]);

        final result = await conn.execute("UPDATE crud_test SET age = ? WHERE name = ?", [21, 'Test']);
        expect(result.affectedRows, equals(1));
      });

      test('DELETE returns affected count', () async {
        await conn.execute("INSERT INTO crud_test (name, age) VALUES (?, ?)", ['ToDelete', 99]);

        final result = await conn.execute("DELETE FROM crud_test WHERE name = ?", ['ToDelete']);
        expect(result.affectedRows, equals(1));
      });

      test('handles null values', () async {
        await conn.execute("INSERT INTO crud_test (name, age) VALUES (?, ?)", ['NoAge', null]);

        final rows = await conn.query("SELECT * FROM crud_test WHERE name = ?", ['NoAge']);
        expect(rows.first['age'], isNull);
      });

      test('handles boolean conversion', () async {
        await conn.execute("INSERT INTO crud_test (name, active) VALUES (?, ?)", ['BoolTest', true]);

        final rows = await conn.query("SELECT * FROM crud_test WHERE name = ?", ['BoolTest']);
        expect(rows.first['active'], equals(1));
      });

      test('handles DateTime conversion', () async {
        await conn.execute('''
          CREATE TABLE datetime_test (
            id INTEGER PRIMARY KEY,
            created_at TEXT
          )
        ''');

        final now = DateTime.now();
        await conn.execute("INSERT INTO datetime_test (created_at) VALUES (?)", [now]);

        final rows = await conn.query("SELECT * FROM datetime_test");
        expect(rows.first['created_at'], equals(now.toIso8601String()));
      });
    });
  });

  group('SqliteTransaction', () {
    late SqliteConnectionPool pool;
    late DatabaseConnection conn;

    setUp(() async {
      pool = await SqliteConnectionPool.create(DatabaseConfig.sqliteMemory());
      conn = await pool.acquire();
      await conn.execute('''
        CREATE TABLE tx_test (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          value TEXT
        )
      ''');
    });

    tearDown(() async {
      await pool.release(conn);
      await pool.close();
    });

    test('beginTransaction starts transaction', () async {
      final tx = await conn.beginTransaction();
      expect(tx.isActive, isTrue);
      await tx.rollback();
    });

    test('transaction.commit commits changes', () async {
      final tx = await conn.beginTransaction();
      await tx.execute("INSERT INTO tx_test (value) VALUES (?)", ['committed']);
      await tx.commit();

      final rows = await conn.query("SELECT * FROM tx_test WHERE value = ?", ['committed']);
      expect(rows.length, equals(1));
    });

    test('transaction.rollback reverts changes', () async {
      final tx = await conn.beginTransaction();
      await tx.execute("INSERT INTO tx_test (value) VALUES (?)", ['rollback_me']);
      await tx.rollback();

      final rows = await conn.query("SELECT * FROM tx_test WHERE value = ?", ['rollback_me']);
      expect(rows, isEmpty);
    });

    test('transaction isActive becomes false after commit', () async {
      final tx = await conn.beginTransaction();
      expect(tx.isActive, isTrue);
      await tx.commit();
      expect(tx.isActive, isFalse);
    });

    test('transaction isActive becomes false after rollback', () async {
      final tx = await conn.beginTransaction();
      expect(tx.isActive, isTrue);
      await tx.rollback();
      expect(tx.isActive, isFalse);
    });
  });

  group('SqliteConnectionPool', () {
    test('createPool creates pool', () async {
      final pool = await SqliteConnectionPool.create(DatabaseConfig.sqliteMemory());
      expect(pool.size, equals(1));
      await pool.close();
    });

    test('pool.acquire returns connection', () async {
      final pool = await SqliteConnectionPool.create(DatabaseConfig.sqliteMemory());
      final conn = await pool.acquire();
      expect(conn, isNotNull);
      expect(conn.isOpen, isTrue);
      await pool.release(conn);
      await pool.close();
    });

    test('pool.release returns to pool', () async {
      final pool = await SqliteConnectionPool.create(DatabaseConfig.sqliteMemory());
      expect(pool.inUse, equals(0));

      final conn = await pool.acquire();
      expect(pool.inUse, equals(1));

      await pool.release(conn);
      expect(pool.inUse, equals(0));

      await pool.close();
    });

    test('pool.withConnection auto-releases', () async {
      final pool = await SqliteConnectionPool.create(DatabaseConfig.sqliteMemory());

      await pool.withConnection((conn) async {
        expect(pool.inUse, equals(1));
        await conn.execute('SELECT 1');
      });

      expect(pool.inUse, equals(0));
      await pool.close();
    });

    test('pool.close closes all connections', () async {
      final pool = await SqliteConnectionPool.create(DatabaseConfig.sqliteMemory());
      final conn = await pool.acquire();
      await pool.release(conn);
      await pool.close();

      expect(pool.size, equals(0));
    });

    test('withTransaction auto-commits on success', () async {
      final pool = await SqliteConnectionPool.create(DatabaseConfig.sqliteMemory());

      await pool.withConnection((conn) async {
        await conn.execute('CREATE TABLE auto_commit_test (id INTEGER PRIMARY KEY, val TEXT)');
      });

      await pool.withTransaction((tx) async {
        await tx.execute("INSERT INTO auto_commit_test (val) VALUES (?)", ['success']);
      });

      final rows = await pool.withConnection((conn) => conn.query('SELECT * FROM auto_commit_test'));
      expect(rows.length, equals(1));
      expect(rows.first['val'], equals('success'));

      await pool.close();
    });

    test('withTransaction auto-rollbacks on error', () async {
      final pool = await SqliteConnectionPool.create(DatabaseConfig.sqliteMemory());

      await pool.withConnection((conn) async {
        await conn.execute('CREATE TABLE auto_rollback_test (id INTEGER PRIMARY KEY, val TEXT)');
      });

      try {
        await pool.withTransaction((tx) async {
          await tx.execute("INSERT INTO auto_rollback_test (val) VALUES (?)", ['should_rollback']);
          throw Exception('Simulated error');
        });
      } catch (_) {
        // Expected
      }

      final rows = await pool.withConnection((conn) => conn.query('SELECT * FROM auto_rollback_test'));
      expect(rows, isEmpty);

      await pool.close();
    });

    test('acquire throws when pool is closed', () async {
      final pool = await SqliteConnectionPool.create(DatabaseConfig.sqliteMemory());
      await pool.close();

      expect(() => pool.acquire(), throwsStateError);
    });
  });

  group('Schema Introspection', () {
    const adapter = SqliteAdapter();
    late SqliteConnectionPool pool;
    late DatabaseConnection conn;

    setUp(() async {
      pool = await SqliteConnectionPool.create(DatabaseConfig.sqliteMemory());
      conn = await pool.acquire();
    });

    tearDown(() async {
      await pool.release(conn);
      await pool.close();
    });

    test('getTables returns table names', () async {
      await conn.execute('CREATE TABLE table_a (id INTEGER PRIMARY KEY)');
      await conn.execute('CREATE TABLE table_b (id INTEGER PRIMARY KEY)');

      final tables = await adapter.getTables(conn);
      expect(tables, containsAll(['table_a', 'table_b']));
    });

    test('getTables excludes sqlite internal tables', () async {
      await conn.execute('CREATE TABLE user_table (id INTEGER PRIMARY KEY)');

      final tables = await adapter.getTables(conn);
      expect(tables, isNot(contains('sqlite_sequence')));
      expect(tables, isNot(contains('sqlite_master')));
    });

    test('tableExists returns true for existing table', () async {
      await conn.execute('CREATE TABLE exists_test (id INTEGER PRIMARY KEY)');

      final exists = await adapter.tableExists(conn, 'exists_test');
      expect(exists, isTrue);
    });

    test('tableExists returns false for missing table', () async {
      final exists = await adapter.tableExists(conn, 'nonexistent_table');
      expect(exists, isFalse);
    });

    test('getTableSchema returns columns', () async {
      await conn.execute('''
        CREATE TABLE schema_test (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          age INTEGER,
          email TEXT UNIQUE
        )
      ''');

      final schema = await adapter.getTableSchema(conn, 'schema_test');
      expect(schema.columns.length, equals(4));
      expect(schema.columns.map((c) => c.name), containsAll(['id', 'name', 'age', 'email']));
    });

    test('getTableSchema returns column types', () async {
      await conn.execute('''
        CREATE TABLE type_test (
          int_col INTEGER,
          text_col TEXT,
          real_col REAL,
          blob_col BLOB
        )
      ''');

      final schema = await adapter.getTableSchema(conn, 'type_test');

      final intCol = schema.columns.firstWhere((c) => c.name == 'int_col');
      expect(intCol.type, equals('INTEGER'));

      final textCol = schema.columns.firstWhere((c) => c.name == 'text_col');
      expect(textCol.type, equals('TEXT'));
    });

    test('getTableSchema returns nullable flag', () async {
      await conn.execute('''
        CREATE TABLE nullable_test (
          required_col TEXT NOT NULL,
          optional_col TEXT
        )
      ''');

      final schema = await adapter.getTableSchema(conn, 'nullable_test');

      final required = schema.columns.firstWhere((c) => c.name == 'required_col');
      expect(required.nullable, isFalse);

      final optional = schema.columns.firstWhere((c) => c.name == 'optional_col');
      expect(optional.nullable, isTrue);
    });

    test('getTableSchema returns default values', () async {
      await conn.execute('''
        CREATE TABLE default_test (
          id INTEGER PRIMARY KEY,
          status TEXT DEFAULT 'active',
          count INTEGER DEFAULT 0
        )
      ''');

      final schema = await adapter.getTableSchema(conn, 'default_test');

      final status = schema.columns.firstWhere((c) => c.name == 'status');
      expect(status.defaultValue, equals("'active'"));

      final count = schema.columns.firstWhere((c) => c.name == 'count');
      expect(count.defaultValue, equals('0'));
    });

    test('getTableSchema returns primary key', () async {
      await conn.execute('''
        CREATE TABLE pk_test (
          id INTEGER PRIMARY KEY,
          name TEXT
        )
      ''');

      final schema = await adapter.getTableSchema(conn, 'pk_test');
      expect(schema.primaryKey, equals('id'));

      final idCol = schema.columns.firstWhere((c) => c.name == 'id');
      expect(idCol.isPrimaryKey, isTrue);
    });

    test('getTableSchema returns indexes', () async {
      await conn.execute('''
        CREATE TABLE index_test (
          id INTEGER PRIMARY KEY,
          email TEXT,
          name TEXT
        )
      ''');
      await conn.execute('CREATE INDEX idx_email ON index_test(email)');
      await conn.execute('CREATE UNIQUE INDEX idx_name ON index_test(name)');

      final schema = await adapter.getTableSchema(conn, 'index_test');

      expect(schema.indexes.length, greaterThanOrEqualTo(2));

      final emailIdx = schema.indexes.firstWhere((i) => i.name == 'idx_email');
      expect(emailIdx.columns, contains('email'));
      expect(emailIdx.unique, isFalse);

      final nameIdx = schema.indexes.firstWhere((i) => i.name == 'idx_name');
      expect(nameIdx.columns, contains('name'));
      expect(nameIdx.unique, isTrue);
    });

    test('getTableSchema returns foreign keys', () async {
      await conn.execute('CREATE TABLE fk_parent (id INTEGER PRIMARY KEY, name TEXT)');
      await conn.execute('''
        CREATE TABLE fk_child (
          id INTEGER PRIMARY KEY,
          parent_id INTEGER,
          FOREIGN KEY (parent_id) REFERENCES fk_parent(id) ON DELETE CASCADE
        )
      ''');

      final schema = await adapter.getTableSchema(conn, 'fk_child');

      expect(schema.constraints, isNotEmpty);
      final fk = schema.constraints.firstWhere((c) => c.type == ConstraintType.foreignKey);
      expect(fk.columns, contains('parent_id'));
      expect(fk.referencedTable, equals('fk_parent'));
      expect(fk.referencedColumns, contains('id'));
      expect(fk.onDelete, equals('CASCADE'));
    });
  });

  group('Parameter Conversion', () {
    late SqliteConnectionPool pool;
    late DatabaseConnection conn;

    setUp(() async {
      pool = await SqliteConnectionPool.create(DatabaseConfig.sqliteMemory());
      conn = await pool.acquire();
    });

    tearDown(() async {
      await pool.release(conn);
      await pool.close();
    });

    test('converts \$1, \$2 placeholders to ?', () async {
      await conn.execute('CREATE TABLE placeholder_test (a INTEGER, b INTEGER)');

      // The SQLite adapter should convert $1, $2 to ?
      await conn.execute('INSERT INTO placeholder_test (a, b) VALUES (\$1, \$2)', [1, 2]);

      final rows = await conn.query('SELECT * FROM placeholder_test');
      expect(rows.first['a'], equals(1));
      expect(rows.first['b'], equals(2));
    });

    test('converts ?1, ?2 placeholders to ?', () async {
      await conn.execute('CREATE TABLE qmark_test (a INTEGER, b INTEGER)');

      await conn.execute('INSERT INTO qmark_test (a, b) VALUES (?1, ?2)', [10, 20]);

      final rows = await conn.query('SELECT * FROM qmark_test');
      expect(rows.first['a'], equals(10));
      expect(rows.first['b'], equals(20));
    });
  });

  group('SqliteException', () {
    test('includes message', () {
      final ex = SqliteException('Test error');
      expect(ex.toString(), contains('Test error'));
    });

    test('includes SQL when provided', () {
      final ex = SqliteException('Query failed', sql: 'SELECT * FROM bad');
      expect(ex.toString(), contains('SELECT * FROM bad'));
    });

    test('includes database when provided', () {
      final ex = SqliteException('Error', database: 'test.db');
      expect(ex.toString(), contains('test.db'));
    });
  });

  group('generateTableRecreationSql', () {
    test('generates basic nullability change SQL', () {
      final schema = TableSchema(
        name: 'items',
        columns: [
          ColumnSchema(name: 'id', type: 'INTEGER', nullable: false, isPrimaryKey: true),
          ColumnSchema(name: 'name', type: 'TEXT', nullable: false),
        ],
        indexes: [],
        constraints: [],
        primaryKey: 'id',
      );

      final statements = generateTableRecreationSql(
        tableName: 'items',
        currentSchema: schema,
        columnName: 'name',
        newNullable: true,
      );

      expect(statements[0], contains('ALTER TABLE "items" RENAME TO "_old_items"'));
      expect(statements[1], contains('CREATE TABLE "items"'));
      expect(statements[1], isNot(contains('"name" TEXT NOT NULL')));
      expect(statements[2], contains('INSERT INTO "items"'));
      expect(statements[3], contains('DROP TABLE "_old_items"'));
    });

    test('generates type change SQL', () {
      final schema = TableSchema(
        name: 'products',
        columns: [
          ColumnSchema(name: 'id', type: 'INTEGER', nullable: false, isPrimaryKey: true),
          ColumnSchema(name: 'price', type: 'INTEGER', nullable: false),
        ],
        indexes: [],
        constraints: [],
        primaryKey: 'id',
      );

      final statements = generateTableRecreationSql(
        tableName: 'products',
        currentSchema: schema,
        columnName: 'price',
        newType: FieldType.decimal,
      );

      expect(statements[1], contains('REAL'));
    });

    test('generates column rename SQL', () {
      final schema = TableSchema(
        name: 'users',
        columns: [
          ColumnSchema(name: 'id', type: 'INTEGER', nullable: false, isPrimaryKey: true),
          ColumnSchema(name: 'name', type: 'TEXT', nullable: false),
        ],
        indexes: [],
        constraints: [],
        primaryKey: 'id',
      );

      final statements = generateTableRecreationSql(
        tableName: 'users',
        currentSchema: schema,
        columnName: 'name',
        renameTo: 'full_name',
      );

      expect(statements[1], contains('"full_name" TEXT'));
      expect(statements[2], contains('INSERT INTO "users" ("id", "full_name")'));
      expect(statements[2], contains('SELECT "id", "name" FROM "_old_users"'));
    });

    test('generates default value change SQL', () {
      final schema = TableSchema(
        name: 'settings',
        columns: [
          ColumnSchema(name: 'id', type: 'INTEGER', nullable: false, isPrimaryKey: true),
          ColumnSchema(name: 'active', type: 'INTEGER', nullable: false),
        ],
        indexes: [],
        constraints: [],
        primaryKey: 'id',
      );

      final statements = generateTableRecreationSql(
        tableName: 'settings',
        currentSchema: schema,
        columnName: 'active',
        newDefault: '1',
      );

      expect(statements[1], contains('DEFAULT 1'));
    });

    test('generates drop default SQL', () {
      final schema = TableSchema(
        name: 'settings',
        columns: [
          ColumnSchema(name: 'id', type: 'INTEGER', nullable: false, isPrimaryKey: true),
          ColumnSchema(name: 'theme', type: 'TEXT', nullable: false, defaultValue: "'dark'"),
        ],
        indexes: [],
        constraints: [],
        primaryKey: 'id',
      );

      final statements = generateTableRecreationSql(
        tableName: 'settings',
        currentSchema: schema,
        columnName: 'theme',
        dropDefault: true,
      );

      expect(statements[1], isNot(contains('DEFAULT')));
    });

    test('handles non-INTEGER primary key', () {
      final schema = TableSchema(
        name: 'entities',
        columns: [
          ColumnSchema(name: 'uuid', type: 'TEXT', nullable: false, isPrimaryKey: true),
          ColumnSchema(name: 'name', type: 'TEXT', nullable: false),
        ],
        indexes: [],
        constraints: [],
        primaryKey: 'uuid',
      );

      final statements = generateTableRecreationSql(
        tableName: 'entities',
        currentSchema: schema,
        columnName: 'name',
        newNullable: true,
      );

      expect(statements[1], contains('PRIMARY KEY ("uuid")'));
    });

    test('recreates foreign key constraints', () {
      final schema = TableSchema(
        name: 'posts',
        columns: [
          ColumnSchema(name: 'id', type: 'INTEGER', nullable: false, isPrimaryKey: true),
          ColumnSchema(name: 'author_id', type: 'INTEGER', nullable: false),
          ColumnSchema(name: 'title', type: 'TEXT', nullable: false),
        ],
        indexes: [],
        constraints: [
          ConstraintSchema(
            name: 'fk_posts_author',
            type: ConstraintType.foreignKey,
            columns: ['author_id'],
            referencedTable: 'users',
            referencedColumns: ['id'],
            onDelete: 'CASCADE',
            onUpdate: 'NO ACTION',
          ),
        ],
        primaryKey: 'id',
      );

      final statements = generateTableRecreationSql(
        tableName: 'posts',
        currentSchema: schema,
        columnName: 'title',
        newNullable: true,
      );

      expect(statements[1], contains('FOREIGN KEY ("author_id") REFERENCES "users"("id")'));
      expect(statements[1], contains('ON DELETE CASCADE'));
    });

    test('renames FK column when column is renamed', () {
      final schema = TableSchema(
        name: 'posts',
        columns: [
          ColumnSchema(name: 'id', type: 'INTEGER', nullable: false, isPrimaryKey: true),
          ColumnSchema(name: 'author_id', type: 'INTEGER', nullable: false),
        ],
        indexes: [],
        constraints: [
          ConstraintSchema(
            name: 'fk_posts_author',
            type: ConstraintType.foreignKey,
            columns: ['author_id'],
            referencedTable: 'users',
            referencedColumns: ['id'],
          ),
        ],
        primaryKey: 'id',
      );

      final statements = generateTableRecreationSql(
        tableName: 'posts',
        currentSchema: schema,
        columnName: 'author_id',
        renameTo: 'user_id',
      );

      expect(statements[1], contains('FOREIGN KEY ("user_id") REFERENCES "users"("id")'));
    });

    test('recreates indexes', () {
      final schema = TableSchema(
        name: 'users',
        columns: [
          ColumnSchema(name: 'id', type: 'INTEGER', nullable: false, isPrimaryKey: true),
          ColumnSchema(name: 'email', type: 'TEXT', nullable: false),
        ],
        indexes: [
          IndexSchema(name: 'idx_users_email', columns: ['email'], unique: false),
        ],
        constraints: [],
        primaryKey: 'id',
      );

      final statements = generateTableRecreationSql(
        tableName: 'users',
        currentSchema: schema,
        columnName: 'email',
        newNullable: true,
      );

      expect(statements.last, contains('CREATE INDEX "idx_users_email" ON "users" ("email")'));
    });

    test('recreates unique indexes', () {
      final schema = TableSchema(
        name: 'users',
        columns: [
          ColumnSchema(name: 'id', type: 'INTEGER', nullable: false, isPrimaryKey: true),
          ColumnSchema(name: 'email', type: 'TEXT', nullable: false),
        ],
        indexes: [
          IndexSchema(name: 'idx_users_email_unique', columns: ['email'], unique: true),
        ],
        constraints: [],
        primaryKey: 'id',
      );

      final statements = generateTableRecreationSql(
        tableName: 'users',
        currentSchema: schema,
        columnName: 'email',
        newNullable: true,
      );

      expect(statements.last, contains('CREATE UNIQUE INDEX'));
    });

    test('renames index column when column is renamed', () {
      final schema = TableSchema(
        name: 'users',
        columns: [
          ColumnSchema(name: 'id', type: 'INTEGER', nullable: false, isPrimaryKey: true),
          ColumnSchema(name: 'name', type: 'TEXT', nullable: false),
        ],
        indexes: [
          IndexSchema(name: 'idx_users_name', columns: ['name'], unique: false),
        ],
        constraints: [],
        primaryKey: 'id',
      );

      final statements = generateTableRecreationSql(
        tableName: 'users',
        currentSchema: schema,
        columnName: 'name',
        renameTo: 'full_name',
      );

      expect(statements.last, contains('CREATE INDEX "idx_users_name" ON "users" ("full_name")'));
    });

    test('skips sqlite auto-created indexes', () {
      final schema = TableSchema(
        name: 'users',
        columns: [
          ColumnSchema(name: 'id', type: 'INTEGER', nullable: false, isPrimaryKey: true),
          ColumnSchema(name: 'email', type: 'TEXT', nullable: false),
        ],
        indexes: [
          IndexSchema(name: 'sqlite_autoindex_users_1', columns: ['id'], unique: true),
          IndexSchema(name: 'idx_users_email', columns: ['email'], unique: false),
        ],
        constraints: [],
        primaryKey: 'id',
      );

      final statements = generateTableRecreationSql(
        tableName: 'users',
        currentSchema: schema,
        columnName: 'email',
        newNullable: true,
      );

      expect(statements.any((s) => s.contains('sqlite_autoindex')), isFalse);
      expect(statements.any((s) => s.contains('idx_users_email')), isTrue);
    });
  });
}
