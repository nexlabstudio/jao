import 'dart:io';

import 'package:test/test.dart';
import 'package:jao/jao.dart';
import 'package:jao_cli/jao_cli.dart';

void main() {
  group('makemigrations command', () {
    late Directory tempDir;
    late JaoCli cli;
    late List<ModelSchema> models;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('jao_makemig_test_');

      models = [
        ModelSchema(
          className: 'User',
          tableName: 'users',
          fields: [
            const ModelFieldSchema(
              name: 'id',
              columnName: 'id',
              dbType: FieldType.serial,
              primaryKey: true,
              autoIncrement: true,
            ),
            const ModelFieldSchema(
              name: 'name',
              columnName: 'name',
              dbType: FieldType.varchar,
              maxLength: 100,
            ),
            const ModelFieldSchema(
              name: 'email',
              columnName: 'email',
              dbType: FieldType.varchar,
              maxLength: 255,
              unique: true,
            ),
          ],
        ),
      ];

      cli = JaoCli(
        MigrationRunnerConfig(
          database: DatabaseConfig.sqlite(':memory:'),
          adapter: const SqliteAdapter(),
          migrations: [],
          modelSchemas: models,
        ),
      );
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('Detects new model and creates migration', () async {
      final path = '${tempDir.path}/migrations';

      final result = await cli.run([
        'makemigrations',
        '-p=$path',
      ]);

      expect(result, equals(0));

      // Should have created a migration file
      final files = Directory(path).listSync();
      expect(files, hasLength(1));
    });

    test('--dry-run shows without creating', () async {
      final path = '${tempDir.path}/migrations';

      final result = await cli.run([
        'makemigrations',
        '--dry-run',
        '-p=$path',
      ]);

      expect(result, equals(0));

      // Should NOT have created files
      expect(Directory(path).existsSync(), isFalse);
    });

    test('--empty creates empty migration', () async {
      final path = '${tempDir.path}/migrations';

      final result = await cli.run([
        'makemigrations',
        '--empty',
        '-n=empty_migration',
        '-p=$path',
      ]);

      expect(result, equals(0));

      final files = Directory(path).listSync();
      expect(files, hasLength(1));

      final content = File(files.first.path).readAsStringSync();
      expect(content, contains('class EmptyMigration'));
    });

    test('--name sets migration name', () async {
      final path = '${tempDir.path}/migrations';

      final result = await cli.run([
        'makemigrations',
        '--empty',
        '--name=custom_name',
        '-p=$path',
      ]);

      expect(result, equals(0));

      final files = Directory(path).listSync();
      final fileName = files.first.path.split('/').last;
      expect(fileName, contains('custom_name'));
    });

    test('-n flag sets migration name', () async {
      final path = '${tempDir.path}/migrations';

      final result = await cli.run([
        'makemigrations',
        '--empty',
        '-n=short_name',
        '-p=$path',
      ]);

      expect(result, equals(0));

      final files = Directory(path).listSync();
      final fileName = files.first.path.split('/').last;
      expect(fileName, contains('short_name'));
    });

    test('Error when no model schemas found', () async {
      cli = JaoCli(
        MigrationRunnerConfig(
          database: DatabaseConfig.sqlite(':memory:'),
          adapter: const SqliteAdapter(),
          migrations: [],
          modelSchemas: [],
        ),
      );

      final path = '${tempDir.path}/migrations';

      final result = await cli.run([
        'makemigrations',
        '-p=$path',
      ]);

      // Should fail because no models
      expect(result, equals(1));
    });

    test('Exit code 0 on success', () async {
      final path = '${tempDir.path}/migrations';

      final result = await cli.run([
        'makemigrations',
        '--empty',
        '-n=test',
        '-p=$path',
      ]);

      expect(result, equals(0));
    });

    test('Generated file has up() method', () async {
      final path = '${tempDir.path}/migrations';

      await cli.run([
        'makemigrations',
        '--empty',
        '-n=test',
        '-p=$path',
      ]);

      final files = Directory(path).listSync();
      final content = File(files.first.path).readAsStringSync();

      expect(content, contains('void up(MigrationBuilder builder)'));
    });

    test('Generated file has down() method', () async {
      final path = '${tempDir.path}/migrations';

      await cli.run([
        'makemigrations',
        '--empty',
        '-n=test',
        '-p=$path',
      ]);

      final files = Directory(path).listSync();
      final content = File(files.first.path).readAsStringSync();

      expect(content, contains('void down(MigrationBuilder builder)'));
    });

    test('Creates path if not exists', () async {
      final path = '${tempDir.path}/new/nested/migrations';
      expect(Directory(path).existsSync(), isFalse);

      await cli.run([
        'makemigrations',
        '--empty',
        '-n=test',
        '-p=$path',
      ]);

      expect(Directory(path).existsSync(), isTrue);
    });
  });
}
