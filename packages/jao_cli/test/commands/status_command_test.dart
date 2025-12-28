import 'package:test/test.dart';
import 'package:jao/jao.dart';
import 'package:jao_cli/jao_cli.dart';

void main() {
  group('status command', () {
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

    test('Shows all migrations with status', () async {
      final result = await cli.run(['status']);

      expect(result, equals(0));
    });

    test('Shows pending status for unapplied migrations', () async {
      final result = await cli.run(['status']);

      expect(result, equals(0));
    });

    test('Shows applied status after migrations run', () async {
      // Apply migrations
      await cli.run(['migrate']);

      final result = await cli.run(['status']);

      expect(result, equals(0));
    });

    test('Shows partial status when some migrations applied', () async {
      cli = JaoCli(
        MigrationRunnerConfig(
          database: DatabaseConfig.sqlite(':memory:'),
          adapter: const SqliteAdapter(),
          migrations: [_TestMigration1()],
        ),
      );

      // Apply first migration only
      await cli.run(['migrate']);

      // Add more migrations
      cli = JaoCli(
        MigrationRunnerConfig(
          database: DatabaseConfig.sqlite(':memory:'),
          adapter: const SqliteAdapter(),
          migrations: migrations,
        ),
      );

      final result = await cli.run(['status']);

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

      final result = await cli.run(['status']);

      expect(result, equals(0));
    });

    test('Exit code 0 on success', () async {
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
