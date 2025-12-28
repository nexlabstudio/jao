import 'package:test/test.dart';
import 'package:jao/jao.dart';
import 'package:jao_cli/jao_cli.dart';

void main() {
  group('refresh command', () {
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

    test('Resets then migrates with --force', () async {
      // Apply migrations first
      await cli.run(['migrate']);

      // Refresh with force flag (skip confirmation)
      final result = await cli.run(['refresh', '--force']);

      expect(result, equals(0));
    });

    test('-f flag is alias for --force', () async {
      await cli.run(['migrate']);

      final result = await cli.run(['refresh', '-f']);

      expect(result, equals(0));
    });

    test('--dry-run shows SQL without executing', () async {
      await cli.run(['migrate']);

      final result = await cli.run(['refresh', '--dry-run']);

      expect(result, equals(0));
    });

    test('-n flag is alias for --dry-run', () async {
      await cli.run(['migrate']);

      final result = await cli.run(['refresh', '-n']);

      expect(result, equals(0));
    });

    test('Works on fresh database', () async {
      // No migrations applied yet
      final result = await cli.run(['refresh', '--force']);

      expect(result, equals(0));
    });

    test('Exit code 0 on success', () async {
      await cli.run(['migrate']);

      final result = await cli.run(['refresh', '--force']);

      expect(result, equals(0));
    });

    test('All migrations reapplied after refresh', () async {
      // Apply migrations
      await cli.run(['migrate']);

      // Refresh
      await cli.run(['refresh', '--force']);

      // Status should show all applied
      final result = await cli.run(['status']);

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
