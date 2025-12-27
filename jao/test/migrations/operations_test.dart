import 'package:jao/jao.dart';
import 'package:test/test.dart';

void main() {
  const sqlite = SqliteDialect();
  const postgres = PostgresDialect();

  group('CreateTable', () {
    test('toSql generates CREATE TABLE', () {
      final table = TableBuilder('users').id().string('name').build();
      final op = CreateTable(table);
      final sql = op.toSql(sqlite);

      expect(sql, contains('CREATE TABLE'));
      expect(sql, contains('"users"'));
    });

    test('toSql with all column types', () {
      final table = TableBuilder(
        'test',
      ).id().string('name').text('bio').integer('age').boolean('active').timestamp('created_at').build();
      final op = CreateTable(table);
      final sql = op.toSql(sqlite);

      expect(sql, contains('"name"'));
      expect(sql, contains('"bio"'));
      expect(sql, contains('"age"'));
      expect(sql, contains('"active"'));
      expect(sql, contains('"created_at"'));
    });

    test('toSql with PRIMARY KEY', () {
      final table = TableBuilder('users').id().string('name').build();
      final op = CreateTable(table);
      final sql = op.toSql(sqlite);

      // SERIAL types in SQLite include PRIMARY KEY AUTOINCREMENT
      expect(sql, contains('PRIMARY KEY'));
    });

    test('toSql with NOT NULL', () {
      final table = TableBuilder('users').id().string('name').build();
      final op = CreateTable(table);
      final sql = op.toSql(sqlite);

      expect(sql, contains('NOT NULL'));
    });

    test('toSql with DEFAULT value', () {
      final table = TableBuilder('users').id().string('status', defaultValue: "'active'").build();
      final op = CreateTable(table);
      final sql = op.toSql(sqlite);

      expect(sql, contains("DEFAULT 'active'"));
    });

    test('toSql with FOREIGN KEY', () {
      final table = TableBuilder('posts').id().string('title').foreignKey('author_id', 'users').build();
      final op = CreateTable(table);
      final sql = op.toSql(postgres);

      expect(sql, contains('FOREIGN KEY'));
      expect(sql, contains('REFERENCES'));
      expect(sql, contains('"users"'));
    });

    test('toSql with IF NOT EXISTS', () {
      final table = TableBuilder('users').ifNotExists().id().string('name').build();
      final op = CreateTable(table);
      final sql = op.toSql(sqlite);

      expect(sql, contains('IF NOT EXISTS'));
    });

    test('toReverseSql generates DROP TABLE', () {
      final table = TableBuilder('users').id().string('name').build();
      final op = CreateTable(table);
      final reverse = op.toReverseSql(sqlite);

      expect(reverse, contains('DROP TABLE'));
      expect(reverse, contains('"users"'));
    });

    test('isReversible is true', () {
      final table = TableBuilder('users').id().build();
      final op = CreateTable(table);
      expect(op.isReversible, isTrue);
    });
  });

  group('DropTable', () {
    test('toSql generates DROP TABLE', () {
      const op = DropTable('users');
      final sql = op.toSql(sqlite);

      expect(sql, equals('DROP TABLE "users"'));
    });

    test('toSql with IF EXISTS', () {
      const op = DropTable('users', ifExists: true);
      final sql = op.toSql(sqlite);

      expect(sql, contains('IF EXISTS'));
    });

    test('toSql with CASCADE', () {
      const op = DropTable('users', cascade: true);
      final sql = op.toSql(postgres);

      expect(sql, contains('CASCADE'));
    });

    test('toReverseSql returns null', () {
      const op = DropTable('users');
      expect(op.toReverseSql(sqlite), isNull);
    });

    test('isReversible is false', () {
      const op = DropTable('users');
      expect(op.isReversible, isFalse);
    });
  });

  group('RenameTable', () {
    test('toSql generates RENAME TABLE', () {
      const op = RenameTable('old_users', 'users');
      final sql = op.toSql(sqlite);

      expect(sql, contains('ALTER TABLE'));
      expect(sql, contains('"old_users"'));
      expect(sql, contains('RENAME TO'));
      expect(sql, contains('"users"'));
    });

    test('toReverseSql reverses the rename', () {
      const op = RenameTable('old_users', 'users');
      final reverse = op.toReverseSql(sqlite);

      expect(reverse, contains('"users"'));
      expect(reverse, contains('RENAME TO'));
      expect(reverse, contains('"old_users"'));
    });

    test('isReversible is true', () {
      const op = RenameTable('old_users', 'users');
      expect(op.isReversible, isTrue);
    });
  });

  group('AddColumn', () {
    test('toSql generates ALTER TABLE ADD COLUMN', () {
      const col = ColumnDefinition(name: 'email', type: FieldType.varchar, nullable: true);
      const op = AddColumn('users', col);
      final sql = op.toSql(sqlite);

      expect(sql, contains('ALTER TABLE'));
      expect(sql, contains('ADD COLUMN'));
      expect(sql, contains('"email"'));
    });

    test('toSql with nullable column', () {
      const col = ColumnDefinition(name: 'bio', type: FieldType.text, nullable: true);
      const op = AddColumn('users', col);
      final sql = op.toSql(sqlite);

      expect(sql, isNot(contains('NOT NULL')));
    });

    test('toSql with NOT NULL and default', () {
      const col = ColumnDefinition(name: 'status', type: FieldType.varchar, nullable: false, defaultValue: "'active'");
      const op = AddColumn('users', col);
      final sql = op.toSql(sqlite);

      expect(sql, contains('NOT NULL'));
      expect(sql, contains('DEFAULT'));
    });

    test('toReverseSql generates DROP COLUMN', () {
      const col = ColumnDefinition(name: 'email', type: FieldType.varchar);
      const op = AddColumn('users', col);
      final reverse = op.toReverseSql(sqlite);

      expect(reverse, contains('DROP COLUMN'));
      expect(reverse, contains('"email"'));
    });

    test('isReversible is true', () {
      const col = ColumnDefinition(name: 'email', type: FieldType.varchar);
      const op = AddColumn('users', col);
      expect(op.isReversible, isTrue);
    });
  });

  group('DropColumn', () {
    test('toSql generates ALTER TABLE DROP COLUMN', () {
      const op = DropColumn('users', 'email');
      final sql = op.toSql(sqlite);

      expect(sql, contains('ALTER TABLE'));
      expect(sql, contains('DROP COLUMN'));
      expect(sql, contains('"email"'));
    });

    test('toSql with CASCADE', () {
      const op = DropColumn('users', 'email', cascade: true);
      final sql = op.toSql(postgres);

      expect(sql, contains('CASCADE'));
    });

    test('toReverseSql returns null', () {
      const op = DropColumn('users', 'email');
      expect(op.toReverseSql(sqlite), isNull);
    });

    test('isReversible is false', () {
      const op = DropColumn('users', 'email');
      expect(op.isReversible, isFalse);
    });
  });

  group('RenameColumn', () {
    test('toSql generates RENAME COLUMN', () {
      const op = RenameColumn('users', 'email', 'email_address');
      final sql = op.toSql(sqlite);

      expect(sql, contains('ALTER TABLE'));
      expect(sql, contains('RENAME COLUMN'));
      expect(sql, contains('"email"'));
      expect(sql, contains('"email_address"'));
    });

    test('toReverseSql reverses the rename', () {
      const op = RenameColumn('users', 'email', 'email_address');
      final reverse = op.toReverseSql(sqlite);

      expect(reverse, contains('"email_address"'));
      expect(reverse, contains('"email"'));
    });

    test('isReversible is true', () {
      const op = RenameColumn('users', 'email', 'email_address');
      expect(op.isReversible, isTrue);
    });
  });

  group('AlterColumn', () {
    test('toSql changes column type', () {
      const mod = ColumnModification(table: 'users', column: 'age', type: FieldType.bigInt);
      const op = AlterColumn(mod);
      final sql = op.toSql(postgres);

      expect(sql, contains('ALTER COLUMN'));
      expect(sql, contains('TYPE'));
      expect(sql, contains('BIGINT'));
    });

    test('toSql changes nullable', () {
      const mod = ColumnModification(table: 'users', column: 'bio', nullable: true);
      const op = AlterColumn(mod);
      final sql = op.toSql(postgres);

      expect(sql, contains('DROP NOT NULL'));
    });

    test('toSql changes default', () {
      const mod = ColumnModification(table: 'users', column: 'status', defaultValue: "'inactive'");
      const op = AlterColumn(mod);
      final sql = op.toSql(postgres);

      expect(sql, contains('SET DEFAULT'));
    });

    test('toSql drops default', () {
      const mod = ColumnModification(table: 'users', column: 'status', dropDefault: true);
      const op = AlterColumn(mod);
      final sql = op.toSql(postgres);

      expect(sql, contains('DROP DEFAULT'));
    });

    test('isReversible is false', () {
      const mod = ColumnModification(table: 'users', column: 'age');
      const op = AlterColumn(mod);
      expect(op.isReversible, isFalse);
    });
  });

  group('CreateIndex', () {
    test('toSql generates CREATE INDEX', () {
      const idx = IndexDefinition(name: 'idx_users_email', columns: ['email']);
      const op = CreateIndex('users', idx);
      final sql = op.toSql(sqlite);

      expect(sql, contains('CREATE INDEX'));
      expect(sql, contains('"idx_users_email"'));
      expect(sql, contains('ON "users"'));
      expect(sql, contains('"email"'));
    });

    test('toSql with UNIQUE', () {
      const idx = IndexDefinition(name: 'idx_users_email', columns: ['email'], unique: true);
      const op = CreateIndex('users', idx);
      final sql = op.toSql(sqlite);

      expect(sql, contains('CREATE UNIQUE INDEX'));
    });

    test('toSql with multiple columns', () {
      const idx = IndexDefinition(name: 'idx_users_name_email', columns: ['name', 'email']);
      const op = CreateIndex('users', idx);
      final sql = op.toSql(sqlite);

      expect(sql, contains('"name"'));
      expect(sql, contains('"email"'));
    });

    test('toSql with CONCURRENTLY', () {
      const idx = IndexDefinition(name: 'idx_users_email', columns: ['email']);
      const op = CreateIndex('users', idx, concurrently: true);
      final sql = op.toSql(postgres);

      expect(sql, contains('CONCURRENTLY'));
    });

    test('toReverseSql generates DROP INDEX', () {
      const idx = IndexDefinition(name: 'idx_users_email', columns: ['email']);
      const op = CreateIndex('users', idx);
      final reverse = op.toReverseSql(sqlite);

      expect(reverse, contains('DROP INDEX'));
      expect(reverse, contains('"idx_users_email"'));
    });

    test('isReversible is true', () {
      const idx = IndexDefinition(name: 'idx_users_email', columns: ['email']);
      const op = CreateIndex('users', idx);
      expect(op.isReversible, isTrue);
    });
  });

  group('DropIndex', () {
    test('toSql generates DROP INDEX', () {
      const op = DropIndex('idx_users_email');
      final sql = op.toSql(sqlite);

      expect(sql, contains('DROP INDEX'));
      expect(sql, contains('"idx_users_email"'));
    });

    test('toSql with IF EXISTS', () {
      const op = DropIndex('idx_users_email', ifExists: true);
      final sql = op.toSql(sqlite);

      expect(sql, contains('IF EXISTS'));
    });

    test('toSql with CONCURRENTLY', () {
      const op = DropIndex('idx_users_email', concurrently: true);
      final sql = op.toSql(postgres);

      expect(sql, contains('CONCURRENTLY'));
    });

    test('toReverseSql returns null', () {
      const op = DropIndex('idx_users_email');
      expect(op.toReverseSql(sqlite), isNull);
    });

    test('isReversible is false', () {
      const op = DropIndex('idx_users_email');
      expect(op.isReversible, isFalse);
    });
  });

  group('AddForeignKey', () {
    test('toSql generates ADD CONSTRAINT FOREIGN KEY', () {
      const fk = ForeignKeyDefinition(column: 'author_id', referencedTable: 'users', referencedColumn: 'id');
      const op = AddForeignKey('posts', fk);
      final sql = op.toSql(postgres);

      expect(sql, contains('ALTER TABLE'));
      expect(sql, contains('ADD CONSTRAINT'));
      expect(sql, contains('FOREIGN KEY'));
      expect(sql, contains('"author_id"'));
      expect(sql, contains('REFERENCES'));
      expect(sql, contains('"users"'));
    });

    test('toSql uses custom constraint name', () {
      const fk = ForeignKeyDefinition(column: 'author_id', referencedTable: 'users', referencedColumn: 'id');
      const op = AddForeignKey('posts', fk, constraintName: 'custom_fk_name');
      final sql = op.toSql(postgres);

      expect(sql, contains('"custom_fk_name"'));
    });

    test('toReverseSql generates DROP CONSTRAINT', () {
      const fk = ForeignKeyDefinition(column: 'author_id', referencedTable: 'users', referencedColumn: 'id');
      const op = AddForeignKey('posts', fk);
      final reverse = op.toReverseSql(postgres);

      expect(reverse, contains('DROP CONSTRAINT'));
    });

    test('isReversible is true', () {
      const fk = ForeignKeyDefinition(column: 'author_id', referencedTable: 'users', referencedColumn: 'id');
      const op = AddForeignKey('posts', fk);
      expect(op.isReversible, isTrue);
    });
  });

  group('DropConstraint', () {
    test('toSql generates DROP CONSTRAINT', () {
      const op = DropConstraint('posts', 'fk_posts_author');
      final sql = op.toSql(postgres);

      expect(sql, contains('ALTER TABLE'));
      expect(sql, contains('DROP CONSTRAINT'));
      expect(sql, contains('"fk_posts_author"'));
    });

    test('toSql with CASCADE', () {
      const op = DropConstraint('posts', 'fk_posts_author', cascade: true);
      final sql = op.toSql(postgres);

      expect(sql, contains('CASCADE'));
    });

    test('toReverseSql returns null', () {
      const op = DropConstraint('posts', 'fk_posts_author');
      expect(op.toReverseSql(postgres), isNull);
    });

    test('isReversible is false', () {
      const op = DropConstraint('posts', 'fk_posts_author');
      expect(op.isReversible, isFalse);
    });
  });

  group('RawSql', () {
    test('toSql returns the raw SQL', () {
      const op = RawSql('CREATE EXTENSION IF NOT EXISTS "uuid-ossp"');
      final sql = op.toSql(postgres);

      expect(sql, equals('CREATE EXTENSION IF NOT EXISTS "uuid-ossp"'));
    });

    test('toReverseSql returns the reverse SQL', () {
      const op = RawSql(
        'CREATE EXTENSION IF NOT EXISTS "uuid-ossp"',
        reverseSql: 'DROP EXTENSION IF EXISTS "uuid-ossp"',
      );
      final reverse = op.toReverseSql(postgres);

      expect(reverse, equals('DROP EXTENSION IF EXISTS "uuid-ossp"'));
    });

    test('toReverseSql returns null if not provided', () {
      const op = RawSql('SELECT 1');
      expect(op.toReverseSql(postgres), isNull);
    });

    test('isReversible depends on reverseSql', () {
      const opWithReverse = RawSql('CREATE TABLE x', reverseSql: 'DROP TABLE x');
      const opWithoutReverse = RawSql('CREATE TABLE x');

      expect(opWithReverse.isReversible, isTrue);
      expect(opWithoutReverse.isReversible, isFalse);
    });
  });

  group('RunDart', () {
    test('toSql returns comment', () {
      final op = RunDart((conn) async {});
      final sql = op.toSql(postgres);

      expect(sql, contains('Dart code migration'));
    });

    test('toReverseSql returns comment when backward provided', () {
      final op = RunDart((conn) async {}, backward: (conn) async {});
      final reverse = op.toReverseSql(postgres);

      expect(reverse, contains('Dart code migration'));
      expect(reverse, contains('reverse'));
    });

    test('toReverseSql returns null when no backward', () {
      final op = RunDart((conn) async {});
      expect(op.toReverseSql(postgres), isNull);
    });

    test('isReversible depends on backward', () {
      final opWithBackward = RunDart((conn) async {}, backward: (conn) async {});
      final opWithoutBackward = RunDart((conn) async {});

      expect(opWithBackward.isReversible, isTrue);
      expect(opWithoutBackward.isReversible, isFalse);
    });
  });

  group('Cross-dialect', () {
    test('CreateTable works with PostgreSQL', () {
      final table = TableBuilder('users').id().string('name').build();
      final op = CreateTable(table);
      final sql = op.toSql(postgres);

      expect(sql, contains('CREATE TABLE'));
      expect(sql, contains('"users"'));
    });

    test('DropTable uses correct quoting per dialect', () {
      const op = DropTable('users');

      expect(op.toSql(postgres), contains('"users"'));
      expect(op.toSql(sqlite), contains('"users"'));
      expect(op.toSql(const MySqlDialect()), contains('`users`'));
    });

    test('Foreign key ON DELETE actions generate correctly', () {
      final table = TableBuilder(
        'posts',
      ).id().foreignKey('author_id', 'users', onDelete: OnDeleteAction.cascade).build();
      final op = CreateTable(table);
      final sql = op.toSql(postgres);

      expect(sql, contains('ON DELETE CASCADE'));
    });

    test('Foreign key ON UPDATE actions generate correctly', () {
      final table = TableBuilder(
        'posts',
      ).id().foreignKey('author_id', 'users', onUpdate: OnUpdateAction.setNull).build();
      final op = CreateTable(table);
      final sql = op.toSql(postgres);

      expect(sql, contains('ON UPDATE SET NULL'));
    });
  });
}
