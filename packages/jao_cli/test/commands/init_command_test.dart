import 'dart:io';

import 'package:test/test.dart';
import 'package:jao_cli/jao_cli.dart';

void main() {
  group('init command', () {
    late Directory tempDir;
    late Directory originalDir;
    late JaoCli cli;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('jao_init_test_');
      originalDir = Directory.current;
      Directory.current = tempDir;

      // Create a minimal pubspec.yaml to simulate a Dart project
      File('pubspec.yaml').writeAsStringSync('''
name: test_project
environment:
  sdk: ^3.0.0
''');

      cli = JaoCli();
    });

    tearDown(() {
      Directory.current = originalDir;
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('Creates jao.yaml', () async {
      await cli.run(['init']);

      expect(File('jao.yaml').existsSync(), isTrue);
    });

    test('jao.yaml has correct structure (paths only)', () async {
      await cli.run(['init']);

      final content = File('jao.yaml').readAsStringSync();
      expect(content, contains('migrations_path:'));
      expect(content, contains('models_path:'));
    });

    test('Creates lib/migrations/ directory', () async {
      await cli.run(['init']);

      expect(Directory('lib/migrations').existsSync(), isTrue);
    });

    test('Creates lib/migrations/migrations.dart', () async {
      await cli.run(['init']);

      final file = File('lib/migrations/migrations.dart');
      expect(file.existsSync(), isTrue);

      final content = file.readAsStringSync();
      expect(content, contains('allMigrations'));
      expect(content, contains('<Migration>'));
    });

    test('Creates lib/config/ directory', () async {
      await cli.run(['init']);

      expect(Directory('lib/config').existsSync(), isTrue);
    });

    test('Creates lib/config/database.dart', () async {
      await cli.run(['init']);

      final file = File('lib/config/database.dart');
      expect(file.existsSync(), isTrue);

      final content = file.readAsStringSync();
      expect(content, contains('databaseConfig'));
      expect(content, contains('databaseAdapter'));
      expect(content, contains('package:jao/jao.dart'));
    });

    test('lib/config/database.dart has SQLite as default', () async {
      await cli.run(['init']);

      final content = File('lib/config/database.dart').readAsStringSync();
      expect(content, contains('DatabaseConfig.sqlite'));
      expect(content, contains('SqliteAdapter'));
    });

    test('Creates bin/migrate.dart', () async {
      await cli.run(['init']);

      final file = File('bin/migrate.dart');
      expect(file.existsSync(), isTrue);

      final content = file.readAsStringSync();
      expect(content, contains('package:jao_cli/jao_cli.dart'));
      expect(content, contains('JaoCli'));
    });

    test('bin/migrate.dart imports from lib/config/database.dart', () async {
      await cli.run(['init']);

      final content = File('bin/migrate.dart').readAsStringSync();
      expect(content, contains("import '../lib/config/database.dart'"));
      expect(content, contains('databaseConfig'));
      expect(content, contains('databaseAdapter'));
    });

    test('bin/migrate.dart imports migrations', () async {
      await cli.run(['init']);

      final content = File('bin/migrate.dart').readAsStringSync();
      expect(content, contains("import '../lib/migrations/migrations.dart'"));
      expect(content, contains('allMigrations'));
    });

    test('Does not overwrite existing jao.yaml', () async {
      final originalContent = '# Original config\nmigrations_path: custom/path\n';
      File('jao.yaml').writeAsStringSync(originalContent);

      await cli.run(['init']);

      final content = File('jao.yaml').readAsStringSync();
      expect(content, contains('migrations_path: lib/migrations'));
    });

    test('Does not overwrite existing migrations.dart', () async {
      Directory('lib/migrations').createSync(recursive: true);
      final originalContent = '// Original migrations\n';
      File('lib/migrations/migrations.dart').writeAsStringSync(originalContent);

      await cli.run(['init']);

      final content = File('lib/migrations/migrations.dart').readAsStringSync();
      expect(content, equals(originalContent));
    });

    test('Does not overwrite existing lib/config/database.dart', () async {
      Directory('lib/config').createSync(recursive: true);
      final originalContent = '// Original database config\n';
      File('lib/config/database.dart').writeAsStringSync(originalContent);

      await cli.run(['init']);

      final content = File('lib/config/database.dart').readAsStringSync();
      expect(content, equals(originalContent));
    });

    test('Does not overwrite existing bin/migrate.dart', () async {
      Directory('bin').createSync();
      final originalContent = '// Original migrate\n';
      File('bin/migrate.dart').writeAsStringSync(originalContent);

      await cli.run(['init']);

      final content = File('bin/migrate.dart').readAsStringSync();
      expect(content, equals(originalContent));
    });

    test('Exit code is 0 on success', () async {
      final result = await cli.run(['init']);

      expect(result, equals(0));
    });
  });
}
