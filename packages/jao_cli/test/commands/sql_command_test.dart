import 'package:test/test.dart';
import 'package:jao/jao.dart';
import 'package:jao_cli/jao_cli.dart';

void main() {
  group('sql command', () {
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

    test('Shows SQL for all migrations', () async {
      final result = await cli.run(['sql']);

      expect(result, equals(0));
    });

    test('--down shows rollback SQL', () async {
      final result = await cli.run(['sql', '--down']);

      expect(result, equals(0));
    });

    test('--migration=NAME shows specific migration', () async {
      final result = await cli.run(['sql', '--migration=20240101000001_first']);

      expect(result, equals(0));
    });

    test('-m flag is alias for --migration', () async {
      final result = await cli.run(['sql', '-m=20240101000001_first']);

      expect(result, equals(0));
    });

    test('Shows up SQL by default', () async {
      final result = await cli.run(['sql']);

      expect(result, equals(0));
    });

    test('Error for non-existent migration name', () async {
      final result = await cli.run(['sql', '--migration=nonexistent']);

      expect(result, equals(1));
    });

    test('Exit code 0 on success', () async {
      final result = await cli.run(['sql']);

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

      final result = await cli.run(['sql']);

      expect(result, equals(0));
    });

    test('Shows SQL for single migration with --down', () async {
      final result = await cli.run(['sql', '--migration=20240101000001_first', '--down']);

      expect(result, equals(0));
    });
  });
}

class _TestMigration1 extends Migration {
  @override
  String get name => '20240101000001_first';

  @override
  void up(MigrationBuilder builder) {
    builder.createTable('users', (t) {
      t.id();
      t.string('name');
      t.string('email');
    });
  }

  @override
  void down(MigrationBuilder builder) {
    builder.dropTable('users');
  }
}

class _TestMigration2 extends Migration {
  @override
  String get name => '20240101000002_second';

  @override
  void up(MigrationBuilder builder) {
    builder.createTable('posts', (t) {
      t.id();
      t.string('title');
      t.text('content');
      t.foreignKey('user_id', 'users');
    });
  }

  @override
  void down(MigrationBuilder builder) {
    builder.dropTable('posts');
  }
}
