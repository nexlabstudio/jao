import 'package:jao/jao.dart';
import 'package:test/test.dart';

// Test migrations
class CreateUsersTable extends Migration {
  @override
  String get name => '001_create_users';

  @override
  void up(MigrationBuilder builder) {
    builder.createTable('users', (table) {
      table.id();
      table.string('name');
      table.string('email');
      table.timestamps();
    });
  }

  @override
  void down(MigrationBuilder builder) {
    builder.dropTable('users');
  }
}

class CreatePostsTable extends Migration {
  @override
  String get name => '002_create_posts';

  @override
  void up(MigrationBuilder builder) {
    builder.createTable('posts', (table) {
      table.id();
      table.string('title');
      table.text('body', nullable: true);
      table.foreignKey('user_id', 'users');
      table.timestamps();
    });
  }

  @override
  void down(MigrationBuilder builder) {
    builder.dropTable('posts');
  }
}

class AddStatusToUsers extends Migration {
  @override
  String get name => '003_add_status_to_users';

  @override
  void up(MigrationBuilder builder) {
    builder.addStringColumn('users', 'status', nullable: true);
  }

  @override
  void down(MigrationBuilder builder) {
    builder.dropColumn('users', 'status');
  }
}

class CreateIndexOnEmail extends Migration {
  @override
  String get name => '004_create_index_on_email';

  @override
  void up(MigrationBuilder builder) {
    builder.createUniqueIndex('users', ['email']);
  }

  @override
  void down(MigrationBuilder builder) {
    builder.dropIndex('idx_users_email');
  }
}

class RenameUsersToAccounts extends Migration {
  @override
  String get name => '005_rename_users_to_accounts';

  @override
  void up(MigrationBuilder builder) {
    builder.renameTable('users', 'accounts');
  }

  @override
  void down(MigrationBuilder builder) {
    builder.renameTable('accounts', 'users');
  }
}

class FailingMigration extends Migration {
  @override
  String get name => '999_failing_migration';

  @override
  void up(MigrationBuilder builder) {
    builder.rawSql('SELECT * FROM nonexistent_table');
  }

  @override
  void down(MigrationBuilder builder) {
    // No-op
  }
}

// Auto-reversible migrations (only define up, down is auto-generated)
class AutoReverseCreateCategories extends Migration {
  @override
  String get name => '010_auto_create_categories';

  @override
  bool get autoReverse => true;

  @override
  void up(MigrationBuilder builder) {
    builder.createTable('categories', (table) {
      table.id();
      table.string('name');
    });
  }

  @override
  void down(MigrationBuilder builder) {
    // Not used - autoReverse will generate DROP TABLE
  }
}

class AutoReverseAddIndex extends Migration {
  @override
  String get name => '011_auto_add_category_index';

  @override
  bool get autoReverse => true;

  @override
  void up(MigrationBuilder builder) {
    builder.createIndex('categories', ['name']);
  }

  @override
  void down(MigrationBuilder builder) {
    // Not used - autoReverse will generate DROP INDEX
  }
}

class AutoReverseMultipleOps extends Migration {
  @override
  String get name => '012_auto_multiple_ops';

  @override
  bool get autoReverse => true;

  @override
  void up(MigrationBuilder builder) {
    builder.createTable('tags', (table) {
      table.id();
      table.string('label');
    });
    builder.createIndex('tags', ['label'], unique: true);
  }

  @override
  void down(MigrationBuilder builder) {
    // Not used - autoReverse will:
    // 1. DROP INDEX (reversed first)
    // 2. DROP TABLE
  }
}

// Migration for testing AlterColumn (SQLite table recreation)
class CreateItemsTable extends Migration {
  @override
  String get name => '020_create_items';

  @override
  void up(MigrationBuilder builder) {
    builder.createTable('items', (table) {
      table.id();
      table.string('name');
      table.text('description');
    });
  }

  @override
  void down(MigrationBuilder builder) {
    builder.dropTable('items');
  }
}

class MakeDescriptionNullable extends Migration {
  @override
  String get name => '021_make_description_nullable';

  @override
  void up(MigrationBuilder builder) {
    builder.alterColumn('items', 'description', (col) {
      col.nullable();
    });
  }

  @override
  void down(MigrationBuilder builder) {
    builder.alterColumn('items', 'description', (col) {
      col.notNullable();
    });
  }
}

class CreateAuthorsTable extends Migration {
  @override
  String get name => '030_create_authors';

  @override
  void up(MigrationBuilder builder) {
    builder.createTable('authors', (table) {
      table.id();
      table.string('name');
    });
  }

  @override
  void down(MigrationBuilder builder) {
    builder.dropTable('authors');
  }
}

class CreateBooksTable extends Migration {
  @override
  String get name => '031_create_books';

  @override
  void up(MigrationBuilder builder) {
    builder.createTable('books', (table) {
      table.id();
      table.string('title');
      table.integer('author_id');
    });
  }

  @override
  void down(MigrationBuilder builder) {
    builder.dropTable('books');
  }
}

class AddBookAuthorFk extends Migration {
  @override
  String get name => '032_add_book_author_fk';

  @override
  void up(MigrationBuilder builder) {
    builder.addForeignKey('books', 'author_id', 'authors', referencedColumn: 'id');
  }

  @override
  void down(MigrationBuilder builder) {
    builder.dropConstraint('books', 'fk_books_author_id');
  }
}

class CreateBooksWithFkTable extends Migration {
  @override
  String get name => '033_create_books_with_fk';

