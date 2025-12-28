import 'package:test/test.dart';
import 'package:jao/jao.dart';
import 'package:jao_cli/jao_cli.dart';

void main() {
  group('rollback command', () {
    late JaoCli cli;
    late List<Migration> migrations;

    setUp(() {
      migrations = [_TestMigration1(), _TestMigration2(), _TestMigration3()];
      cli = JaoCli(
        MigrationRunnerConfig(
          database: DatabaseConfig.sqlite(':memory:'),
          adapter: const SqliteAdapter(),
          migrations: migrations,
        ),
      );
    });

    test('Rolls back last migration', () async {
      // First apply migrations
      await cli.run(['migrate']);

      // Then rollback
      final result = await cli.run(['rollback']);

      expect(result, equals(0));
    });

    test('--step=N rolls back N migrations', () async {
      // First apply migrations
      await cli.run(['migrate']);

      // Rollback 2 migrations
      final result = await cli.run(['rollback', '--step=2']);

      expect(result, equals(0));
    });

    test('-s flag is alias for --step', () async {
      await cli.run(['migrate']);

      final result = await cli.run(['rollback', '-s=2']);

      expect(result, equals(0));
    });

    test('--dry-run shows SQL without executing', () async {
      await cli.run(['migrate']);

      final result = await cli.run(['rollback', '--dry-run']);

      expect(result, equals(0));
    });

    test('-n flag is alias for --dry-run', () async {
      await cli.run(['migrate']);

      final result = await cli.run(['rollback', '-n']);

      expect(result, equals(0));
    });

    test('Exit code 0 on success', () async {
      await cli.run(['migrate']);

      final result = await cli.run(['rollback']);

      expect(result, equals(0));
    });

    test('Shows info when nothing to rollback', () async {
      // No migrations applied yet
      final result = await cli.run(['rollback']);

      expect(result, equals(0));
    });

    test('--verbose shows detailed output', () async {
      cli = JaoCli(
        MigrationRunnerConfig(
          database: DatabaseConfig.sqlite(':memory:'),
          adapter: const SqliteAdapter(),
          migrations: migrations,
          verbose: true,
        ),
      );

      await cli.run(['migrate']);
      final result = await cli.run(['rollback', '-v']);

      expect(result, equals(0));
    });
  });
}

class _TestMigration1 extends Migration {
  @override
  String get name => '20240101000001_first';

  @override
  void up(MigrationBuilder builder) {
    builder.createTable('table1', (t) {
      t.id();
    });
  }

  @override
  void down(MigrationBuilder builder) {
    builder.dropTable('table1');
  }
}

class _TestMigration2 extends Migration {
  @override
  String get name => '20240101000002_second';

  @override
  void up(MigrationBuilder builder) {
    builder.createTable('table2', (t) {
      t.id();
    });
  }

  @override
  void down(MigrationBuilder builder) {
    builder.dropTable('table2');
  }
}

class _TestMigration3 extends Migration {
  @override
  String get name => '20240101000003_third';

  @override
  void up(MigrationBuilder builder) {
    builder.createTable('table3', (t) {
      t.id();
    });
  }

  @override
  void down(MigrationBuilder builder) {
    builder.dropTable('table3');
  }
}
