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
            const ModelFieldSchema(name: 'name', columnName: 'name', dbType: FieldType.varchar, maxLength: 100),
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

      final result = await cli.run(['makemigrations', '-p=$path']);

      expect(result, equals(0));

      // Should have created a migration file
      final files = Directory(path).listSync();
      expect(files, hasLength(1));
    });

    test('--dry-run shows without creating', () async {
      final path = '${tempDir.path}/migrations';

      final result = await cli.run(['makemigrations', '--dry-run', '-p=$path']);

      expect(result, equals(0));

      // Should NOT have created files
      expect(Directory(path).existsSync(), isFalse);
    });

    test('--empty creates empty migration', () async {
      final path = '${tempDir.path}/migrations';

      final result = await cli.run(['makemigrations', '--empty', '-n=empty_migration', '-p=$path']);

      expect(result, equals(0));

      final files = Directory(path).listSync();
      expect(files, hasLength(1));

      final content = File(files.first.path).readAsStringSync();
      expect(content, contains('class EmptyMigration'));
    });

    test('--name sets migration name', () async {
      final path = '${tempDir.path}/migrations';

      final result = await cli.run(['makemigrations', '--empty', '--name=custom_name', '-p=$path']);

      expect(result, equals(0));

      final files = Directory(path).listSync();
      final fileName = files.first.path.split('/').last;
      expect(fileName, contains('custom_name'));
    });

    test('-n flag sets migration name', () async {
      final path = '${tempDir.path}/migrations';

      final result = await cli.run(['makemigrations', '--empty', '-n=short_name', '-p=$path']);

      expect(result, equals(0));

      final files = Directory(path).listSync();
      final fileName = files.first.path.split('/').last;
      expect(fileName, contains('short_name'));
    });

    test('Names migration CreateUsers for single CreateTable', () async {
      final path = '${tempDir.path}/migrations';

      await cli.run(['makemigrations', '-p=$path']);

      final files = Directory(path).listSync();
      final content = File(files.first.path).readAsStringSync();
      expect(content, contains('class CreateUsers'));
    });

    test('Names migration CreateUsers for single table model', () async {
      final path = '${tempDir.path}/migrations';

      await cli.run(['makemigrations', '-p=$path']);

      final files = Directory(path).listSync();
      final fileName = files.first.path.split('/').last;
      expect(fileName, contains('create_users'));
    });

    test('Names migration CreateTables for multiple table models', () async {
      final multiModels = [
        ...models,
        const ModelSchema(
          className: 'Post',
          tableName: 'posts',
          fields: [
            ModelFieldSchema(
              name: 'id',
              columnName: 'id',
              dbType: FieldType.serial,
              primaryKey: true,
              autoIncrement: true,
            ),
            ModelFieldSchema(name: 'title', columnName: 'title', dbType: FieldType.varchar, maxLength: 200),
          ],
        ),
      ];

      cli = JaoCli(
        MigrationRunnerConfig(
          database: DatabaseConfig.sqlite(':memory:'),
          adapter: const SqliteAdapter(),
          migrations: [],
          modelSchemas: multiModels,
        ),
      );

      final path = '${tempDir.path}/migrations';
      await cli.run(['makemigrations', '-p=$path']);

      final files = Directory(path).listSync();
      final content = File(files.first.path).readAsStringSync();
      expect(content, contains('class CreateTables'));
    });

    group('generateMigrationName', () {
      test('returns custom name in PascalCase', () {
        expect(generateMigrationName('add_users', []), equals('AddUsers'));
      });

      test('returns EmptyMigration for empty operations', () {
        expect(generateMigrationName(null, []), equals('EmptyMigration'));
      });

      test('returns CreateTable name for single CreateTable', () {
        final ops = [
          CreateTable(TableDefinition(
            name: 'users',
            columns: [const ColumnDefinition(name: 'id', type: FieldType.serial)],
          )),
        ];
        expect(generateMigrationName(null, ops), equals('CreateUsers'));
      });

      test('returns CreateTables for multiple CreateTable ops', () {
        final ops = [
          CreateTable(TableDefinition(
            name: 'users',
            columns: [const ColumnDefinition(name: 'id', type: FieldType.serial)],
          )),
          CreateTable(TableDefinition(
            name: 'posts',
            columns: [const ColumnDefinition(name: 'id', type: FieldType.serial)],
          )),
        ];
        expect(generateMigrationName(null, ops), equals('CreateTables'));
      });

      test('returns AddColumnToTable for AddColumn', () {
        const ops = [AddColumn('users', ColumnDefinition(name: 'age', type: FieldType.integer))];
        expect(generateMigrationName(null, ops), equals('AddAgeToUsers'));
      });

      test('returns DropColumnFromTable for DropColumn', () {
        const ops = [DropColumn('users', 'age')];
        expect(generateMigrationName(null, ops), equals('DropAgeFromUsers'));
      });

      test('returns AlterColumnOnTable for AlterColumn', () {
        const ops = [AlterColumn(ColumnModification(table: 'users', column: 'email'))];
        expect(generateMigrationName(null, ops), equals('AlterEmailOnUsers'));
      });

      test('returns AddFkOnTable for AddForeignKey', () {
        const ops = [
          AddForeignKey(
              'posts', ForeignKeyDefinition(column: 'user_id', referencedTable: 'users', referencedColumn: 'id')),
        ];
        expect(generateMigrationName(null, ops), equals('AddFkOnPosts'));
      });

      test('returns AddIndexOnTable for CreateIndex', () {
        final ops = [
          CreateIndex('users', const IndexDefinition(name: 'idx_users_email', columns: ['email'])),
        ];
        expect(generateMigrationName(null, ops), equals('AddIndexOnUsers'));
      });

      test('returns DropConstraintOnTable for DropConstraint', () {
        const ops = [DropConstraint('posts', 'fk_posts_user_id')];
        expect(generateMigrationName(null, ops), equals('DropConstraintOnPosts'));
      });

      test('returns RenameOldToNew for RenameTable', () {
        const ops = [RenameTable('users', 'accounts')];
        expect(generateMigrationName(null, ops), equals('RenameUsersToAccounts'));
      });

      test('returns RenameColumnOnTable for RenameColumn', () {
        const ops = [RenameColumn('users', 'name', 'full_name')];
        expect(generateMigrationName(null, ops), equals('RenameNameOnUsers'));
      });
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

      final result = await cli.run(['makemigrations', '-p=$path']);

      // Should fail because no models
      expect(result, equals(1));
    });

    test('Exit code 0 on success', () async {
      final path = '${tempDir.path}/migrations';

      final result = await cli.run(['makemigrations', '--empty', '-n=test', '-p=$path']);

      expect(result, equals(0));
    });

    test('Generated file has up() method', () async {
      final path = '${tempDir.path}/migrations';

      await cli.run(['makemigrations', '--empty', '-n=test', '-p=$path']);

      final files = Directory(path).listSync();
      final content = File(files.first.path).readAsStringSync();

      expect(content, contains('void up(MigrationBuilder builder)'));
    });

    test('Generated file has down() method', () async {
      final path = '${tempDir.path}/migrations';

      await cli.run(['makemigrations', '--empty', '-n=test', '-p=$path']);

      final files = Directory(path).listSync();
      final content = File(files.first.path).readAsStringSync();

      expect(content, contains('void down(MigrationBuilder builder)'));
    });

    test('Creates path if not exists', () async {
      final path = '${tempDir.path}/new/nested/migrations';
      expect(Directory(path).existsSync(), isFalse);

      await cli.run(['makemigrations', '--empty', '-n=test', '-p=$path']);

      expect(Directory(path).existsSync(), isTrue);
    });
  });
}