  @override
  void up(MigrationBuilder builder) {
    builder.createTable('books_with_fk', (table) {
      table.id();
      table.string('title');
      table.foreignKey('author_id', 'authors');
    });
  }

  @override
  void down(MigrationBuilder builder) {
    builder.dropTable('books_with_fk');
  }
}

class DropBookAuthorFk extends Migration {
  @override
  String get name => '034_drop_book_author_fk';

  @override
  void up(MigrationBuilder builder) {
    builder.dropConstraint('books_with_fk', 'fk_books_with_fk_author_id');
  }

  @override
  void down(MigrationBuilder builder) {
    builder.addForeignKey('books_with_fk', 'author_id', 'authors', referencedColumn: 'id');
  }
}

void main() {
  group('MigrationBuilder', () {
    group('createTable()', () {
      test('adds CreateTable operation', () {
        final builder = MigrationBuilder();
        builder.createTable('users', (table) {
          table.id();
          table.string('name');
        });

        expect(builder.operations.length, equals(1));
        expect(builder.operations.first, isA<CreateTable>());
      });

      test('passes TableBuilder to callback', () {
        final builder = MigrationBuilder();
        builder.createTable('users', (table) {
          table.id();
          table.string('name');
          table.text('bio', nullable: true);
        });

        final op = builder.operations.first as CreateTable;
        expect(op.table.name, equals('users'));
        expect(op.table.columns.length, equals(3));
      });
    });

    group('createTableIfNotExists()', () {
      test('adds CreateTable with ifNotExists flag', () {
        final builder = MigrationBuilder();
        builder.createTableIfNotExists('users', (table) {
          table.id();
        });

        final op = builder.operations.first as CreateTable;
        expect(op.table.ifNotExists, isTrue);
      });
    });

    group('dropTable()', () {
      test('adds DropTable operation', () {
        final builder = MigrationBuilder();
        builder.dropTable('users');

        expect(builder.operations.first, isA<DropTable>());
        final op = builder.operations.first as DropTable;
        expect(op.name, equals('users'));
      });

      test('dropTable with ifExists', () {
        final builder = MigrationBuilder();
        builder.dropTable('users', ifExists: true);

        final op = builder.operations.first as DropTable;
        expect(op.ifExists, isTrue);
      });

      test('dropTable with cascade', () {
        final builder = MigrationBuilder();
        builder.dropTable('users', cascade: true);

        final op = builder.operations.first as DropTable;
        expect(op.cascade, isTrue);
      });
    });

    group('renameTable()', () {
      test('adds RenameTable operation', () {
        final builder = MigrationBuilder();
        builder.renameTable('old_name', 'new_name');

        expect(builder.operations.first, isA<RenameTable>());
        final op = builder.operations.first as RenameTable;
        expect(op.oldName, equals('old_name'));
        expect(op.newName, equals('new_name'));
      });
    });

    group('addColumn()', () {
      test('adds AddColumn operation', () {
        final builder = MigrationBuilder();
        builder.addColumn('users', 'age', FieldType.integer);

        expect(builder.operations.first, isA<AddColumn>());
        final op = builder.operations.first as AddColumn;
        expect(op.table, equals('users'));
        expect(op.column.name, equals('age'));
        expect(op.column.type, equals(FieldType.integer));
      });

      test('addColumn with nullable', () {
        final builder = MigrationBuilder();
        builder.addColumn('users', 'nickname', FieldType.varchar, nullable: true);

        final op = builder.operations.first as AddColumn;
        expect(op.column.nullable, isTrue);
      });

      test('addColumn with defaultValue', () {
        final builder = MigrationBuilder();
        builder.addColumn('users', 'role', FieldType.varchar, defaultValue: "'user'");

        final op = builder.operations.first as AddColumn;
        expect(op.column.defaultValue, equals("'user'"));
      });
    });

    group('addStringColumn()', () {
      test('adds varchar column', () {
        final builder = MigrationBuilder();
        builder.addStringColumn('users', 'name');

        final op = builder.operations.first as AddColumn;
        expect(op.column.type, equals(FieldType.varchar));
        expect(op.column.length, equals(255));
      });

      test('with custom length', () {
        final builder = MigrationBuilder();
        builder.addStringColumn('users', 'slug', length: 100);

        final op = builder.operations.first as AddColumn;
        expect(op.column.length, equals(100));
      });
    });

    group('addIntegerColumn()', () {
      test('adds integer column', () {
        final builder = MigrationBuilder();
        builder.addIntegerColumn('users', 'age');

        final op = builder.operations.first as AddColumn;
        expect(op.column.type, equals(FieldType.integer));
      });

      test('with defaultValue', () {
        final builder = MigrationBuilder();
        builder.addIntegerColumn('users', 'score', defaultValue: 0);

        final op = builder.operations.first as AddColumn;
        expect(op.column.defaultValue, equals('0'));
      });
    });

    group('addBooleanColumn()', () {
      test('adds boolean column', () {
        final builder = MigrationBuilder();
        builder.addBooleanColumn('users', 'active');

        final op = builder.operations.first as AddColumn;
        expect(op.column.type, equals(FieldType.boolean));
      });

      test('with defaultValue true', () {
        final builder = MigrationBuilder();
        builder.addBooleanColumn('users', 'active', defaultValue: true);

        final op = builder.operations.first as AddColumn;
        expect(op.column.defaultValue, equals('true'));
      });
    });

    group('addTimestampColumn()', () {
      test('adds timestampTz column', () {
        final builder = MigrationBuilder();
        builder.addTimestampColumn('users', 'published_at');

        final op = builder.operations.first as AddColumn;
        expect(op.column.type, equals(FieldType.timestampTz));
      });

      test('with useCurrent', () {
        final builder = MigrationBuilder();
        builder.addTimestampColumn('users', 'created_at', useCurrent: true);

        final op = builder.operations.first as AddColumn;
        expect(op.column.defaultValue, equals('CURRENT_TIMESTAMP'));
      });
    });

    group('dropColumn()', () {
      test('adds DropColumn operation', () {
        final builder = MigrationBuilder();
        builder.dropColumn('users', 'nickname');

        expect(builder.operations.first, isA<DropColumn>());
        final op = builder.operations.first as DropColumn;
        expect(op.table, equals('users'));
        expect(op.column, equals('nickname'));
      });

      test('with cascade', () {
        final builder = MigrationBuilder();
        builder.dropColumn('users', 'id', cascade: true);

        final op = builder.operations.first as DropColumn;
        expect(op.cascade, isTrue);
      });
    });

    group('renameColumn()', () {
      test('adds RenameColumn operation', () {
        final builder = MigrationBuilder();
        builder.renameColumn('users', 'old_col', 'new_col');

        expect(builder.operations.first, isA<RenameColumn>());
        final op = builder.operations.first as RenameColumn;
        expect(op.table, equals('users'));
        expect(op.oldName, equals('old_col'));
        expect(op.newName, equals('new_col'));
      });
    });

    group('alterColumn()', () {
      test('adds AlterColumn operation', () {
        final builder = MigrationBuilder();
        builder.alterColumn('users', 'name', (col) {
          col.nullable();
        });

        expect(builder.operations.first, isA<AlterColumn>());
      });
    });

    group('createIndex()', () {
      test('adds CreateIndex operation', () {
        final builder = MigrationBuilder();
        builder.createIndex('users', ['email']);

        expect(builder.operations.first, isA<CreateIndex>());
        final op = builder.operations.first as CreateIndex;
        expect(op.table, equals('users'));
        expect(op.index.columns, equals(['email']));
      });

      test('with custom name', () {
        final builder = MigrationBuilder();
        builder.createIndex('users', ['email'], name: 'my_email_idx');

        final op = builder.operations.first as CreateIndex;
        expect(op.index.name, equals('my_email_idx'));
      });

      test('generates default name', () {
        final builder = MigrationBuilder();
        builder.createIndex('users', ['first_name', 'last_name']);

        final op = builder.operations.first as CreateIndex;
        expect(op.index.name, equals('idx_users_first_name_last_name'));
      });

      test('with unique flag', () {
        final builder = MigrationBuilder();
        builder.createIndex('users', ['email'], unique: true);

        final op = builder.operations.first as CreateIndex;
        expect(op.index.unique, isTrue);
      });
    });

    group('createUniqueIndex()', () {
      test('creates unique index', () {
        final builder = MigrationBuilder();
        builder.createUniqueIndex('users', ['email']);

        final op = builder.operations.first as CreateIndex;
        expect(op.index.unique, isTrue);
      });
    });

    group('dropIndex()', () {
      test('adds DropIndex operation', () {
        final builder = MigrationBuilder();
        builder.dropIndex('idx_users_email');

        expect(builder.operations.first, isA<DropIndex>());
        final op = builder.operations.first as DropIndex;
        expect(op.name, equals('idx_users_email'));
      });

      test('with ifExists', () {
        final builder = MigrationBuilder();
        builder.dropIndex('idx_users_email', ifExists: true);

        final op = builder.operations.first as DropIndex;
        expect(op.ifExists, isTrue);
      });
    });

    group('addForeignKey()', () {
      test('adds AddForeignKey operation', () {
        final builder = MigrationBuilder();
        builder.addForeignKey('posts', 'author_id', 'users');

        expect(builder.operations.first, isA<AddForeignKey>());
        final op = builder.operations.first as AddForeignKey;
        expect(op.table, equals('posts'));
        expect(op.foreignKey.column, equals('author_id'));
        expect(op.foreignKey.referencedTable, equals('users'));
      });

      test('with custom referenced column', () {
        final builder = MigrationBuilder();
        builder.addForeignKey('posts', 'author_id', 'users', referencedColumn: 'user_id');

        final op = builder.operations.first as AddForeignKey;
        expect(op.foreignKey.referencedColumn, equals('user_id'));
      });

      test('with onDelete action', () {
        final builder = MigrationBuilder();
        builder.addForeignKey('posts', 'author_id', 'users', onDelete: OnDeleteAction.setNull);

        final op = builder.operations.first as AddForeignKey;
        expect(op.foreignKey.onDelete, equals(OnDeleteAction.setNull));
      });

      test('with onUpdate action', () {
        final builder = MigrationBuilder();
        builder.addForeignKey('posts', 'author_id', 'users', onUpdate: OnUpdateAction.restrict);

        final op = builder.operations.first as AddForeignKey;
        expect(op.foreignKey.onUpdate, equals(OnUpdateAction.restrict));
      });
    });

    group('dropConstraint()', () {
      test('adds DropConstraint operation', () {
        final builder = MigrationBuilder();
        builder.dropConstraint('posts', 'fk_posts_author');

        expect(builder.operations.first, isA<DropConstraint>());
        final op = builder.operations.first as DropConstraint;
        expect(op.table, equals('posts'));
        expect(op.constraintName, equals('fk_posts_author'));
      });
    });

    group('rawSql()', () {
      test('adds RawSql operation', () {
        final builder = MigrationBuilder();
        builder.rawSql('CREATE EXTENSION IF NOT EXISTS "uuid-ossp"');

        expect(builder.operations.first, isA<RawSql>());
        final op = builder.operations.first as RawSql;
        expect(op.sql, contains('uuid-ossp'));
      });

      test('with reverseSql', () {
        final builder = MigrationBuilder();
        builder.rawSql(
          'CREATE VIEW active_users AS SELECT * FROM users WHERE active = true',
          reverseSql: 'DROP VIEW active_users',
        );

        final op = builder.operations.first as RawSql;
        expect(op.reverseSql, equals('DROP VIEW active_users'));
      });
    });

    group('runDart()', () {
      test('adds RunDart operation', () {
        final builder = MigrationBuilder();
        builder.runDart((conn) async {
          // Migration code
        });

        expect(builder.operations.first, isA<RunDart>());
      });

      test('with backward function', () {
        final builder = MigrationBuilder();
        builder.runDart((conn) async {}, backward: (conn) async {});

        final op = builder.operations.first as RunDart;
        expect(op.backward, isNotNull);
      });
    });

    group('operations list', () {
      test('is unmodifiable', () {
        final builder = MigrationBuilder();
        builder.dropTable('users');

        expect(() => builder.operations.add(DropTable('posts')), throwsUnsupportedError);
      });

      test('preserves order', () {
        final builder = MigrationBuilder();
        builder.createTable('users', (t) => t.id());
        builder.createTable('posts', (t) => t.id());
        builder.createIndex('users', ['name']);

        expect(builder.operations.length, equals(3));
        expect(builder.operations[0], isA<CreateTable>());
        expect(builder.operations[1], isA<CreateTable>());
        expect(builder.operations[2], isA<CreateIndex>());
      });
    });
  });

  group('Migration', () {
    test('has required name property', () {
      final migration = CreateUsersTable();
      expect(migration.name, equals('001_create_users'));
    });

    test('dependencies defaults to empty', () {
      final migration = CreateUsersTable();
      expect(migration.dependencies, isEmpty);
    });

    test('up() populates builder operations', () {
      final migration = CreateUsersTable();
      final builder = MigrationBuilder();
      migration.up(builder);

      expect(builder.operations, isNotEmpty);
      expect(builder.operations.first, isA<CreateTable>());
    });

    test('down() populates builder operations', () {
      final migration = CreateUsersTable();
      final builder = MigrationBuilder();
      migration.down(builder);

      expect(builder.operations, isNotEmpty);
      expect(builder.operations.first, isA<DropTable>());
    });
  });

  group('MigrationRunner', () {
    late SqliteAdapter adapter;
    late ConnectionPool pool;
    late MigrationRunner runner;

    setUp(() async {
      final config = DatabaseConfig.sqliteMemory();
      adapter = const SqliteAdapter();
      pool = await adapter.createPool(config);
      runner = MigrationRunner(adapter: adapter, pool: pool);
    });

    tearDown(() async {
      await pool.close();
    });

    group('getAppliedMigrations()', () {
      test('returns empty list initially', () async {
        final applied = await runner.getAppliedMigrations();
        expect(applied, isEmpty);
      });

      test('creates migrations table if not exists', () async {
        await runner.getAppliedMigrations();

        final exists = await pool.withConnection((conn) => adapter.tableExists(conn, 'jao_migrations'));
        expect(exists, isTrue);
      });

      test('returns applied migrations after migrate()', () async {
        await runner.migrate([CreateUsersTable()]);

        final applied = await runner.getAppliedMigrations();
        expect(applied, equals(['001_create_users']));
      });
    });

    group('isApplied()', () {
      test('returns false for unapplied migration', () async {
        final applied = await runner.isApplied('001_create_users');
        expect(applied, isFalse);
      });

      test('returns true after migration is applied', () async {
        await runner.migrate([CreateUsersTable()]);

        final applied = await runner.isApplied('001_create_users');
        expect(applied, isTrue);
      });
    });

    group('migrate()', () {
      test('runs pending migrations', () async {
        final result = await runner.migrate([CreateUsersTable()]);

        expect(result.isSuccess, isTrue);
        expect(result.applied, equals(['001_create_users']));
      });

      test('creates tables', () async {
        await runner.migrate([CreateUsersTable()]);

        final exists = await pool.withConnection((conn) => adapter.tableExists(conn, 'users'));
        expect(exists, isTrue);
      });

      test('runs multiple migrations in order', () async {
        final result = await runner.migrate([CreateUsersTable(), CreatePostsTable()]);

        expect(result.applied, equals(['001_create_users', '002_create_posts']));

        await pool.withConnection((conn) async {
          final usersExists = await adapter.tableExists(conn, 'users');
          final postsExists = await adapter.tableExists(conn, 'posts');
          expect(usersExists, isTrue);
          expect(postsExists, isTrue);
        });
      });

      test('skips already applied migrations', () async {
        await runner.migrate([CreateUsersTable()]);
        final result = await runner.migrate([CreateUsersTable(), CreatePostsTable()]);

        expect(result.applied, equals(['002_create_posts']));
        expect(result.skipped, equals(['001_create_users']));
      });

      test('returns empty applied when no pending', () async {
        await runner.migrate([CreateUsersTable()]);
        final result = await runner.migrate([CreateUsersTable()]);

        expect(result.applied, isEmpty);
        expect(result.skipped, equals(['001_create_users']));
      });

      test('stops on first error', () async {
        final result = await runner.migrate([CreateUsersTable(), FailingMigration(), CreatePostsTable()]);

        expect(result.isSuccess, isFalse);
        expect(result.applied, equals(['001_create_users']));
        expect(result.errors.length, equals(1));
        expect(result.errors.first.migrationName, equals('999_failing_migration'));
      });

      test('add column migration works', () async {
        await runner.migrate([CreateUsersTable()]);
        final result = await runner.migrate([CreateUsersTable(), AddStatusToUsers()]);

        expect(result.applied, equals(['003_add_status_to_users']));

        // Verify column exists
        final schema = await pool.withConnection((conn) => adapter.getTableSchema(conn, 'users'));
        expect(schema.columns.any((col) => col.name == 'status'), isTrue);
      });

      test('rename table migration works', () async {
        await runner.migrate([CreateUsersTable()]);

        // We need to skip foreign key dependent migrations for rename test
        final renameRunner = MigrationRunner(adapter: adapter, pool: pool);
        await renameRunner.migrate([RenameUsersToAccounts()]);

        await pool.withConnection((conn) async {
          final usersExists = await adapter.tableExists(conn, 'users');
          final accountsExists = await adapter.tableExists(conn, 'accounts');
          expect(usersExists, isFalse);
          expect(accountsExists, isTrue);
        });
      });
    });

    group('rollback()', () {
      test('rolls back last migration', () async {
        await runner.migrate([CreateUsersTable(), CreatePostsTable()]);
        final result = await runner.rollback([CreateUsersTable(), CreatePostsTable()]);

        expect(result.rolledBack, equals(['002_create_posts']));
      });

      test('drops table on rollback', () async {
        await runner.migrate([CreateUsersTable()]);
        await runner.rollback([CreateUsersTable()]);

        final exists = await pool.withConnection((conn) => adapter.tableExists(conn, 'users'));
        expect(exists, isFalse);
      });

      test('rolls back multiple with count', () async {
        await runner.migrate([CreateUsersTable(), CreatePostsTable()]);
        final result = await runner.rollback([CreateUsersTable(), CreatePostsTable()], count: 2);

        expect(result.rolledBack.length, equals(2));
        expect(result.rolledBack, contains('001_create_users'));
        expect(result.rolledBack, contains('002_create_posts'));
      });

      test('errors when migration not found in codebase', () async {
        await runner.migrate([CreateUsersTable()]);
        final result = await runner.rollback([]); // Empty list, migration not found

        expect(result.errors.length, equals(1));
        expect(result.errors.first.message, contains('not found'));
      });

      test('removes from migrations table', () async {
        await runner.migrate([CreateUsersTable()]);
        await runner.rollback([CreateUsersTable()]);

        final applied = await runner.getAppliedMigrations();
        expect(applied, isEmpty);
      });
    });

    group('reset()', () {
      test('rolls back all migrations', () async {
        await runner.migrate([CreateUsersTable(), CreatePostsTable()]);
        final result = await runner.reset([CreateUsersTable(), CreatePostsTable()]);

        expect(result.rolledBack.length, equals(2));

        final applied = await runner.getAppliedMigrations();
        expect(applied, isEmpty);
      });
    });

    group('refresh()', () {
      test('resets and re-runs all migrations', () async {
        await runner.migrate([CreateUsersTable()]);
        final result = await runner.refresh([CreateUsersTable(), CreatePostsTable()]);

        expect(result.applied, equals(['001_create_users', '002_create_posts']));

        final applied = await runner.getAppliedMigrations();
        expect(applied.length, equals(2));
      });
    });

    group('generateSql()', () {
      test('generates SQL for up migration', () {
        final migration = CreateUsersTable();
        final sql = runner.generateSql(migration, MigrationDirection.up);

        expect(sql, contains('CREATE TABLE'));
        expect(sql, contains('users'));
      });

      test('generates SQL for down migration', () {
        final migration = CreateUsersTable();
        final sql = runner.generateSql(migration, MigrationDirection.down);

        expect(sql, contains('DROP TABLE'));
        expect(sql, contains('users'));
      });
    });

    group('status()', () {
      test('shows pending status', () async {
        final statuses = await runner.status([CreateUsersTable()]);

        expect(statuses.length, equals(1));
        expect(statuses.first.name, equals('001_create_users'));
        expect(statuses.first.isApplied, isFalse);
      });

      test('shows applied status', () async {
        await runner.migrate([CreateUsersTable()]);
        final statuses = await runner.status([CreateUsersTable()]);

        expect(statuses.first.isApplied, isTrue);
      });

      test('shows missing migrations', () async {
        await runner.migrate([CreateUsersTable()]);
        final statuses = await runner.status([]); // Empty list

        expect(statuses.first.isMissing, isTrue);
      });

      test('shows multiple statuses', () async {
        await runner.migrate([CreateUsersTable()]);
        final statuses = await runner.status([CreateUsersTable(), CreatePostsTable()]);

        expect(statuses.length, equals(2));
        expect(statuses[0].isApplied, isTrue);
        expect(statuses[1].isApplied, isFalse);
      });
    });

    group('custom migrations table', () {
      test('uses custom table name', () async {
        final customRunner = MigrationRunner(adapter: adapter, pool: pool, migrationsTable: 'custom_migrations');

        await customRunner.migrate([CreateUsersTable()]);

        final exists = await pool.withConnection((conn) => adapter.tableExists(conn, 'custom_migrations'));
        expect(exists, isTrue);
      });
    });

    group('autoReverse', () {
      test('creates table with autoReverse migration', () async {
        final result = await runner.migrate([AutoReverseCreateCategories()]);

        expect(result.isSuccess, isTrue);
        expect(result.applied, equals(['010_auto_create_categories']));

        final exists = await pool.withConnection((conn) => adapter.tableExists(conn, 'categories'));
        expect(exists, isTrue);
      });

      test('auto-generates DROP TABLE on rollback', () async {
        await runner.migrate([AutoReverseCreateCategories()]);
        await runner.rollback([AutoReverseCreateCategories()]);

        final exists = await pool.withConnection((conn) => adapter.tableExists(conn, 'categories'));
        expect(exists, isFalse);
      });

      test('auto-generates DROP INDEX on rollback', () async {
        await runner.migrate([AutoReverseCreateCategories(), AutoReverseAddIndex()]);

        // Verify index exists (via table schema)
        final schemaBefore = await pool.withConnection((conn) => adapter.getTableSchema(conn, 'categories'));
        expect(schemaBefore.indexes.isNotEmpty, isTrue);

        await runner.rollback([AutoReverseCreateCategories(), AutoReverseAddIndex()]);

        // Table should still exist, index should be gone
        final exists = await pool.withConnection((conn) => adapter.tableExists(conn, 'categories'));
        expect(exists, isTrue);
      });

      test('reverses multiple operations in correct order', () async {
        await runner.migrate([AutoReverseMultipleOps()]);

        final exists = await pool.withConnection((conn) => adapter.tableExists(conn, 'tags'));
        expect(exists, isTrue);

        // Rollback should: DROP INDEX first, then DROP TABLE
        await runner.rollback([AutoReverseMultipleOps()]);

        final existsAfter = await pool.withConnection((conn) => adapter.tableExists(conn, 'tags'));
        expect(existsAfter, isFalse);
      });

      test('generateSql with autoReverse shows reverse SQL', () {
        final migration = AutoReverseCreateCategories();
        final sql = runner.generateSql(migration, MigrationDirection.down);

        expect(sql, contains('DROP TABLE'));
        expect(sql, contains('categories'));
      });

      test('generateSql reverses multiple operations', () {
        final migration = AutoReverseMultipleOps();
        final sql = runner.generateSql(migration, MigrationDirection.down);

        // Should have DROP INDEX before DROP TABLE (reversed order)
        final dropIndexPos = sql.indexOf('DROP INDEX');
        final dropTablePos = sql.indexOf('DROP TABLE');

        expect(dropIndexPos, lessThan(dropTablePos));
      });

      test('autoReverse defaults to false', () {
        final migration = CreateUsersTable();
        expect(migration.autoReverse, isFalse);
      });

      test('explicit down() is used when autoReverse is false', () {
        final migration = CreateUsersTable();
        final sql = runner.generateSql(migration, MigrationDirection.down);

        // Should use explicit down() which has dropTable
        expect(sql, contains('DROP TABLE'));
      });
    });

    group('SQLite table recreation (AlterColumn)', () {
      test('AlterColumn changes nullability via table recreation', () async {
        // First create the items table
        await runner.migrate([CreateItemsTable()]);

        // Verify description is NOT NULL initially
        var schema = await pool.withConnection((conn) => adapter.getTableSchema(conn, 'items'));
        var descCol = schema.columns.firstWhere((c) => c.name == 'description');
        expect(descCol.nullable, isFalse);

        // Apply the AlterColumn migration (should use table recreation)
        final result = await runner.migrate([CreateItemsTable(), MakeDescriptionNullable()]);

        expect(result.isSuccess, isTrue);
        expect(result.applied, equals(['021_make_description_nullable']));

        // Verify description is now nullable
        schema = await pool.withConnection((conn) => adapter.getTableSchema(conn, 'items'));
        descCol = schema.columns.firstWhere((c) => c.name == 'description');
        expect(descCol.nullable, isTrue);
      });

      test('AlterColumn preserves data during table recreation', () async {
        // Create the items table
        await runner.migrate([CreateItemsTable()]);

        // Insert some test data
        await pool.withConnection((conn) async {
          await conn.execute("INSERT INTO items (name, description) VALUES ('Item 1', 'Description 1')");
          await conn.execute("INSERT INTO items (name, description) VALUES ('Item 2', 'Description 2')");
        });

        // Apply the AlterColumn migration
        await runner.migrate([CreateItemsTable(), MakeDescriptionNullable()]);

        // Verify data is preserved
        final rows = await pool.withConnection((conn) => conn.query('SELECT * FROM items ORDER BY id'));

        expect(rows.length, equals(2));
        expect(rows[0]['name'], equals('Item 1'));
        expect(rows[0]['description'], equals('Description 1'));
        expect(rows[1]['name'], equals('Item 2'));
        expect(rows[1]['description'], equals('Description 2'));
      });

      test('AlterColumn rollback restores original nullability', () async {
        // Create the items table and apply nullable migration
        await runner.migrate([CreateItemsTable(), MakeDescriptionNullable()]);

        // Verify description is nullable
        var schema = await pool.withConnection((conn) => adapter.getTableSchema(conn, 'items'));
        var descCol = schema.columns.firstWhere((c) => c.name == 'description');
        expect(descCol.nullable, isTrue);

        // Rollback the nullable migration
        await runner.rollback([CreateItemsTable(), MakeDescriptionNullable()]);

        // Verify description is NOT NULL again
        schema = await pool.withConnection((conn) => adapter.getTableSchema(conn, 'items'));
        descCol = schema.columns.firstWhere((c) => c.name == 'description');
        expect(descCol.nullable, isFalse);
      });
    });

    group('SQLite table recreation (AddForeignKey)', () {
      test('AddForeignKey adds FK via table recreation', () async {
        await runner.migrate([CreateAuthorsTable(), CreateBooksTable(), AddBookAuthorFk()]);

        final tableSql = await pool.withConnection((conn) async {
          final result = await conn.query("SELECT sql FROM sqlite_master WHERE type='table' AND name='books'");
          return result.first['sql'] as String;
        });

        expect(tableSql, contains('FOREIGN KEY'));
        expect(tableSql, contains('"authors"'));
      });

      test('AddForeignKey preserves data during table recreation', () async {
        await runner.migrate([CreateAuthorsTable(), CreateBooksTable()]);

        await pool.withConnection((conn) async {
          await conn.execute("INSERT INTO authors (name) VALUES ('Author 1')");
          await conn.execute("INSERT INTO books (title, author_id) VALUES ('Book 1', 1)");
          await conn.execute("INSERT INTO books (title, author_id) VALUES ('Book 2', 1)");
        });

        await runner.migrate([CreateAuthorsTable(), CreateBooksTable(), AddBookAuthorFk()]);

        final rows = await pool.withConnection((conn) => conn.query('SELECT * FROM books ORDER BY id'));
        expect(rows.length, equals(2));
        expect(rows[0]['title'], equals('Book 1'));
        expect(rows[1]['title'], equals('Book 2'));
      });
    });

    group('SQLite table recreation (DropConstraint)', () {
      test('DropConstraint removes FK via table recreation', () async {
        await runner.migrate([CreateAuthorsTable(), CreateBooksWithFkTable()]);

        var tableSql = await pool.withConnection((conn) async {
          final result = await conn.query("SELECT sql FROM sqlite_master WHERE type='table' AND name='books_with_fk'");
          return result.first['sql'] as String;
        });
        expect(tableSql, contains('FOREIGN KEY'), reason: 'FK should exist before drop');

        await runner.migrate([CreateAuthorsTable(), CreateBooksWithFkTable(), DropBookAuthorFk()]);

        tableSql = await pool.withConnection((conn) async {
          final result = await conn.query("SELECT sql FROM sqlite_master WHERE type='table' AND name='books_with_fk'");
          return result.first['sql'] as String;
        });
        expect(tableSql, isNot(contains('FOREIGN KEY')), reason: 'FK should be removed after migration');
      });

      test('DropConstraint preserves data during table recreation', () async {
        await runner.migrate([CreateAuthorsTable(), CreateBooksWithFkTable()]);

        await pool.withConnection((conn) async {
          await conn.execute("INSERT INTO authors (name) VALUES ('Author 1')");
          await conn.execute("INSERT INTO books_with_fk (title, author_id) VALUES ('Book 1', 1)");
        });

        await runner.migrate([CreateAuthorsTable(), CreateBooksWithFkTable(), DropBookAuthorFk()]);

        final rows = await pool.withConnection((conn) => conn.query('SELECT * FROM books_with_fk ORDER BY id'));
        expect(rows.length, equals(1));
        expect(rows[0]['title'], equals('Book 1'));
      });
    });
  });

  group('MigrationResult', () {
    test('isSuccess is true with no errors', () {
      const result = MigrationResult(applied: ['001_create_users']);
      expect(result.isSuccess, isTrue);
    });

    test('isSuccess is false with errors', () {
      final result = MigrationResult(errors: [MigrationError('test', 'error message', null)]);
      expect(result.isSuccess, isFalse);
    });

    test('hasChanges is true with applied', () {
      const result = MigrationResult(applied: ['001_create_users']);
      expect(result.hasChanges, isTrue);
    });

    test('hasChanges is true with rolledBack', () {
      const result = MigrationResult(rolledBack: ['001_create_users']);
      expect(result.hasChanges, isTrue);
    });

    test('hasChanges is false with only skipped', () {
      const result = MigrationResult(skipped: ['001_create_users']);
      expect(result.hasChanges, isFalse);
    });
  });

  group('MigrationError', () {
    test('stores properties', () {
      final stack = StackTrace.current;
      final error = MigrationError('test_migration', 'Something failed', stack);

      expect(error.migrationName, equals('test_migration'));
      expect(error.message, equals('Something failed'));
      expect(error.stackTrace, equals(stack));
    });

    test('toString includes name and message', () {
      final error = MigrationError('test_migration', 'Something failed', null);
      expect(error.toString(), contains('test_migration'));
      expect(error.toString(), contains('Something failed'));
    });
  });

  group('MigrationStatus', () {
    test('stores properties', () {
      const status = MigrationStatus(name: 'test', isApplied: true);
      expect(status.name, equals('test'));
      expect(status.isApplied, isTrue);
    });

    test('isMissing defaults to false', () {
      const status = MigrationStatus(name: 'test', isApplied: false);
      expect(status.isMissing, isFalse);
    });

    test('isMissing can be true', () {
      const status = MigrationStatus(name: 'test', isApplied: true, isMissing: true);
      expect(status.isMissing, isTrue);
    });
  });

  group('MigrationDirection', () {
    test('has up and down values', () {
      expect(MigrationDirection.values, contains(MigrationDirection.up));
      expect(MigrationDirection.values, contains(MigrationDirection.down));
    });
  });

  group('RunDart operations', () {
    late SqliteAdapter adapter;
    late ConnectionPool pool;
    late MigrationRunner runner;

    setUp(() async {
      final config = DatabaseConfig.sqliteMemory();
      adapter = const SqliteAdapter();
      pool = await adapter.createPool(config);
      runner = MigrationRunner(adapter: adapter, pool: pool);
    });

    tearDown(() async {
      await pool.close();
    });

    test('RunDart forward executes during up migration', () async {
      var forwardCalled = false;

      final migration = _RunDartMigration(
        migrationName: 'run_dart_forward',
        forward: (conn) async {
          forwardCalled = true;
          await conn.execute('CREATE TABLE dart_test (id INTEGER PRIMARY KEY)');
        },
      );

      await runner.migrate([migration]);

      expect(forwardCalled, isTrue);
      final exists = await pool.withConnection((conn) => adapter.tableExists(conn, 'dart_test'));
      expect(exists, isTrue);
    });

    test('RunDart backward executes during rollback', () async {
      var backwardCalled = false;

      final migration = _RunDartMigration(
        migrationName: 'run_dart_backward',
        forward: (conn) async {
          await conn.execute('CREATE TABLE dart_backward_test (id INTEGER PRIMARY KEY)');
        },
        backward: (conn) async {
          backwardCalled = true;
          await conn.execute('DROP TABLE dart_backward_test');
        },
      );

      // First apply the migration
      await runner.migrate([migration]);

      // Then rollback
      await runner.rollback([migration]);

      expect(backwardCalled, isTrue);
      final exists = await pool.withConnection((conn) => adapter.tableExists(conn, 'dart_backward_test'));
      expect(exists, isFalse);
    });

    test('RunDart without backward skips during rollback', () async {
      final migration = _RunDartMigration(
        migrationName: 'run_dart_no_backward',
        forward: (conn) async {
          await conn.execute('CREATE TABLE no_backward_test (id INTEGER PRIMARY KEY)');
        },
        // No backward function
      );

      // Apply the migration
      await runner.migrate([migration]);

      // Rollback should not throw even without backward
      final result = await runner.rollback([migration]);
      expect(result.rolledBack, contains('run_dart_no_backward'));
    });

    test('RunDart backward executes during autoReverse rollback', () async {
      var backwardCalled = false;

      final migration = _AutoReverseMigration(
        migrationName: 'auto_reverse_run_dart',
        forward: (conn) async {
          await conn.execute('CREATE TABLE auto_reverse_test (id INTEGER PRIMARY KEY)');
        },
        backward: (conn) async {
          backwardCalled = true;
          await conn.execute('DROP TABLE IF EXISTS auto_reverse_test');
        },
      );

      // Apply the migration
      await runner.migrate([migration]);

      // Verify forward ran
      final existsBefore = await pool.withConnection((conn) => adapter.tableExists(conn, 'auto_reverse_test'));
      expect(existsBefore, isTrue);

      // Rollback using autoReverse (which calls operation.backward)
      await runner.rollback([migration]);

      expect(backwardCalled, isTrue);
    });
  });

  group('Rollback error handling', () {
    late SqliteAdapter adapter;
    late ConnectionPool pool;
    late MigrationRunner runner;

    setUp(() async {
      final config = DatabaseConfig.sqliteMemory();
      adapter = const SqliteAdapter();
      pool = await adapter.createPool(config);
      runner = MigrationRunner(adapter: adapter, pool: pool);
    });

    tearDown(() async {
      await pool.close();
    });

    test('rollback catches and reports errors', () async {
      final migration = _FailingRollbackMigration();

      // First apply the migration
      await runner.migrate([migration]);

      // Rollback should fail but not throw
      final result = await runner.rollback([migration]);

      expect(result.errors, isNotEmpty);
      expect(result.errors.first.migrationName, equals('failing_rollback'));
      expect(result.errors.first.message, contains('Rollback intentionally failed'));
    });
  });
}

