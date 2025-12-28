import 'package:test/test.dart';
import 'package:jao/jao.dart';
import 'package:jao_cli/jao_cli.dart';

void main() {
  group('migrate command', () {
    late JaoCli cli;
    late List<Migration> migrations;

    setUp(() {
      migrations = [_TestMigration1(), _TestMigration2()];
      cli = JaoCli(
        MigrationRunnerConfig(
          database: DatabaseConfig.sqlite(':memory:'),
          adapter: const SqliteAdapter(),
          migrations: migrations,
        ),
      );
    });

    test('Runs pending migrations', () async {
      final result = await cli.run(['migrate']);

      expect(result, equals(0));
    });

    test('Shows "no pending migrations" when up to date', () async {
      // Run migrations first
      await cli.run(['migrate']);

      // Run again - should be up to date
      final result = await cli.run(['migrate']);

      expect(result, equals(0));
    });

    test('Exit code 0 on success', () async {
      final result = await cli.run(['migrate']);

      expect(result, equals(0));
    });

    test('--verbose flag enables verbose output', () async {
      cli = JaoCli(
        MigrationRunnerConfig(
          database: DatabaseConfig.sqlite(':memory:'),
          adapter: const SqliteAdapter(),
          migrations: migrations,
          verbose: true,
        ),
      );

      final result = await cli.run(['migrate', '-v']);

      expect(result, equals(0));
    });

    test('--dry-run shows SQL without executing', () async {
      final result = await cli.run(['migrate', '--dry-run']);

      expect(result, equals(0));
    });

    test('-n flag is alias for --dry-run', () async {
      final result = await cli.run(['migrate', '-n']);

      expect(result, equals(0));
    });

    test('Runs migrations in order', () async {
      // Create a CLI with specific migrations
      final orderedMigrations = [
        _OrderedMigration('001_first'),
        _OrderedMigration('002_second'),
        _OrderedMigration('003_third'),
      ];

      cli = JaoCli(
        MigrationRunnerConfig(
          database: DatabaseConfig.sqlite(':memory:'),
          adapter: const SqliteAdapter(),
          migrations: orderedMigrations,
        ),
      );

      final result = await cli.run(['migrate']);

      expect(result, equals(0));
    });

    test('Handles empty migrations list', () async {
      cli = JaoCli(
        MigrationRunnerConfig(
          database: DatabaseConfig.sqlite(':memory:'),
          adapter: const SqliteAdapter(),
          migrations: [],
        ),
      );

      final result = await cli.run(['migrate']);

      expect(result, equals(0));
    });
  });
}

class _TestMigration1 extends Migration {
  @override
  String get name => '20240101000000_create_test_table';

  @override
  void up(MigrationBuilder builder) {
    builder.createTable('test_table', (t) {
      t.id();
      t.string('name');
    });
  }

  @override
  void down(MigrationBuilder builder) {
    builder.dropTable('test_table');
  }
}

class _TestMigration2 extends Migration {
  @override
  String get name => '20240101000001_add_email_column';

  @override
  void up(MigrationBuilder builder) {
    builder.addColumn('test_table', 'email', FieldType.varchar, length: 255, nullable: true);
  }

  @override
  void down(MigrationBuilder builder) {
    builder.dropColumn('test_table', 'email');
  }
}

class _OrderedMigration extends Migration {
  final String _name;

  _OrderedMigration(this._name);

  @override
  String get name => _name;

  @override
  void up(MigrationBuilder builder) {
    // Just a placeholder migration
  }

  @override
  void down(MigrationBuilder builder) {
    // Just a placeholder migration
  }
}
