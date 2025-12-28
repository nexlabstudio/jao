import 'dart:io';

import 'package:test/test.dart';
import 'package:jao/jao.dart';
import 'package:jao_cli/jao_cli.dart';

void main() {
  group('make command', () {
    late Directory tempDir;
    late JaoCli cli;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('jao_cli_test_');
      cli = JaoCli(
        MigrationRunnerConfig(
          database: DatabaseConfig.sqlite(':memory:'),
          adapter: const SqliteAdapter(),
          migrations: [],
        ),
      );
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('Creates migration file with timestamp', () async {
      final path = '${tempDir.path}/migrations';
      final result = await cli.run(['make', '-n=test_migration', '-p=$path']);

      expect(result, equals(0));

      final files = Directory(path).listSync();
      expect(files, hasLength(1));

      final fileName = files.first.path.split('/').last;
      // Filename should match pattern: YYYYMMDDHHMMSS_test_migration.dart
      expect(fileName, matches(RegExp(r'^\d{14}_test_migration\.dart$')));
    });

    test('Migration file in specified path', () async {
      final path = '${tempDir.path}/custom/migrations';
      final result = await cli.run(['make', '-n=my_migration', '-p=$path']);

      expect(result, equals(0));
      expect(Directory(path).existsSync(), isTrue);

      final files = Directory(path).listSync();
      expect(files, hasLength(1));
    });

    test('Migration file has correct class name', () async {
      final path = '${tempDir.path}/migrations';
      await cli.run(['make', '-n=create_users', '-p=$path']);

      final files = Directory(path).listSync();
      final content = File(files.first.path).readAsStringSync();

      // Class name should be PascalCase
      expect(content, contains('class CreateUsers extends Migration'));
    });

    test('Migration file has empty up()', () async {
      final path = '${tempDir.path}/migrations';
      await cli.run(['make', '-n=test_migration', '-p=$path']);

      final files = Directory(path).listSync();
      final content = File(files.first.path).readAsStringSync();

      expect(content, contains('void up(MigrationBuilder builder)'));
      // Should have TODO comment inside
      expect(content, contains('// TODO:'));
    });

    test('Migration file has empty down()', () async {
      final path = '${tempDir.path}/migrations';
      await cli.run(['make', '-n=test_migration', '-p=$path']);

      final files = Directory(path).listSync();
      final content = File(files.first.path).readAsStringSync();

      expect(content, contains('void down(MigrationBuilder builder)'));
    });

    test('Migration file imports jao', () async {
      final path = '${tempDir.path}/migrations';
      await cli.run(['make', '-n=test_migration', '-p=$path']);

      final files = Directory(path).listSync();
      final content = File(files.first.path).readAsStringSync();

      expect(content, contains("import 'package:jao/jao.dart'"));
    });

    test('-n flag sets migration name', () async {
      final path = '${tempDir.path}/migrations';
      await cli.run(['make', '-n=add_users_table', '-p=$path']);

      final files = Directory(path).listSync();
      final fileName = files.first.path.split('/').last;

      expect(fileName, contains('add_users_table'));
    });

    test('--name flag sets migration name', () async {
      final path = '${tempDir.path}/migrations';
      await cli.run(['make', '--name=add_posts_table', '-p=$path']);

      final files = Directory(path).listSync();
      final fileName = files.first.path.split('/').last;

      expect(fileName, contains('add_posts_table'));
    });

    test('Converts name to PascalCase class', () async {
      final path = '${tempDir.path}/migrations';
      await cli.run(['make', '-n=add_user_comments', '-p=$path']);

      final files = Directory(path).listSync();
      final content = File(files.first.path).readAsStringSync();

      // Underscored name should become PascalCase
      expect(content, contains('class AddUserComments extends Migration'));
    });

    test('Error without name', () async {
      final path = '${tempDir.path}/migrations';
      final result = await cli.run(['make', '-p=$path']);

      expect(result, equals(1));
    });

    test('Migration name can be positional argument', () async {
      final path = '${tempDir.path}/migrations';
      await cli.run(['make', 'create_products', '-p=$path']);

      final files = Directory(path).listSync();
      expect(files, hasLength(1));

      final fileName = files.first.path.split('/').last;
      expect(fileName, contains('create_products'));
    });

    test('Creates migrations directory if not exists', () async {
      final path = '${tempDir.path}/new_dir/migrations';
      expect(Directory(path).existsSync(), isFalse);

      await cli.run(['make', '-n=test', '-p=$path']);

      expect(Directory(path).existsSync(), isTrue);
    });

    test('Multiple migrations create separate files', () async {
      final path = '${tempDir.path}/migrations';

      await cli.run(['make', '-n=first_migration', '-p=$path']);
      await cli.run(['make', '-n=second_migration', '-p=$path']);

      final files = Directory(path).listSync().cast<File>();
      expect(files, hasLength(2));

      // Both files should exist with different names
      final names = files.map((f) => f.path.split('/').last).toList();
      expect(names.any((n) => n.contains('first_migration')), isTrue);
      expect(names.any((n) => n.contains('second_migration')), isTrue);
    });

    test('Migration file has name getter with timestamp', () async {
      final path = '${tempDir.path}/migrations';
      await cli.run(['make', '-n=test_migration', '-p=$path']);

      final files = Directory(path).listSync();
      final content = File(files.first.path).readAsStringSync();

      // Should have name getter with full migration name
      expect(content, contains("String get name =>"));
      // The name should be in format 'YYYYMMDDHHMMSS_test_migration'
      expect(content, matches(RegExp(r"'\d{14}_test_migration'")));
    });

    test('Migration extends Migration class', () async {
      final path = '${tempDir.path}/migrations';
      await cli.run(['make', '-n=test', '-p=$path']);

      final files = Directory(path).listSync();
      final content = File(files.first.path).readAsStringSync();

      expect(content, contains('extends Migration'));
    });

    test('Generated migration file has valid structure', () async {
      final path = '${tempDir.path}/migrations';
      await cli.run(['make', '-n=valid_migration', '-p=$path']);

      final files = Directory(path).listSync();
      final content = File(files.first.path).readAsStringSync();

      // Verify the file has valid Dart class structure
      expect(content, contains("import 'package:jao/jao.dart'"));
      expect(content, contains('class ValidMigration extends Migration'));
      expect(content, contains('@override'));
      expect(content, contains('String get name =>'));
      expect(content, contains('void up(MigrationBuilder builder)'));
      expect(content, contains('void down(MigrationBuilder builder)'));
      expect(content, contains('{'));
      expect(content, contains('}'));
    });

    test('Hyphenated name converts to PascalCase', () async {
      final path = '${tempDir.path}/migrations';
      await cli.run(['make', '-n=add-user-table', '-p=$path']);

      final files = Directory(path).listSync();
      final content = File(files.first.path).readAsStringSync();

      expect(content, contains('class AddUserTable extends Migration'));
    });

    test('Default path is lib/migrations', () async {
      // This test would need to run in a controlled directory
      // For now, just verify the make command accepts no path
      final path = '${tempDir.path}/lib/migrations';
      Directory(path).createSync(recursive: true);

      final cwd = Directory.current;
      Directory.current = tempDir;

      try {
        final result = await cli.run(['make', '-n=test_default']);
        // Will create in lib/migrations (default)
        expect(result, equals(0));
      } finally {
        Directory.current = cwd;
      }
    });

    group('project config', () {
      test('Uses migrations_path from jao.yaml', () async {
        final cwd = Directory.current;
        Directory.current = tempDir;

        try {
          // Create a jao.yaml with custom migrations path
          File('jao.yaml').writeAsStringSync('''
type: sqlite
database: test.db
migrations_path: custom/migrations
models_path: custom/models
''');

          // Create a fresh cli without config to use project config
          final cliWithoutConfig = JaoCli();

          final result = await cliWithoutConfig.run(['make', '-n=test_migration']);

          expect(result, equals(0));
          // Should have created in custom/migrations
          expect(Directory('custom/migrations').existsSync(), isTrue);

          final files = Directory('custom/migrations').listSync();
          expect(files, hasLength(1));
        } finally {
          Directory.current = cwd;
        }
      });

      test('Defaults to lib/migrations when no jao.yaml', () async {
        final cwd = Directory.current;
        Directory.current = tempDir;

        try {
          // No jao.yaml - should use default path
          final cliWithoutConfig = JaoCli();

          final result = await cliWithoutConfig.run(['make', '-n=test_migration']);

          expect(result, equals(0));
          // Should have created in lib/migrations (default)
          expect(Directory('lib/migrations').existsSync(), isTrue);
        } finally {
          Directory.current = cwd;
        }
      });

      test('-p flag overrides jao.yaml path', () async {
        final cwd = Directory.current;
        Directory.current = tempDir;

        try {
          // Create a jao.yaml with custom migrations path
          File('jao.yaml').writeAsStringSync('''
type: sqlite
migrations_path: custom/migrations
''');

          final cliWithoutConfig = JaoCli();

          // Override with -p flag
          final result = await cliWithoutConfig.run(['make', '-n=test', '-p=override/path']);

          expect(result, equals(0));
          // Should have created in override/path, NOT custom/migrations
          expect(Directory('override/path').existsSync(), isTrue);
          expect(Directory('custom/migrations').existsSync(), isFalse);
        } finally {
          Directory.current = cwd;
        }
      });
    });

    group('registry update', () {
      test('Adds to migrations.dart if exists', () async {
        final path = '${tempDir.path}/migrations';
        Directory(path).createSync(recursive: true);

        // Create a migrations.dart file
        final registryFile = File('$path/migrations.dart');
        registryFile.writeAsStringSync('''library;

import 'package:jao/jao.dart';

final allMigrations = <Migration>[
];
''');

        await cli.run(['make', '-n=new_migration', '-p=$path']);

        final content = registryFile.readAsStringSync();

        // Should have added import
        expect(content, contains("import '"));
        expect(content, contains('new_migration.dart'));

        // Should have added to list
        expect(content, contains('NewMigration()'));
      });

      test('Does not fail if migrations.dart does not exist', () async {
        final path = '${tempDir.path}/migrations';

        final result = await cli.run(['make', '-n=test', '-p=$path']);

        expect(result, equals(0));
      });
    });
  });
}