// Helper migration class for RunDart tests
class _RunDartMigration extends Migration {
  final String migrationName;
  final Future<void> Function(DatabaseConnection conn) forward;
  final Future<void> Function(DatabaseConnection conn)? backward;

  _RunDartMigration({
    required this.migrationName,
    required this.forward,
    this.backward,
  });

  @override
  String get name => migrationName;

  @override
  void up(MigrationBuilder builder) {
    builder.runDart(forward, backward: backward);
  }

  @override
  void down(MigrationBuilder builder) {
    if (backward != null) {
      builder.runDart(backward!, backward: forward);
    }
  }
}

// Helper migration class that fails during rollback
class _FailingRollbackMigration extends Migration {
  @override
  String get name => 'failing_rollback';

  @override
  void up(MigrationBuilder builder) {
    builder.createTable('failing_rollback_test', (table) {
      table.id();
    });
  }

  @override
  void down(MigrationBuilder builder) {
    builder.rawSql('INVALID SQL THAT WILL FAIL -- Rollback intentionally failed');
  }
}

class _AutoReverseMigration extends Migration {
  final String migrationName;
  final Future<void> Function(DatabaseConnection conn) forward;
  final Future<void> Function(DatabaseConnection conn)? backward;

  _AutoReverseMigration({
    required this.migrationName,
    required this.forward,
    this.backward,
  });

  @override
  String get name => migrationName;

  @override
  bool get autoReverse => true;

  @override
  void up(MigrationBuilder builder) {
    builder.runDart(forward, backward: backward);
  }

  @override
  void down(MigrationBuilder builder) {
    // Not used when autoReverse is true
  }
}
