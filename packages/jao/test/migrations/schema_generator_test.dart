import 'package:jao/jao.dart';
import 'package:test/test.dart';

void main() {
  group('ModelSchema', () {
    test('stores basic properties', () {
      const schema = ModelSchema(className: 'User', tableName: 'users', fields: []);

      expect(schema.className, equals('User'));
      expect(schema.tableName, equals('users'));
      expect(schema.fields, isEmpty);
    });

    test('stores fields', () {
      const schema = ModelSchema(
        className: 'User',
        tableName: 'users',
        fields: [
          ModelFieldSchema(
            name: 'id',
            columnName: 'id',
            dbType: FieldType.serial,
            primaryKey: true,
            autoIncrement: true,
          ),
          ModelFieldSchema(name: 'name', columnName: 'name', dbType: FieldType.varchar, maxLength: 100),
        ],
      );

      expect(schema.fields.length, equals(2));
      expect(schema.fields[0].name, equals('id'));
      expect(schema.fields[1].name, equals('name'));
    });

    test('stores uniqueTogether constraints', () {
      const schema = ModelSchema(
        className: 'UserRole',
        tableName: 'user_roles',
        fields: [],
        uniqueTogether: ['user_id, role_id'],
      );

      expect(schema.uniqueTogether, isNotNull);
      expect(schema.uniqueTogether!.length, equals(1));
      expect(schema.uniqueTogether![0], equals('user_id, role_id'));
    });

    test('stores indexTogether constraints', () {
      const schema = ModelSchema(
        className: 'Log',
        tableName: 'logs',
        fields: [],
        indexTogether: ['user_id, action', 'created_at, level'],
      );

      expect(schema.indexTogether, isNotNull);
      expect(schema.indexTogether!.length, equals(2));
    });
  });

  group('ModelFieldSchema', () {
    test('stores basic field properties', () {
      const field = ModelFieldSchema(name: 'email', columnName: 'email', dbType: FieldType.varchar);

      expect(field.name, equals('email'));
      expect(field.columnName, equals('email'));
      expect(field.dbType, equals(FieldType.varchar));
      expect(field.nullable, isFalse);
      expect(field.unique, isFalse);
      expect(field.index, isFalse);
      expect(field.primaryKey, isFalse);
      expect(field.autoIncrement, isFalse);
    });

    test('stores nullable field', () {
      const field = ModelFieldSchema(name: 'bio', columnName: 'bio', dbType: FieldType.text, nullable: true);

      expect(field.nullable, isTrue);
    });

    test('stores unique field', () {
      const field = ModelFieldSchema(name: 'email', columnName: 'email', dbType: FieldType.varchar, unique: true);

      expect(field.unique, isTrue);
    });

    test('stores indexed field', () {
      const field = ModelFieldSchema(name: 'status', columnName: 'status', dbType: FieldType.varchar, index: true);

      expect(field.index, isTrue);
    });

    test('stores primary key field', () {
      const field = ModelFieldSchema(
        name: 'id',
        columnName: 'id',
        dbType: FieldType.serial,
        primaryKey: true,
        autoIncrement: true,
      );

      expect(field.primaryKey, isTrue);
      expect(field.autoIncrement, isTrue);
    });

    test('stores default value', () {
      const field = ModelFieldSchema(
        name: 'isActive',
        columnName: 'is_active',
        dbType: FieldType.boolean,
        defaultValue: true,
      );

      expect(field.defaultValue, equals(true));
    });

    test('stores varchar maxLength', () {
      const field = ModelFieldSchema(name: 'name', columnName: 'name', dbType: FieldType.varchar, maxLength: 255);

      expect(field.maxLength, equals(255));
    });

    test('stores decimal precision and scale', () {
      const field = ModelFieldSchema(
        name: 'price',
        columnName: 'price',
        dbType: FieldType.decimal,
        precision: 10,
        scale: 2,
      );

      expect(field.precision, equals(10));
      expect(field.scale, equals(2));
    });

    test('stores foreign key info', () {
      const field = ModelFieldSchema(
        name: 'authorId',
        columnName: 'author_id',
        dbType: FieldType.integer,
        foreignKey: ForeignKeyInfo(referencedTable: 'users', referencedColumn: 'id', onDelete: OnDeleteAction.cascade),
      );

      expect(field.foreignKey, isNotNull);
      expect(field.foreignKey!.referencedTable, equals('users'));
      expect(field.foreignKey!.referencedColumn, equals('id'));
      expect(field.foreignKey!.onDelete, equals(OnDeleteAction.cascade));
    });

    test('stores autoNowAdd flag', () {
      const field = ModelFieldSchema(
        name: 'createdAt',
        columnName: 'created_at',
        dbType: FieldType.timestampTz,
        autoNowAdd: true,
      );

      expect(field.autoNowAdd, isTrue);
    });

    test('stores autoNow flag', () {
      const field = ModelFieldSchema(
        name: 'updatedAt',
        columnName: 'updated_at',
        dbType: FieldType.timestampTz,
        autoNow: true,
      );

      expect(field.autoNow, isTrue);
    });
  });

  group('ForeignKeyInfo', () {
    test('stores basic properties', () {
      const fk = ForeignKeyInfo(referencedTable: 'users');

      expect(fk.referencedTable, equals('users'));
      expect(fk.referencedColumn, equals('id')); // default
      expect(fk.onDelete, equals(OnDeleteAction.cascade)); // default
    });

    test('stores custom referenced column', () {
      const fk = ForeignKeyInfo(referencedTable: 'users', referencedColumn: 'uuid');

      expect(fk.referencedColumn, equals('uuid'));
    });

    test('stores onDelete action', () {
      const fk = ForeignKeyInfo(referencedTable: 'users', onDelete: OnDeleteAction.setNull);

      expect(fk.onDelete, equals(OnDeleteAction.setNull));
    });
  });

  group('SchemaGenerator', () {
    late SchemaGenerator generator;

    setUp(() {
      generator = SchemaGenerator(const SqliteAdapter());
    });

    group('generateCreateTable()', () {
      test('generates CreateTable operation for simple model', () {
        const schema = ModelSchema(
          className: 'Author',
          tableName: 'authors',
          fields: [
            ModelFieldSchema(
              name: 'id',
              columnName: 'id',
              dbType: FieldType.serial,
              primaryKey: true,
              autoIncrement: true,
            ),
            ModelFieldSchema(name: 'name', columnName: 'name', dbType: FieldType.varchar, maxLength: 100),
          ],
        );

        final operations = generator.generateCreateTable(schema);

        expect(operations.length, equals(1));
        expect(operations[0], isA<CreateTable>());

        final createTable = operations[0] as CreateTable;
        expect(createTable.table.name, equals('authors'));
        expect(createTable.table.columns.length, equals(2));
      });

      test('generates CreateTable with all column types', () {
        const schema = ModelSchema(
          className: 'TestModel',
          tableName: 'test_models',
          fields: [
            ModelFieldSchema(
              name: 'id',
              columnName: 'id',
              dbType: FieldType.serial,
              primaryKey: true,
              autoIncrement: true,
            ),
            ModelFieldSchema(name: 'name', columnName: 'name', dbType: FieldType.varchar, maxLength: 255),
            ModelFieldSchema(name: 'bio', columnName: 'bio', dbType: FieldType.text, nullable: true),
            ModelFieldSchema(name: 'age', columnName: 'age', dbType: FieldType.integer),
            ModelFieldSchema(name: 'score', columnName: 'score', dbType: FieldType.real),
            ModelFieldSchema(name: 'price', columnName: 'price', dbType: FieldType.decimal, precision: 10, scale: 2),
            ModelFieldSchema(
              name: 'isActive',
              columnName: 'is_active',
              dbType: FieldType.boolean,
              defaultValue: true,
            ),
            ModelFieldSchema(name: 'birthDate', columnName: 'birth_date', dbType: FieldType.date),
            ModelFieldSchema(
              name: 'createdAt',
              columnName: 'created_at',
              dbType: FieldType.timestampTz,
              defaultValue: 'CURRENT_TIMESTAMP',
            ),
            ModelFieldSchema(name: 'uuid', columnName: 'uuid', dbType: FieldType.uuid),
            ModelFieldSchema(name: 'data', columnName: 'data', dbType: FieldType.jsonb, nullable: true),
            ModelFieldSchema(name: 'file', columnName: 'file', dbType: FieldType.bytea, nullable: true),
          ],
        );

        final operations = generator.generateCreateTable(schema);

        expect(operations.length, equals(1));
        final createTable = operations[0] as CreateTable;
        expect(createTable.table.columns.length, equals(12));
      });

      test('generates CreateTable with UuidPrimaryKey', () {
        const schema = ModelSchema(
          className: 'Merchant',
          tableName: 'merchants',
          fields: [
            ModelFieldSchema(
              name: 'id',
              columnName: 'id',
              dbType: FieldType.uuid,
              primaryKey: true,
            ),
            ModelFieldSchema(name: 'name', columnName: 'name', dbType: FieldType.varchar, maxLength: 100),
            ModelFieldSchema(
                name: 'email', columnName: 'email', dbType: FieldType.varchar, maxLength: 254, unique: true),
            ModelFieldSchema(
              name: 'createdAt',
              columnName: 'created_at',
              dbType: FieldType.timestampTz,
              defaultValue: 'CURRENT_TIMESTAMP',
            ),
          ],
        );

        final operations = generator.generateCreateTable(schema);

        expect(operations.length, equals(1));
        final createTable = operations[0] as CreateTable;
        final table = createTable.table;

        // The id column should exist
        final idColumn = table.columns.where((c) => c.name == 'id').firstOrNull;
        expect(idColumn, isNotNull, reason: 'UUID primary key column should be created');

        // The id column should be a UUID type
        expect(idColumn!.type, equals(FieldType.uuid));

        // The id column should be marked as primary key
        expect(idColumn.primaryKey, isTrue, reason: 'UUID column should be marked as primary key');

        // The table should have the id as its primary key
        expect(table.primaryKey, equals('id'), reason: 'Table primary key should be set to id');
      });

      test('generates CreateTable with bigId primary key', () {
        const schema = ModelSchema(
          className: 'BigModel',
          tableName: 'big_models',
          fields: [
            ModelFieldSchema(
              name: 'id',
              columnName: 'id',
              dbType: FieldType.bigSerial,
              primaryKey: true,
              autoIncrement: true,
            ),
          ],
        );

        final operations = generator.generateCreateTable(schema);

        expect(operations.length, equals(1));
        final createTable = operations[0] as CreateTable;
        expect(createTable.table.columns[0].type, equals(FieldType.bigSerial));
      });

      test('generates CreateTable with foreign key', () {
        const schema = ModelSchema(
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
            ModelFieldSchema(
              name: 'authorId',
              columnName: 'author_id',
              dbType: FieldType.integer,
              foreignKey: ForeignKeyInfo(
                referencedTable: 'authors',
                referencedColumn: 'id',
                onDelete: OnDeleteAction.cascade,
              ),
            ),
          ],
        );

        final operations = generator.generateCreateTable(schema);

        expect(operations.length, equals(1));
        final createTable = operations[0] as CreateTable;
        expect(createTable.table.foreignKeys.length, equals(1));
        expect(createTable.table.foreignKeys[0].referencedTable, equals('authors'));
      });

      test('generates CreateIndex for indexed fields', () {
        const schema = ModelSchema(
          className: 'User',
          tableName: 'users',
          fields: [
            ModelFieldSchema(
              name: 'id',
              columnName: 'id',
              dbType: FieldType.serial,
              primaryKey: true,
              autoIncrement: true,
            ),
            ModelFieldSchema(name: 'status', columnName: 'status', dbType: FieldType.varchar, index: true),
          ],
        );

        final operations = generator.generateCreateTable(schema);

        expect(operations.length, equals(2));
        expect(operations[0], isA<CreateTable>());
        expect(operations[1], isA<CreateIndex>());

        final createIndex = operations[1] as CreateIndex;
        expect(createIndex.table, equals('users'));
        expect(createIndex.index.name, equals('idx_users_status'));
        expect(createIndex.index.columns, equals(['status']));
      });

      test('generates unique constraints with uniqueTogether', () {
        const schema = ModelSchema(
          className: 'UserRole',
          tableName: 'user_roles',
          fields: [
            ModelFieldSchema(
              name: 'id',
              columnName: 'id',
              dbType: FieldType.serial,
              primaryKey: true,
              autoIncrement: true,
            ),
            ModelFieldSchema(name: 'userId', columnName: 'user_id', dbType: FieldType.integer),
            ModelFieldSchema(name: 'roleId', columnName: 'role_id', dbType: FieldType.integer),
          ],
          uniqueTogether: ['user_id, role_id'],
        );

        final operations = generator.generateCreateTable(schema);

        expect(operations.length, equals(1));
        final createTable = operations[0] as CreateTable;
        expect(createTable.table.indexes.length, equals(1));
        expect(createTable.table.indexes[0].unique, isTrue);
        expect(createTable.table.indexes[0].columns, equals(['user_id', 'role_id']));
      });

      test('generates composite indexes with indexTogether', () {
        const schema = ModelSchema(
          className: 'Log',
          tableName: 'logs',
          fields: [
            ModelFieldSchema(
              name: 'id',
              columnName: 'id',
              dbType: FieldType.serial,
              primaryKey: true,
              autoIncrement: true,
            ),
            ModelFieldSchema(name: 'userId', columnName: 'user_id', dbType: FieldType.integer),
            ModelFieldSchema(name: 'action', columnName: 'action', dbType: FieldType.varchar),
          ],
          indexTogether: ['user_id, action'],
        );

        final operations = generator.generateCreateTable(schema);

        expect(operations.length, equals(1));
        final createTable = operations[0] as CreateTable;
        expect(createTable.table.indexes.length, equals(1));
        expect(createTable.table.indexes[0].unique, isFalse);
        expect(createTable.table.indexes[0].columns, equals(['user_id', 'action']));
      });

      test('does not generate index for primary key fields', () {
        const schema = ModelSchema(
          className: 'User',
          tableName: 'users',
          fields: [
            ModelFieldSchema(
              name: 'id',
              columnName: 'id',
              dbType: FieldType.serial,
              primaryKey: true,
              autoIncrement: true,
              index: true, // Should be ignored for PK
            ),
          ],
        );

        final operations = generator.generateCreateTable(schema);

        // Only CreateTable, no separate CreateIndex for PK
        expect(operations.length, equals(1));
        expect(operations[0], isA<CreateTable>());
      });

      test('does not generate index for unique fields (unique constraint is enough)', () {
        const schema = ModelSchema(
          className: 'User',
          tableName: 'users',
          fields: [
            ModelFieldSchema(
              name: 'id',
              columnName: 'id',
              dbType: FieldType.serial,
              primaryKey: true,
              autoIncrement: true,
            ),
            ModelFieldSchema(
              name: 'email',
              columnName: 'email',
              dbType: FieldType.varchar,
              unique: true,
              index: true, // Should be ignored for unique
            ),
          ],
        );

        final operations = generator.generateCreateTable(schema);

        // Only CreateTable, no separate CreateIndex for unique
        expect(operations.length, equals(1));
        expect(operations[0], isA<CreateTable>());
      });

      test('handles nullable foreign key', () {
        const schema = ModelSchema(
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
            ModelFieldSchema(
              name: 'authorId',
              columnName: 'author_id',
              dbType: FieldType.integer,
              nullable: true,
              foreignKey: ForeignKeyInfo(referencedTable: 'authors', onDelete: OnDeleteAction.setNull),
            ),
          ],
        );

        final operations = generator.generateCreateTable(schema);

        final createTable = operations[0] as CreateTable;
        // The foreign key column should be nullable
        final authorIdCol = createTable.table.columns.firstWhere((c) => c.name == 'author_id');
        expect(authorIdCol.nullable, isTrue);
      });
    });

    group('generateDiff()', () {
      late SqliteAdapter adapter;
      late ConnectionPool pool;

      setUpAll(() async {
        adapter = const SqliteAdapter();
        final config = DatabaseConfig.sqliteMemory();
        pool = await adapter.createPool(config);
      });

      tearDownAll(() async {
        await pool.close();
      });

      test('generates CreateTable for new model', () async {
        await pool.withConnection((conn) async {
          const schema = ModelSchema(
            className: 'NewTable',
            tableName: 'new_table',
            fields: [
              ModelFieldSchema(
                name: 'id',
                columnName: 'id',
                dbType: FieldType.serial,
                primaryKey: true,
                autoIncrement: true,
              ),
              ModelFieldSchema(name: 'name', columnName: 'name', dbType: FieldType.varchar),
            ],
          );

          final operations = await generator.generateDiff(conn, [schema]);

          expect(operations.length, greaterThanOrEqualTo(1));
          expect(operations[0], isA<CreateTable>());
        });
      });

      test('generates AddColumn for new field in existing table', () async {
        await pool.withConnection((conn) async {
          // First create the table
          await conn.execute('''
            CREATE TABLE IF NOT EXISTS existing_table (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL
            )
          ''');

          // Model with a new column
          const schema = ModelSchema(
            className: 'ExistingTable',
            tableName: 'existing_table',
            fields: [
              ModelFieldSchema(
                name: 'id',
                columnName: 'id',
                dbType: FieldType.serial,
                primaryKey: true,
                autoIncrement: true,
              ),
              ModelFieldSchema(name: 'name', columnName: 'name', dbType: FieldType.text),
              ModelFieldSchema(name: 'email', columnName: 'email', dbType: FieldType.varchar, maxLength: 254),
            ],
          );

          final operations = await generator.generateDiff(conn, [schema]);

          expect(operations.any((op) => op is AddColumn), isTrue);
          final addColumn = operations.whereType<AddColumn>().first;
          expect(addColumn.column.name, equals('email'));
        });
      });

      test('generates CreateIndex for new indexed field', () async {
        await pool.withConnection((conn) async {
          // First create the table
          await conn.execute('''
            CREATE TABLE IF NOT EXISTS indexed_table (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL
            )
          ''');

          // Model with a new indexed column
          const schema = ModelSchema(
            className: 'IndexedTable',
            tableName: 'indexed_table',
            fields: [
              ModelFieldSchema(
                name: 'id',
                columnName: 'id',
                dbType: FieldType.serial,
                primaryKey: true,
                autoIncrement: true,
              ),
              ModelFieldSchema(name: 'name', columnName: 'name', dbType: FieldType.text),
              ModelFieldSchema(name: 'status', columnName: 'status', dbType: FieldType.varchar, index: true),
            ],
          );

          final operations = await generator.generateDiff(conn, [schema]);

          expect(operations.any((op) => op is CreateIndex), isTrue);
        });
      });

      test('generates AddForeignKey for new foreign key field', () async {
        await pool.withConnection((conn) async {
          // Create referenced table
          await conn.execute('''
            CREATE TABLE IF NOT EXISTS referenced_table (
              id INTEGER PRIMARY KEY AUTOINCREMENT
            )
          ''');

          // Create table without FK
          await conn.execute('''
            CREATE TABLE IF NOT EXISTS fk_table (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL
            )
          ''');

          // Model with a new FK column
          const schema = ModelSchema(
            className: 'FkTable',
            tableName: 'fk_table',
            fields: [
              ModelFieldSchema(
                name: 'id',
                columnName: 'id',
                dbType: FieldType.serial,
                primaryKey: true,
                autoIncrement: true,
              ),
              ModelFieldSchema(name: 'name', columnName: 'name', dbType: FieldType.text),
              ModelFieldSchema(
                name: 'refId',
                columnName: 'ref_id',
                dbType: FieldType.integer,
                foreignKey: ForeignKeyInfo(referencedTable: 'referenced_table'),
              ),
            ],
          );

          final operations = await generator.generateDiff(conn, [schema]);

          expect(operations.any((op) => op is AddForeignKey), isTrue);
        });
      });

      test('generates no operations for up-to-date table', () async {
        await pool.withConnection((conn) async {
          // Create table that matches schema
          await conn.execute('''
            CREATE TABLE IF NOT EXISTS matched_table (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              email TEXT
            )
          ''');

          // Model that matches the table
          const schema = ModelSchema(
            className: 'MatchedTable',
            tableName: 'matched_table',
            fields: [
              ModelFieldSchema(
                name: 'id',
                columnName: 'id',
                dbType: FieldType.serial,
                primaryKey: true,
                autoIncrement: true,
              ),
              ModelFieldSchema(name: 'name', columnName: 'name', dbType: FieldType.text),
              ModelFieldSchema(name: 'email', columnName: 'email', dbType: FieldType.text, nullable: true),
            ],
          );

          final operations = await generator.generateDiff(conn, [schema]);

          expect(operations, isEmpty);
        });
      });

      test('handles multiple models', () async {
        await pool.withConnection((conn) async {
          const schema1 = ModelSchema(
            className: 'Model1',
            tableName: 'model1',
            fields: [
              ModelFieldSchema(
                name: 'id',
                columnName: 'id',
                dbType: FieldType.serial,
                primaryKey: true,
                autoIncrement: true,
              ),
            ],
          );

          const schema2 = ModelSchema(
            className: 'Model2',
            tableName: 'model2',
            fields: [
              ModelFieldSchema(
                name: 'id',
                columnName: 'id',
                dbType: FieldType.serial,
                primaryKey: true,
                autoIncrement: true,
              ),
            ],
          );

          final operations = await generator.generateDiff(conn, [schema1, schema2]);

          // Both tables should be created
          final createTables = operations.whereType<CreateTable>().toList();
          expect(createTables.length, equals(2));
        });
      });

      test('generates AlterColumn for nullability change (non-nullable to nullable)', () async {
        await pool.withConnection((conn) async {
          // Create table with a NOT NULL column
          await conn.execute('''
            CREATE TABLE IF NOT EXISTS nullable_test (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL
            )
          ''');

          // Model with nullable=true for name
          const schema = ModelSchema(
            className: 'NullableTest',
            tableName: 'nullable_test',
            fields: [
              ModelFieldSchema(
                name: 'id',
                columnName: 'id',
                dbType: FieldType.serial,
                primaryKey: true,
                autoIncrement: true,
              ),
              ModelFieldSchema(name: 'name', columnName: 'name', dbType: FieldType.text, nullable: true),
            ],
          );

          final operations = await generator.generateDiff(conn, [schema]);

          expect(operations.any((op) => op is AlterColumn), isTrue);
          final alterColumn = operations.whereType<AlterColumn>().first;
          expect(alterColumn.modification.table, equals('nullable_test'));
          expect(alterColumn.modification.column, equals('name'));
          expect(alterColumn.modification.nullable, isTrue);
        });
      });

      test('generates AlterColumn for nullability change (nullable to non-nullable)', () async {
        await pool.withConnection((conn) async {
          // Create table with a nullable column (no NOT NULL)
          await conn.execute('''
            CREATE TABLE IF NOT EXISTS notnull_test (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              description TEXT
            )
          ''');

          // Model with nullable=false for description
          const schema = ModelSchema(
            className: 'NotNullTest',
            tableName: 'notnull_test',
            fields: [
              ModelFieldSchema(
                name: 'id',
                columnName: 'id',
                dbType: FieldType.serial,
                primaryKey: true,
                autoIncrement: true,
              ),
              ModelFieldSchema(name: 'description', columnName: 'description', dbType: FieldType.text, nullable: false),
            ],
          );

          final operations = await generator.generateDiff(conn, [schema]);

          expect(operations.any((op) => op is AlterColumn), isTrue);
          final alterColumn = operations.whereType<AlterColumn>().first;
          expect(alterColumn.modification.table, equals('notnull_test'));
          expect(alterColumn.modification.column, equals('description'));
          expect(alterColumn.modification.nullable, isFalse);
        });
      });

      test('does not generate AlterColumn for PK fields (SQLite quirk)', () async {
        await pool.withConnection((conn) async {
          // Create table - SQLite reports INTEGER PRIMARY KEY as nullable=true in PRAGMA
          await conn.execute('''
            CREATE TABLE IF NOT EXISTS pk_null_test (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL
            )
          ''');

          // Model with PK marked as non-nullable (which is correct)
          const schema = ModelSchema(
            className: 'PkNullTest',
            tableName: 'pk_null_test',
            fields: [
              ModelFieldSchema(
                name: 'id',
                columnName: 'id',
                dbType: FieldType.serial,
                primaryKey: true,
                autoIncrement: true,
                // nullable defaults to false
              ),
              ModelFieldSchema(name: 'name', columnName: 'name', dbType: FieldType.text),
            ],
          );

          final operations = await generator.generateDiff(conn, [schema]);

          // Should not detect a nullability change for PK
          expect(operations.whereType<AlterColumn>().isEmpty, isTrue);
        });
      });

      test('does not generate AlterColumn for SQLite TEXT type affinity (text to varchar)', () async {
        await pool.withConnection((conn) async {
          // Create table with TEXT column
          await conn.execute('''
            CREATE TABLE IF NOT EXISTS type_change_test (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              description TEXT NOT NULL
            )
          ''');

          // Model with VARCHAR type for description - equivalent in SQLite
          const schema = ModelSchema(
            className: 'TypeChangeTest',
            tableName: 'type_change_test',
            fields: [
              ModelFieldSchema(
                name: 'id',
                columnName: 'id',
                dbType: FieldType.serial,
                primaryKey: true,
                autoIncrement: true,
              ),
              ModelFieldSchema(
                  name: 'description', columnName: 'description', dbType: FieldType.varchar, maxLength: 500),
            ],
          );

          final operations = await generator.generateDiff(conn, [schema]);

          // TEXT and VARCHAR are equivalent in SQLite - no AlterColumn should be generated
          expect(operations.whereType<AlterColumn>().isEmpty, isTrue);
        });
      });

      test('does not generate AlterColumn for SQLite INTEGER type affinity (integer to bigint)', () async {
        await pool.withConnection((conn) async {
          // Create table with INTEGER column
          await conn.execute('''
            CREATE TABLE IF NOT EXISTS bigint_test (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              count INTEGER NOT NULL
            )
          ''');

          // Model with BIGINT type for count - equivalent in SQLite
          const schema = ModelSchema(
            className: 'BigIntTest',
            tableName: 'bigint_test',
            fields: [
              ModelFieldSchema(
                name: 'id',
                columnName: 'id',
                dbType: FieldType.serial,
                primaryKey: true,
                autoIncrement: true,
              ),
              ModelFieldSchema(name: 'count', columnName: 'count', dbType: FieldType.bigInt),
            ],
          );

          final operations = await generator.generateDiff(conn, [schema]);

          // INTEGER and BIGINT are equivalent in SQLite - no AlterColumn should be generated
          expect(operations.whereType<AlterColumn>().isEmpty, isTrue);
        });
      });

      test('does not generate AlterColumn when types match', () async {
        await pool.withConnection((conn) async {
          // Create table with TEXT column
          await conn.execute('''
            CREATE TABLE IF NOT EXISTS no_type_change_test (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              content TEXT NOT NULL
            )
          ''');

          // Model with TEXT type (same as DB)
          const schema = ModelSchema(
            className: 'NoTypeChangeTest',
            tableName: 'no_type_change_test',
            fields: [
              ModelFieldSchema(
                name: 'id',
                columnName: 'id',
                dbType: FieldType.serial,
                primaryKey: true,
                autoIncrement: true,
              ),
              ModelFieldSchema(name: 'content', columnName: 'content', dbType: FieldType.text),
            ],
          );

          final operations = await generator.generateDiff(conn, [schema]);

          // Should not detect a type change
          expect(operations.whereType<AlterColumn>().isEmpty, isTrue);
        });
      });

      test('does not generate AlterColumn for PK integer/serial mismatch', () async {
        await pool.withConnection((conn) async {
          // SQLite reports INTEGER PRIMARY KEY, model has serial
          await conn.execute('''
            CREATE TABLE IF NOT EXISTS pk_type_test (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL
            )
          ''');

          // Model with serial (should match INTEGER for PK)
          const schema = ModelSchema(
            className: 'PkTypeTest',
            tableName: 'pk_type_test',
            fields: [
              ModelFieldSchema(
                name: 'id',
                columnName: 'id',
                dbType: FieldType.serial,
                primaryKey: true,
                autoIncrement: true,
              ),
              ModelFieldSchema(name: 'name', columnName: 'name', dbType: FieldType.text),
            ],
          );

          final operations = await generator.generateDiff(conn, [schema]);

          // Should not detect a type change for PK integer/serial
          expect(operations.whereType<AlterColumn>().isEmpty, isTrue);
        });
      });

      test('does not generate AlterColumn for SQLite TEXT type affinity (timestamp vs text)', () async {
        await pool.withConnection((conn) async {
          // SQLite stores timestamps as TEXT
          await conn.execute('''
            CREATE TABLE IF NOT EXISTS timestamp_equiv_test (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              created_at TEXT NOT NULL
            )
          ''');

          // Model uses timestampTz, which SQLite reports as TEXT
          const schema = ModelSchema(
            className: 'TimestampEquivTest',
            tableName: 'timestamp_equiv_test',
            fields: [
              ModelFieldSchema(
                name: 'id',
                columnName: 'id',
                dbType: FieldType.serial,
                primaryKey: true,
                autoIncrement: true,
              ),
              ModelFieldSchema(name: 'createdAt', columnName: 'created_at', dbType: FieldType.timestampTz),
            ],
          );

          final operations = await generator.generateDiff(conn, [schema]);

          // Should not detect a type change - TEXT and timestampTz are equivalent in SQLite
          expect(operations.whereType<AlterColumn>().isEmpty, isTrue);
        });
      });

      test('does not generate AlterColumn for SQLite TEXT type affinity (uuid vs text)', () async {
        await pool.withConnection((conn) async {
          // SQLite stores UUIDs as TEXT
          await conn.execute('''
            CREATE TABLE IF NOT EXISTS uuid_equiv_test (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              uuid TEXT NOT NULL
            )
          ''');

          // Model uses UUID, which SQLite reports as TEXT
          const schema = ModelSchema(
            className: 'UuidEquivTest',
            tableName: 'uuid_equiv_test',
            fields: [
              ModelFieldSchema(
                name: 'id',
                columnName: 'id',
                dbType: FieldType.serial,
                primaryKey: true,
                autoIncrement: true,
              ),
              ModelFieldSchema(name: 'uuid', columnName: 'uuid', dbType: FieldType.uuid),
            ],
          );

          final operations = await generator.generateDiff(conn, [schema]);

          // Should not detect a type change - TEXT and uuid are equivalent in SQLite
          expect(operations.whereType<AlterColumn>().isEmpty, isTrue);
        });
      });

      test('does not generate AlterColumn for SQLite TEXT type affinity (json vs text)', () async {
        await pool.withConnection((conn) async {
          // SQLite stores JSON as TEXT
          await conn.execute('''
            CREATE TABLE IF NOT EXISTS json_equiv_test (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              data TEXT
            )
          ''');

          // Model uses JSON, which SQLite reports as TEXT
          const schema = ModelSchema(
            className: 'JsonEquivTest',
            tableName: 'json_equiv_test',
            fields: [
              ModelFieldSchema(
                name: 'id',
                columnName: 'id',
                dbType: FieldType.serial,
                primaryKey: true,
                autoIncrement: true,
              ),
              ModelFieldSchema(name: 'data', columnName: 'data', dbType: FieldType.jsonb, nullable: true),
            ],
          );

          final operations = await generator.generateDiff(conn, [schema]);

          // Should not detect a type change - TEXT and jsonb are equivalent in SQLite
          expect(operations.whereType<AlterColumn>().isEmpty, isTrue);
        });
      });

      test('does not generate AlterColumn for SQLite INTEGER type affinity (boolean vs integer)', () async {
        await pool.withConnection((conn) async {
          // SQLite stores booleans as INTEGER
          await conn.execute('''
            CREATE TABLE IF NOT EXISTS bool_equiv_test (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              is_active INTEGER NOT NULL
            )
          ''');

          // Model uses boolean, which SQLite reports as INTEGER
          const schema = ModelSchema(
            className: 'BoolEquivTest',
            tableName: 'bool_equiv_test',
            fields: [
              ModelFieldSchema(
                name: 'id',
                columnName: 'id',
                dbType: FieldType.serial,
                primaryKey: true,
                autoIncrement: true,
              ),
              ModelFieldSchema(name: 'isActive', columnName: 'is_active', dbType: FieldType.boolean),
            ],
          );

          final operations = await generator.generateDiff(conn, [schema]);

          // Should not detect a type change - INTEGER and boolean are equivalent in SQLite
          expect(operations.whereType<AlterColumn>().isEmpty, isTrue);
        });
      });

      test('does not generate AlterColumn for SQLite REAL type affinity (decimal vs real)', () async {
        await pool.withConnection((conn) async {
          // SQLite stores decimals as REAL
          await conn.execute('''
            CREATE TABLE IF NOT EXISTS decimal_equiv_test (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              price REAL NOT NULL
            )
          ''');

          // Model uses decimal, which SQLite reports as REAL
          const schema = ModelSchema(
            className: 'DecimalEquivTest',
            tableName: 'decimal_equiv_test',
            fields: [
              ModelFieldSchema(
                name: 'id',
                columnName: 'id',
                dbType: FieldType.serial,
                primaryKey: true,
                autoIncrement: true,
              ),
              ModelFieldSchema(
                name: 'price',
                columnName: 'price',
                dbType: FieldType.decimal,
                precision: 10,
                scale: 2,
              ),
            ],
          );

          final operations = await generator.generateDiff(conn, [schema]);

          // Should not detect a type change - REAL and decimal are equivalent in SQLite
          expect(operations.whereType<AlterColumn>().isEmpty, isTrue);
        });
      });

      test('detects missing default value on existing column', () async {
        await pool.withConnection((conn) async {
          await conn.execute('''
            CREATE TABLE IF NOT EXISTS default_test (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              status TEXT NOT NULL
            )
          ''');

          const schema = ModelSchema(
            className: 'DefaultTest',
            tableName: 'default_test',
            fields: [
              ModelFieldSchema(
                name: 'id',
                columnName: 'id',
                dbType: FieldType.serial,
                primaryKey: true,
                autoIncrement: true,
              ),
              ModelFieldSchema(
                name: 'status',
                columnName: 'status',
                dbType: FieldType.text,
                defaultValue: 'active',
              ),
            ],
          );

          final operations = await generator.generateDiff(conn, [schema]);

          final alterOps = operations.whereType<AlterColumn>().toList();
          expect(alterOps.isNotEmpty, isTrue, reason: 'Should detect missing default value');
          expect(alterOps.any((op) => op.modification.defaultValue == 'active'), isTrue);
        });
      });

      test('detects missing unique constraint on existing column', () async {
        await pool.withConnection((conn) async {
          await conn.execute('''
            CREATE TABLE IF NOT EXISTS unique_test (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              email TEXT NOT NULL
            )
          ''');

          const schema = ModelSchema(
            className: 'UniqueTest',
            tableName: 'unique_test',
            fields: [
              ModelFieldSchema(
                name: 'id',
                columnName: 'id',
                dbType: FieldType.serial,
                primaryKey: true,
                autoIncrement: true,
              ),
              ModelFieldSchema(
                name: 'email',
                columnName: 'email',
                dbType: FieldType.text,
                unique: true,
              ),
            ],
          );

          final operations = await generator.generateDiff(conn, [schema]);

          final indexOps = operations.whereType<CreateIndex>().toList();
          expect(indexOps.isNotEmpty, isTrue, reason: 'Should detect missing unique constraint');
          expect(indexOps.any((op) => op.index.unique && op.index.columns.contains('email')), isTrue);
        });
      });

      test('does not add unique constraint if already exists', () async {
        await pool.withConnection((conn) async {
          await conn.execute('''
            CREATE TABLE IF NOT EXISTS unique_exists_test (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              email TEXT NOT NULL UNIQUE
            )
          ''');

          const schema = ModelSchema(
            className: 'UniqueExistsTest',
            tableName: 'unique_exists_test',
            fields: [
              ModelFieldSchema(
                name: 'id',
                columnName: 'id',
                dbType: FieldType.serial,
                primaryKey: true,
                autoIncrement: true,
              ),
              ModelFieldSchema(
                name: 'email',
                columnName: 'email',
                dbType: FieldType.text,
                unique: true,
              ),
            ],
          );

          final operations = await generator.generateDiff(conn, [schema]);

          final indexOps = operations.whereType<CreateIndex>().toList();
          expect(indexOps.isEmpty, isTrue, reason: 'Should not add unique constraint if already present');
        });
      });

      test('detects missing foreign key constraint on existing column', () async {
        await pool.withConnection((conn) async {
          await conn.execute('''
            CREATE TABLE IF NOT EXISTS fk_parent (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL
            )
          ''');
          await conn.execute('''
            CREATE TABLE IF NOT EXISTS fk_child (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              parent_id INTEGER NOT NULL
            )
          ''');

          const schema = ModelSchema(
            className: 'FkChild',
            tableName: 'fk_child',
            fields: [
              ModelFieldSchema(
                name: 'id',
                columnName: 'id',
                dbType: FieldType.serial,
                primaryKey: true,
                autoIncrement: true,
              ),
              ModelFieldSchema(
                name: 'parentId',
                columnName: 'parent_id',
                dbType: FieldType.integer,
                foreignKey: ForeignKeyInfo(
                  referencedTable: 'fk_parent',
                  referencedColumn: 'id',
                  onDelete: OnDeleteAction.cascade,
                ),
              ),
            ],
          );

          final operations = await generator.generateDiff(conn, [schema]);

          final fkOps = operations.whereType<AddForeignKey>().toList();
          expect(fkOps.isNotEmpty, isTrue, reason: 'Should detect missing foreign key');
          expect(fkOps.first.foreignKey.referencedTable, equals('fk_parent'));
          expect(fkOps.first.foreignKey.onDelete, equals(OnDeleteAction.cascade));
        });
      });

      test('generates drop default when model removes default value', () async {
        await pool.withConnection((conn) async {
          await conn.execute('''
            CREATE TABLE IF NOT EXISTS drop_default_test (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              status TEXT NOT NULL DEFAULT 'pending'
            )
          ''');

          const schema = ModelSchema(
            className: 'DropDefaultTest',
            tableName: 'drop_default_test',
            fields: [
              ModelFieldSchema(
                name: 'id',
                columnName: 'id',
                dbType: FieldType.serial,
                primaryKey: true,
                autoIncrement: true,
              ),
              ModelFieldSchema(
                name: 'status',
                columnName: 'status',
                dbType: FieldType.text,
                // no defaultValue — model removed it
              ),
            ],
          );

          final operations = await generator.generateDiff(conn, [schema]);

          final alterOps = operations.whereType<AlterColumn>().toList();
          expect(alterOps.isNotEmpty, isTrue, reason: 'Should detect removed default value');
          expect(alterOps.any((op) => op.modification.dropDefault), isTrue, reason: 'Should generate DROP DEFAULT');
        });
      });

      test('does not add foreign key if already exists', () async {
        await pool.withConnection((conn) async {
          await conn.execute('''
            CREATE TABLE IF NOT EXISTS fk_exists_parent (
              id INTEGER PRIMARY KEY AUTOINCREMENT
            )
          ''');
          await conn.execute('''
            CREATE TABLE IF NOT EXISTS fk_exists_child (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              parent_id INTEGER NOT NULL REFERENCES fk_exists_parent(id)
            )
          ''');

          const schema = ModelSchema(
            className: 'FkExistsChild',
            tableName: 'fk_exists_child',
            fields: [
              ModelFieldSchema(
                name: 'id',
                columnName: 'id',
                dbType: FieldType.serial,
                primaryKey: true,
                autoIncrement: true,
              ),
              ModelFieldSchema(
                name: 'parentId',
                columnName: 'parent_id',
                dbType: FieldType.integer,
                foreignKey: ForeignKeyInfo(
                  referencedTable: 'fk_exists_parent',
                  referencedColumn: 'id',
                ),
              ),
            ],
          );

          final operations = await generator.generateDiff(conn, [schema]);

          final fkOps = operations.whereType<AddForeignKey>().toList();
          expect(fkOps.isEmpty, isTrue, reason: 'Should not add FK if already present');
        });
      });

      test('detects changed default value on existing column', () async {
        await pool.withConnection((conn) async {
          await conn.execute('''
            CREATE TABLE IF NOT EXISTS changed_default_test (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              priority INTEGER NOT NULL DEFAULT 0
            )
          ''');

          const schema = ModelSchema(
            className: 'ChangedDefaultTest',
            tableName: 'changed_default_test',
            fields: [
              ModelFieldSchema(
                name: 'id',
                columnName: 'id',
                dbType: FieldType.serial,
                primaryKey: true,
                autoIncrement: true,
              ),
              ModelFieldSchema(
                name: 'priority',
                columnName: 'priority',
                dbType: FieldType.integer,
                defaultValue: 5,
              ),
            ],
          );

          final operations = await generator.generateDiff(conn, [schema]);

          final alterOps = operations.whereType<AlterColumn>().toList();
          expect(alterOps.isNotEmpty, isTrue, reason: 'Should detect changed default value');
          expect(alterOps.any((op) => op.modification.defaultValue == '5'), isTrue);
        });
      });

      test('does not add default value if already matches', () async {
        await pool.withConnection((conn) async {
          await conn.execute('''
            CREATE TABLE IF NOT EXISTS default_match_test (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              active INTEGER NOT NULL DEFAULT 0
            )
          ''');

          const schema = ModelSchema(
            className: 'DefaultMatchTest',
            tableName: 'default_match_test',
            fields: [
              ModelFieldSchema(
                name: 'id',
                columnName: 'id',
                dbType: FieldType.serial,
                primaryKey: true,
                autoIncrement: true,
              ),
              ModelFieldSchema(
                name: 'active',
                columnName: 'active',
                dbType: FieldType.integer,
                defaultValue: 0,
              ),
            ],
          );

          final operations = await generator.generateDiff(conn, [schema]);

          final alterOps = operations.whereType<AlterColumn>().where((op) => op.modification.column == 'active');
          expect(alterOps.isEmpty, isTrue, reason: 'Should not alter column when default value already matches');
        });
      });
    });

    group('generateMigrationFile()', () {
      test('generates valid Dart migration file', () {
        final operations = [
          CreateTable(
            TableDefinition(
              name: 'users',
              columns: [
                const ColumnDefinition(name: 'id', type: FieldType.serial, primaryKey: true),
                const ColumnDefinition(name: 'name', type: FieldType.varchar, length: 100),
              ],
            ),
          ),
        ];

        final content = generator.generateMigrationFile('CreateUsersTable', operations);

        expect(content, contains("import 'package:jao/jao.dart';"));
        expect(content, contains('class CreateUsersTable extends Migration'));
        expect(content, contains("String get name => 'create_users_table'"));
        expect(content, contains('void up(MigrationBuilder builder)'));
        expect(content, contains('void down(MigrationBuilder builder)'));
        expect(content, contains("builder.createTable('users'"));
        expect(content, contains("builder.dropTable('users')"));
      });

      test('generates migration with multiple operations', () {
        final operations = [
          CreateTable(
            TableDefinition(
              name: 'posts',
              columns: [
                const ColumnDefinition(name: 'id', type: FieldType.serial, primaryKey: true),
                const ColumnDefinition(name: 'title', type: FieldType.varchar, length: 200),
              ],
            ),
          ),
          const CreateIndex('posts', IndexDefinition(name: 'idx_posts_title', columns: ['title'])),
        ];

        final content = generator.generateMigrationFile('CreatePostsTable', operations);

        expect(content, contains("builder.createTable('posts'"));
        expect(content, contains("builder.createIndex('posts'"));
        expect(content, contains("builder.dropIndex('idx_posts_title')"));
      });

      test('generates reverse operations for CreateTable', () {
        final operations = [
          CreateTable(
            TableDefinition(
              name: 'categories',
              columns: [const ColumnDefinition(name: 'id', type: FieldType.serial, primaryKey: true)],
            ),
          ),
        ];

        final content = generator.generateMigrationFile('CreateCategories', operations);

        expect(content, contains("builder.dropTable('categories')"));
      });

      test('generates reverse operations for AddColumn', () {
        final operations = [const AddColumn('users', ColumnDefinition(name: 'email', type: FieldType.varchar))];

        final content = generator.generateMigrationFile('AddEmailToUsers', operations);

        expect(content, contains("builder.addColumn('users', 'email'"));
        expect(content, contains("builder.dropColumn('users', 'email')"));
      });

      test('generates reverse operations for CreateIndex', () {
        final operations = [
          const CreateIndex('users', IndexDefinition(name: 'idx_users_email', columns: ['email'], unique: true)),
        ];

        final content = generator.generateMigrationFile('AddEmailIndex', operations);

        expect(content, contains("builder.createIndex('users', ['email'], unique: true)"));
        expect(content, contains("builder.dropIndex('idx_users_email')"));
      });

      test('generates reverse for AlterColumn nullability change', () {
        const operations = [
          AlterColumn(ColumnModification(table: 'users', column: 'name', nullable: true)),
        ];

        final content = generator.generateMigrationFile('MakeNameNullable', operations);

        expect(content, contains('col.notNullable()'));
      });

      test('generates reverse for AlterColumn type change with previousType', () {
        const operations = [
          AlterColumn(ColumnModification(
            table: 'users',
            column: 'age',
            type: FieldType.bigInt,
            previousType: FieldType.integer,
          )),
        ];

        final content = generator.generateMigrationFile('ChangeAgeType', operations);

        expect(content, contains('col.type(FieldType.integer)'));
      });

      test('generates reverse for AlterColumn default value change with previousDefault', () {
        const operations = [
          AlterColumn(ColumnModification(
            table: 'users',
            column: 'status',
            defaultValue: 'active',
            previousDefault: 'pending',
          )),
        ];

        final content = generator.generateMigrationFile('ChangeStatusDefault', operations);

        expect(content, contains("col.defaultValue('pending')"));
      });

      test('generates reverse for AlterColumn drop default with previousDefault', () {
        const operations = [
          AlterColumn(ColumnModification(
            table: 'users',
            column: 'status',
            dropDefault: true,
            previousDefault: 'active',
          )),
        ];

        final content = generator.generateMigrationFile('DropStatusDefault', operations);

        expect(content, contains("col.defaultValue('active')"));
      });

      test('generates reverse for AlterColumn rename', () {
        const operations = [
          AlterColumn(ColumnModification(table: 'users', column: 'name', rename: 'full_name')),
        ];

        final content = generator.generateMigrationFile('RenameName', operations);

        expect(content, contains("builder.renameColumn('users', 'full_name', 'name')"));
      });

      test('generates comment when AlterColumn has no previous state', () {
        const operations = [
          AlterColumn(ColumnModification(table: 'users', column: 'age', type: FieldType.bigInt)),
        ];

        final content = generator.generateMigrationFile('ChangeAge', operations);

        expect(content, contains('Cannot auto-reverse AlterColumn'));
      });

      test('converts PascalCase to snake_case for migration name', () {
        final content = generator.generateMigrationFile('CreateUserRolesTable', []);

        expect(content, contains("String get name => 'create_user_roles_table'"));
      });

      test('generates timestampTz column with useCurrent', () {
        final operations = [
          CreateTable(
            TableDefinition(
              name: 'logs',
              columns: [
                const ColumnDefinition(name: 'id', type: FieldType.serial, primaryKey: true),
                const ColumnDefinition(
                  name: 'created_at',
                  type: FieldType.timestampTz,
                  defaultValue: 'CURRENT_TIMESTAMP',
                ),
              ],
            ),
          ),
        ];

        final content = generator.generateMigrationFile('CreateLogsTable', operations);

        expect(content, contains('useCurrent: true'));
      });

      test('generates DropTable operation', () {
        final operations = [const DropTable('old_table')];

        final content = generator.generateMigrationFile('DropOldTable', operations);

        expect(content, contains("builder.dropTable('old_table')"));
      });

      test('generates RenameTable operation', () {
        final operations = [const RenameTable('old_name', 'new_name')];

        final content = generator.generateMigrationFile('RenameOldTable', operations);

        expect(content, contains("builder.renameTable('old_name', 'new_name')"));
        // Reverse should swap the names
        expect(content, contains("builder.renameTable('new_name', 'old_name')"));
      });

      test('generates DropColumn operation', () {
        final operations = [const DropColumn('users', 'deprecated_field')];

        final content = generator.generateMigrationFile('DropDeprecatedField', operations);

        expect(content, contains("builder.dropColumn('users', 'deprecated_field')"));
      });

      test('generates RenameColumn operation', () {
        final operations = [const RenameColumn('users', 'old_col', 'new_col')];

        final content = generator.generateMigrationFile('RenameUserColumn', operations);

        expect(content, contains("builder.renameColumn('users', 'old_col', 'new_col')"));
        // Reverse should swap the names
        expect(content, contains("builder.renameColumn('users', 'new_col', 'old_col')"));
      });

      test('generates AlterColumn with nullable change', () {
        final operations = [
          AlterColumn(ColumnModification(table: 'users', column: 'bio', nullable: true)),
        ];

        final content = generator.generateMigrationFile('MakeBioNullable', operations);

        expect(content, contains("builder.alterColumn('users', 'bio', (col) {"));
        expect(content, contains('col.nullable();'));
        // Reverse should use notNullable
        expect(content, contains('col.notNullable();'));
      });

      test('generates AlterColumn with notNullable change', () {
        final operations = [
          AlterColumn(ColumnModification(table: 'users', column: 'email', nullable: false)),
        ];

        final content = generator.generateMigrationFile('MakeEmailRequired', operations);

        expect(content, contains("builder.alterColumn('users', 'email', (col) {"));
        expect(content, contains('col.notNullable();'));
        // Reverse should use nullable
        expect(content, contains('col.nullable();'));
      });

      test('generates AlterColumn with type change', () {
        final operations = [
          AlterColumn(ColumnModification(table: 'products', column: 'price', type: FieldType.decimal)),
        ];

        final content = generator.generateMigrationFile('ChangePrice', operations);

        expect(content, contains("builder.alterColumn('products', 'price', (col) {"));
        expect(content, contains('col.type(FieldType.decimal)'));
      });

      test('generates AlterColumn with default value', () {
        final operations = [
          AlterColumn(ColumnModification(table: 'settings', column: 'is_active', defaultValue: 'true')),
        ];

        final content = generator.generateMigrationFile('SetDefaultActive', operations);

        expect(content, contains("builder.alterColumn('settings', 'is_active', (col) {"));
        expect(content, contains("col.defaultValue('true')"));
      });

      test('generates AlterColumn with drop default', () {
        final operations = [
          AlterColumn(ColumnModification(table: 'settings', column: 'theme', dropDefault: true)),
        ];

        final content = generator.generateMigrationFile('DropThemeDefault', operations);

        expect(content, contains("builder.alterColumn('settings', 'theme', (col) {"));
        expect(content, contains('col.dropDefault()'));
      });

      test('generates AlterColumn with rename', () {
        final operations = [
          AlterColumn(ColumnModification(table: 'users', column: 'name', rename: 'full_name')),
        ];

        final content = generator.generateMigrationFile('RenameNameColumn', operations);

        expect(content, contains("builder.alterColumn('users', 'name', (col) {"));
        expect(content, contains("col.renameTo('full_name')"));
      });

      test('generates DropIndex operation', () {
        final operations = [const DropIndex('idx_users_email')];

        final content = generator.generateMigrationFile('DropEmailIndex', operations);

        expect(content, contains("builder.dropIndex('idx_users_email')"));
      });

      test('generates AddForeignKey operation', () {
        final operations = [
          const AddForeignKey(
            'posts',
            ForeignKeyDefinition(
              column: 'author_id',
              referencedTable: 'users',
              referencedColumn: 'id',
            ),
          ),
        ];

        final content = generator.generateMigrationFile('AddAuthorFK', operations);

        expect(content, contains("builder.addForeignKey('posts', 'author_id', 'users', referencedColumn: 'id')"));
        // Reverse should drop the constraint
        expect(content, contains("builder.dropConstraint('posts', 'fk_posts_author_id')"));
      });

      test('generates DropConstraint operation', () {
        final operations = [const DropConstraint('orders', 'fk_orders_user_id')];

        final content = generator.generateMigrationFile('DropUserFK', operations);

        expect(content, contains("builder.dropConstraint('orders', 'fk_orders_user_id')"));
      });

      test('generates RawSql operation', () {
        final operations = [const RawSql('CREATE EXTENSION IF NOT EXISTS "uuid-ossp"')];

        final content = generator.generateMigrationFile('AddUuidExtension', operations);

        expect(content, contains("builder.raw('CREATE EXTENSION IF NOT EXISTS"));
      });

      test('generates RawSql with reverse', () {
        final operations = [
          const RawSql(
            'CREATE MATERIALIZED VIEW stats AS SELECT COUNT(*) FROM users',
            reverseSql: 'DROP MATERIALIZED VIEW stats',
          ),
        ];

        final content = generator.generateMigrationFile('CreateStatsView', operations);

        expect(content, contains('CREATE MATERIALIZED VIEW stats'));
        expect(content, contains('DROP MATERIALIZED VIEW stats'));
      });

      test('generates RunDart operation', () {
        final operations = [
          RunDart((conn) async {
            // Migrate data
          }),
        ];

        final content = generator.generateMigrationFile('MigrateData', operations);

        expect(content, contains('// RunDart operation - implement manually'));
      });

      test('generates nullable column', () {
        final operations = [
          CreateTable(
            TableDefinition(
              name: 'profiles',
              columns: [
                const ColumnDefinition(name: 'id', type: FieldType.serial, primaryKey: true),
                const ColumnDefinition(name: 'bio', type: FieldType.text, nullable: true),
              ],
            ),
          ),
        ];

        final content = generator.generateMigrationFile('CreateProfilesTable', operations);

        expect(content, contains('nullable: true'));
      });

      test('generates bigId column', () {
        final operations = [
          CreateTable(
            TableDefinition(
              name: 'events',
              columns: [const ColumnDefinition(name: 'id', type: FieldType.bigSerial, primaryKey: true)],
            ),
          ),
        ];

        final content = generator.generateMigrationFile('CreateEventsTable', operations);

        expect(content, contains("table.bigId('id')"));
      });

      test('generates boolean column with default', () {
        final operations = [
          CreateTable(
            TableDefinition(
              name: 'settings',
              columns: [
                const ColumnDefinition(name: 'id', type: FieldType.serial, primaryKey: true),
                const ColumnDefinition(name: 'is_enabled', type: FieldType.boolean, defaultValue: 'true'),
              ],
            ),
          ),
        ];

        final content = generator.generateMigrationFile('CreateSettingsTable', operations);

        expect(content, contains("table.boolean('is_enabled'"));
        expect(content, contains("defaultValue: 'true'"));
      });
    });
  });

  group('fieldDefToDbType()', () {
    test('AutoField maps to serial', () {
      expect(fieldDefToDbType(const AutoField()), equals(FieldType.serial));
    });

    test('BigAutoField maps to bigSerial', () {
      expect(fieldDefToDbType(const BigAutoField()), equals(FieldType.bigSerial));
    });

    test('CharField maps to varchar', () {
      expect(fieldDefToDbType(const CharField(maxLength: 100)), equals(FieldType.varchar));
    });

    test('EmailField maps to varchar', () {
      expect(fieldDefToDbType(const EmailField()), equals(FieldType.varchar));
    });

    test('UrlField maps to varchar', () {
      expect(fieldDefToDbType(const UrlField()), equals(FieldType.varchar));
    });

    test('TextField maps to text', () {
      expect(fieldDefToDbType(const TextField()), equals(FieldType.text));
    });

    test('IntegerField maps to integer', () {
      expect(fieldDefToDbType(const IntegerField()), equals(FieldType.integer));
    });

    test('SmallIntegerField maps to smallInt', () {
      expect(fieldDefToDbType(const SmallIntegerField()), equals(FieldType.smallInt));
    });

    test('BigIntegerField maps to bigInt', () {
      expect(fieldDefToDbType(const BigIntegerField()), equals(FieldType.bigInt));
    });

    test('PositiveIntegerField maps to integer', () {
      expect(fieldDefToDbType(const PositiveIntegerField()), equals(FieldType.integer));
    });

    test('FloatField maps to real', () {
      expect(fieldDefToDbType(const FloatField()), equals(FieldType.real));
    });

    test('DecimalField maps to decimal', () {
      expect(fieldDefToDbType(const DecimalField(maxDigits: 10, decimalPlaces: 2)), equals(FieldType.decimal));
    });

    test('BooleanField maps to boolean', () {
      expect(fieldDefToDbType(const BooleanField()), equals(FieldType.boolean));
    });

    test('DateField maps to date', () {
      expect(fieldDefToDbType(const DateField()), equals(FieldType.date));
    });

    test('DateTimeField maps to timestampTz', () {
      expect(fieldDefToDbType(const DateTimeField()), equals(FieldType.timestampTz));
    });

    test('TimeField maps to time', () {
      expect(fieldDefToDbType(const TimeField()), equals(FieldType.time));
    });

    test('DurationField maps to interval', () {
      expect(fieldDefToDbType(const DurationField()), equals(FieldType.interval));
    });

    test('BinaryField maps to bytea', () {
      expect(fieldDefToDbType(const BinaryField()), equals(FieldType.bytea));
    });

    test('UuidField maps to uuid', () {
      expect(fieldDefToDbType(const UuidField()), equals(FieldType.uuid));
    });

    test('JsonField maps to jsonb', () {
      expect(fieldDefToDbType(const JsonField()), equals(FieldType.jsonb));
    });

    test('ForeignKey maps to integer', () {
      expect(fieldDefToDbType(const ForeignKey(Object)), equals(FieldType.integer));
    });

    test('OneToOneField maps to integer', () {
      expect(fieldDefToDbType(const OneToOneField(Object)), equals(FieldType.integer));
    });

    test('EnumField maps to varchar (string storage)', () {
      expect(fieldDefToDbType(const EnumField<TestEnum>()), equals(FieldType.varchar));
    });

    test('EnumField with storeAsInt maps to integer', () {
      expect(fieldDefToDbType(const EnumField<TestEnum>(storeAsInt: true)), equals(FieldType.integer));
    });
  });

  group('SchemaGenerator additional field types', () {
    late SchemaGenerator generator;

    setUp(() {
      generator = SchemaGenerator(const SqliteAdapter());
    });

    test('generates CreateTable with doublePrecision field', () {
      const schema = ModelSchema(
        className: 'Scientific',
        tableName: 'scientific_data',
        fields: [
          ModelFieldSchema(
            name: 'id',
            columnName: 'id',
            dbType: FieldType.serial,
            primaryKey: true,
            autoIncrement: true,
          ),
          ModelFieldSchema(
            name: 'value',
            columnName: 'value',
            dbType: FieldType.doublePrecision,
            nullable: true,
            defaultValue: 3.14159,
          ),
        ],
      );

      final operations = generator.generateCreateTable(schema);

      expect(operations.length, equals(1));
      final createTable = operations[0] as CreateTable;
      final valueCol = createTable.table.columns.firstWhere((c) => c.name == 'value');
      expect(valueCol.type, equals(FieldType.doublePrecision));
    });

    test('generates CreateTable with blob field', () {
      const schema = ModelSchema(
        className: 'FileStorage',
        tableName: 'file_storage',
        fields: [
          ModelFieldSchema(
            name: 'id',
            columnName: 'id',
            dbType: FieldType.serial,
            primaryKey: true,
            autoIncrement: true,
          ),
          ModelFieldSchema(name: 'data', columnName: 'data', dbType: FieldType.blob, nullable: true),
        ],
      );

      final operations = generator.generateCreateTable(schema);

      expect(operations.length, equals(1));
      final createTable = operations[0] as CreateTable;
      expect(createTable.table.columns.any((c) => c.name == 'data'), isTrue);
    });

    test('generates CreateTable with unknown field type (falls back to text)', () {
      const schema = ModelSchema(
        className: 'Unknown',
        tableName: 'unknown_types',
        fields: [
          ModelFieldSchema(
            name: 'id',
            columnName: 'id',
            dbType: FieldType.serial,
            primaryKey: true,
            autoIncrement: true,
          ),
          // array is a less commonly used type that might hit the default case
          ModelFieldSchema(name: 'tags', columnName: 'tags', dbType: FieldType.array, nullable: true),
        ],
      );

      final operations = generator.generateCreateTable(schema);

      expect(operations.length, equals(1));
      final createTable = operations[0] as CreateTable;
      expect(createTable.table.columns.any((c) => c.name == 'tags'), isTrue);
    });

    test('generates CreateTable with smallInt field (uses integer builder)', () {
      const schema = ModelSchema(
        className: 'SmallNumbers',
        tableName: 'small_numbers',
        fields: [
          ModelFieldSchema(
            name: 'id',
            columnName: 'id',
            dbType: FieldType.serial,
            primaryKey: true,
            autoIncrement: true,
          ),
          ModelFieldSchema(name: 'count', columnName: 'count', dbType: FieldType.smallInt),
        ],
      );

      final operations = generator.generateCreateTable(schema);

      expect(operations.length, equals(1));
      final createTable = operations[0] as CreateTable;
      final countCol = createTable.table.columns.firstWhere((c) => c.name == 'count');
      // Note: SchemaGenerator uses integer builder for smallInt, bigInt, and integer types
      expect(countCol.type, equals(FieldType.integer));
    });
  });

  group('generateMigrationFile code generation', () {
    late SchemaGenerator generator;

    setUp(() {
      generator = SchemaGenerator(const SqliteAdapter());
    });

    test('generates code for DropConstraint operation', () {
      final operations = [const DropConstraint('posts', 'fk_posts_author')];

      final code = generator.generateMigrationFile('DropFkMigration', operations);

      expect(code, contains("builder.dropConstraint('posts', 'fk_posts_author')"));
    });
  });

  group('_normalizeDbType type affinity tests', () {
    late SchemaGenerator generator;
    late SqliteAdapter adapter;
    late ConnectionPool pool;

    setUpAll(() async {
      adapter = const SqliteAdapter();
      final config = DatabaseConfig.sqliteMemory();
      pool = await adapter.createPool(config);
      generator = SchemaGenerator(adapter);
    });

    tearDownAll(() async {
      await pool.close();
    });

    test('handles DOUBLE PRECISION type from database', () async {
      await pool.withConnection((conn) async {
        await conn.execute('''
          CREATE TABLE IF NOT EXISTS double_precision_test (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            value DOUBLE PRECISION NOT NULL
          )
        ''');

        const schema = ModelSchema(
          className: 'DoublePrecisionTest',
          tableName: 'double_precision_test',
          fields: [
            ModelFieldSchema(
              name: 'id',
              columnName: 'id',
              dbType: FieldType.serial,
              primaryKey: true,
              autoIncrement: true,
            ),
            ModelFieldSchema(name: 'value', columnName: 'value', dbType: FieldType.doublePrecision),
          ],
        );

        final operations = await generator.generateDiff(conn, [schema]);
        // SQLite stores DOUBLE PRECISION as REAL, so doublePrecision and real are equivalent
        expect(operations.whereType<AlterColumn>().isEmpty, isTrue);
      });
    });

    test('handles DECIMAL/NUMERIC type from database', () async {
      await pool.withConnection((conn) async {
        await conn.execute('''
          CREATE TABLE IF NOT EXISTS decimal_normalize_test (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            amount DECIMAL(10, 2) NOT NULL
          )
        ''');

        const schema = ModelSchema(
          className: 'DecimalNormalizeTest',
          tableName: 'decimal_normalize_test',
          fields: [
            ModelFieldSchema(
              name: 'id',
              columnName: 'id',
              dbType: FieldType.serial,
              primaryKey: true,
              autoIncrement: true,
            ),
            ModelFieldSchema(name: 'amount', columnName: 'amount', dbType: FieldType.decimal, precision: 10, scale: 2),
          ],
        );

        final operations = await generator.generateDiff(conn, [schema]);
        // SQLite stores DECIMAL as REAL, so they're equivalent
        expect(operations.whereType<AlterColumn>().isEmpty, isTrue);
      });
    });

    test('handles CHAR type from database', () async {
      await pool.withConnection((conn) async {
        await conn.execute('''
          CREATE TABLE IF NOT EXISTS char_test (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code CHAR(10) NOT NULL
          )
        ''');

        const schema = ModelSchema(
          className: 'CharTest',
          tableName: 'char_test',
          fields: [
            ModelFieldSchema(
              name: 'id',
              columnName: 'id',
              dbType: FieldType.serial,
              primaryKey: true,
              autoIncrement: true,
            ),
            ModelFieldSchema(name: 'code', columnName: 'code', dbType: FieldType.char),
          ],
        );

        final operations = await generator.generateDiff(conn, [schema]);
        // SQLite stores CHAR as TEXT, so they're equivalent
        expect(operations.whereType<AlterColumn>().isEmpty, isTrue);
      });
    });

    test('handles BLOB type from database', () async {
      await pool.withConnection((conn) async {
        await conn.execute('''
          CREATE TABLE IF NOT EXISTS blob_normalize_test (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            data BLOB
          )
        ''');

        const schema = ModelSchema(
          className: 'BlobNormalizeTest',
          tableName: 'blob_normalize_test',
          fields: [
            ModelFieldSchema(
              name: 'id',
              columnName: 'id',
              dbType: FieldType.serial,
              primaryKey: true,
              autoIncrement: true,
            ),
            ModelFieldSchema(name: 'data', columnName: 'data', dbType: FieldType.bytea, nullable: true),
          ],
        );

        final operations = await generator.generateDiff(conn, [schema]);
        // SQLite stores BYTEA as BLOB, so they're equivalent
        expect(operations.whereType<AlterColumn>().isEmpty, isTrue);
      });
    });

    test('handles SMALLINT type from database', () async {
      await pool.withConnection((conn) async {
        await conn.execute('''
          CREATE TABLE IF NOT EXISTS smallint_test (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            num SMALLINT NOT NULL
          )
        ''');

        const schema = ModelSchema(
          className: 'SmallIntTest',
          tableName: 'smallint_test',
          fields: [
            ModelFieldSchema(
              name: 'id',
              columnName: 'id',
              dbType: FieldType.serial,
              primaryKey: true,
              autoIncrement: true,
            ),
            ModelFieldSchema(name: 'num', columnName: 'num', dbType: FieldType.smallInt),
          ],
        );

        final operations = await generator.generateDiff(conn, [schema]);
        // INTEGER and SMALLINT are equivalent in SQLite
        expect(operations.whereType<AlterColumn>().isEmpty, isTrue);
      });
    });

    test('handles TIME type from database', () async {
      await pool.withConnection((conn) async {
        await conn.execute('''
          CREATE TABLE IF NOT EXISTS time_test (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            start_time TIME NOT NULL
          )
        ''');

        const schema = ModelSchema(
          className: 'TimeTest',
          tableName: 'time_test',
          fields: [
            ModelFieldSchema(
              name: 'id',
              columnName: 'id',
              dbType: FieldType.serial,
              primaryKey: true,
              autoIncrement: true,
            ),
            ModelFieldSchema(name: 'startTime', columnName: 'start_time', dbType: FieldType.time),
          ],
        );

        final operations = await generator.generateDiff(conn, [schema]);
        // TIME is stored as TEXT in SQLite
        expect(operations.whereType<AlterColumn>().isEmpty, isTrue);
      });
    });

    test('handles INTERVAL type from database', () async {
      await pool.withConnection((conn) async {
        await conn.execute('''
          CREATE TABLE IF NOT EXISTS interval_test (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            duration INTERVAL
          )
        ''');

        const schema = ModelSchema(
          className: 'IntervalTest',
          tableName: 'interval_test',
          fields: [
            ModelFieldSchema(
              name: 'id',
              columnName: 'id',
              dbType: FieldType.serial,
              primaryKey: true,
              autoIncrement: true,
            ),
            ModelFieldSchema(name: 'duration', columnName: 'duration', dbType: FieldType.interval, nullable: true),
          ],
        );

        final operations = await generator.generateDiff(conn, [schema]);
        // INTERVAL is stored as TEXT in SQLite
        expect(operations.whereType<AlterColumn>().isEmpty, isTrue);
      });
    });

    test('handles UUID type from database', () async {
      await pool.withConnection((conn) async {
        await conn.execute('''
          CREATE TABLE IF NOT EXISTS uuid_normalize_test (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            external_id UUID NOT NULL
          )
        ''');

        const schema = ModelSchema(
          className: 'UuidNormalizeTest',
          tableName: 'uuid_normalize_test',
          fields: [
            ModelFieldSchema(
              name: 'id',
              columnName: 'id',
              dbType: FieldType.serial,
              primaryKey: true,
              autoIncrement: true,
            ),
            ModelFieldSchema(name: 'externalId', columnName: 'external_id', dbType: FieldType.uuid),
          ],
        );

        final operations = await generator.generateDiff(conn, [schema]);
        // UUID is stored as TEXT in SQLite
        expect(operations.whereType<AlterColumn>().isEmpty, isTrue);
      });
    });

    test('handles JSON type from database', () async {
      await pool.withConnection((conn) async {
        await conn.execute('''
          CREATE TABLE IF NOT EXISTS json_normalize_test (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            metadata JSON
          )
        ''');

        const schema = ModelSchema(
          className: 'JsonNormalizeTest',
          tableName: 'json_normalize_test',
          fields: [
            ModelFieldSchema(
              name: 'id',
              columnName: 'id',
              dbType: FieldType.serial,
              primaryKey: true,
              autoIncrement: true,
            ),
            ModelFieldSchema(name: 'metadata', columnName: 'metadata', dbType: FieldType.json, nullable: true),
          ],
        );

        final operations = await generator.generateDiff(conn, [schema]);
        // JSON is stored as TEXT in SQLite
        expect(operations.whereType<AlterColumn>().isEmpty, isTrue);
      });
    });

    test('handles JSONB type from database', () async {
      await pool.withConnection((conn) async {
        await conn.execute('''
          CREATE TABLE IF NOT EXISTS jsonb_normalize_test (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            data JSONB
          )
        ''');

        const schema = ModelSchema(
          className: 'JsonbNormalizeTest',
          tableName: 'jsonb_normalize_test',
          fields: [
            ModelFieldSchema(
              name: 'id',
              columnName: 'id',
              dbType: FieldType.serial,
              primaryKey: true,
              autoIncrement: true,
            ),
            ModelFieldSchema(name: 'data', columnName: 'data', dbType: FieldType.jsonb, nullable: true),
          ],
        );

        final operations = await generator.generateDiff(conn, [schema]);
        // JSONB is stored as TEXT in SQLite
        expect(operations.whereType<AlterColumn>().isEmpty, isTrue);
      });
    });

    test('returns false when types are not equivalent in SQLite', () async {
      await pool.withConnection((conn) async {
        // Create a table with INTEGER column
        await conn.execute('''
          CREATE TABLE IF NOT EXISTS not_equiv_test (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            data INTEGER NOT NULL
          )
        ''');

        // Model expects TEXT type (not equivalent to INTEGER in SQLite)
        const schema = ModelSchema(
          className: 'NotEquivTest',
          tableName: 'not_equiv_test',
          fields: [
            ModelFieldSchema(
              name: 'id',
              columnName: 'id',
              dbType: FieldType.serial,
              primaryKey: true,
              autoIncrement: true,
            ),
            ModelFieldSchema(name: 'data', columnName: 'data', dbType: FieldType.text),
          ],
        );

        final operations = await generator.generateDiff(conn, [schema]);
        // TEXT and INTEGER are NOT equivalent in SQLite - should generate AlterColumn
        expect(operations.whereType<AlterColumn>().isNotEmpty, isTrue);
      });
    });
  });

  group('generateMigrationFile _columnToCode coverage', () {
    late SchemaGenerator generator;

    setUp(() {
      generator = SchemaGenerator(const SqliteAdapter());
    });

    test('generates code for boolean column', () {
      final operations = [
        CreateTable(
          TableDefinition(
            name: 'flags',
            columns: [
              const ColumnDefinition(name: 'id', type: FieldType.serial, primaryKey: true),
              const ColumnDefinition(name: 'is_active', type: FieldType.boolean, defaultValue: 'true'),
            ],
          ),
        ),
      ];

      final code = generator.generateMigrationFile('CreateFlagsTable', operations);

      expect(code, contains("table.boolean('is_active'"));
    });

    test('generates code for integer column', () {
      final operations = [
        CreateTable(
          TableDefinition(
            name: 'counts',
            columns: [
              const ColumnDefinition(name: 'id', type: FieldType.serial, primaryKey: true),
              const ColumnDefinition(name: 'count', type: FieldType.integer, nullable: true),
              const ColumnDefinition(name: 'total', type: FieldType.integer, defaultValue: '0'),
            ],
          ),
        ),
      ];

      final code = generator.generateMigrationFile('CreateCountsTable', operations);

      expect(code, contains("table.integer('count'"));
      expect(code, contains("table.integer('total'"));
    });

    test('generates binary column for bytea type', () {
      final operations = [
        CreateTable(
          TableDefinition(
            name: 'misc',
            columns: [
              const ColumnDefinition(name: 'id', type: FieldType.serial, primaryKey: true),
              const ColumnDefinition(name: 'data', type: FieldType.bytea),
            ],
          ),
        ),
      ];

      final code = generator.generateMigrationFile('CreateMiscTable', operations);

      expect(code, contains("table.binary('data'"));
    });

    test('generates code for serial primary key column', () {
      final operations = [
        CreateTable(
          TableDefinition(
            name: 'items',
            columns: [
              const ColumnDefinition(name: 'id', type: FieldType.serial, primaryKey: true),
            ],
          ),
        ),
      ];

      final code = generator.generateMigrationFile('CreateItemsTable', operations);

      expect(code, contains("table.id('id')"));
    });

    test('generates code for bigSerial primary key column', () {
      final operations = [
        CreateTable(
          TableDefinition(
            name: 'items',
            columns: [
              const ColumnDefinition(name: 'id', type: FieldType.bigSerial, primaryKey: true),
            ],
          ),
        ),
      ];

      final code = generator.generateMigrationFile('CreateItemsTable', operations);

      expect(code, contains("table.bigId('id')"));
    });

    test('generates code for varchar column', () {
      final operations = [
        CreateTable(
          TableDefinition(
            name: 'items',
            columns: [
              const ColumnDefinition(name: 'id', type: FieldType.serial, primaryKey: true),
              const ColumnDefinition(name: 'name', type: FieldType.varchar, length: 100, nullable: false),
              const ColumnDefinition(name: 'title', type: FieldType.varchar, nullable: true),
            ],
          ),
        ),
      ];

      final code = generator.generateMigrationFile('CreateItemsTable', operations);

      expect(code, contains("table.string('name', length: 100)"));
      expect(code, contains("table.string('title', length: 255, nullable: true)"));
    });

    test('generates code for char column', () {
      final operations = [
        CreateTable(
          TableDefinition(
            name: 'items',
            columns: [
              const ColumnDefinition(name: 'id', type: FieldType.serial, primaryKey: true),
              const ColumnDefinition(name: 'code', type: FieldType.char, length: 3, nullable: false),
            ],
          ),
        ),
      ];

      final code = generator.generateMigrationFile('CreateItemsTable', operations);

      expect(code, contains("table.char('code', length: 3)"));
    });

    test('generates code for text column', () {
      final operations = [
        CreateTable(
          TableDefinition(
            name: 'items',
            columns: [
              const ColumnDefinition(name: 'id', type: FieldType.serial, primaryKey: true),
              const ColumnDefinition(name: 'bio', type: FieldType.text, nullable: true),
            ],
          ),
        ),
      ];

      final code = generator.generateMigrationFile('CreateItemsTable', operations);

      expect(code, contains("table.text('bio', nullable: true)"));
    });

    test('generates code for smallInt column', () {
      final operations = [
        CreateTable(
          TableDefinition(
            name: 'items',
            columns: [
              const ColumnDefinition(name: 'id', type: FieldType.serial, primaryKey: true),
              const ColumnDefinition(name: 'priority', type: FieldType.smallInt, nullable: false),
            ],
          ),
        ),
      ];

      final code = generator.generateMigrationFile('CreateItemsTable', operations);

      expect(code, contains("table.smallInteger('priority')"));
    });

    test('generates code for bigInt column', () {
      final operations = [
        CreateTable(
          TableDefinition(
            name: 'items',
            columns: [
              const ColumnDefinition(name: 'id', type: FieldType.serial, primaryKey: true),
              const ColumnDefinition(name: 'big_count', type: FieldType.bigInt, nullable: true),
            ],
          ),
        ),
      ];

      final code = generator.generateMigrationFile('CreateItemsTable', operations);

      expect(code, contains("table.bigInteger('big_count', nullable: true)"));
    });

    test('generates code for real/float column', () {
      final operations = [
        CreateTable(
          TableDefinition(
            name: 'items',
            columns: [
              const ColumnDefinition(name: 'id', type: FieldType.serial, primaryKey: true),
              const ColumnDefinition(name: 'score', type: FieldType.real, nullable: false),
            ],
          ),
        ),
      ];

      final code = generator.generateMigrationFile('CreateItemsTable', operations);

      expect(code, contains("table.float('score')"));
    });

    test('generates code for doublePrecision column', () {
      final operations = [
        CreateTable(
          TableDefinition(
            name: 'items',
            columns: [
              const ColumnDefinition(name: 'id', type: FieldType.serial, primaryKey: true),
              const ColumnDefinition(name: 'latitude', type: FieldType.doublePrecision, nullable: false),
            ],
          ),
        ),
      ];

      final code = generator.generateMigrationFile('CreateItemsTable', operations);

      expect(code, contains("table.doublePrecision('latitude')"));
    });

    test('generates code for decimal column', () {
      final operations = [
        CreateTable(
          TableDefinition(
            name: 'items',
            columns: [
              const ColumnDefinition(name: 'id', type: FieldType.serial, primaryKey: true),
              const ColumnDefinition(name: 'price', type: FieldType.decimal, precision: 8, scale: 2, nullable: false),
              const ColumnDefinition(name: 'rate', type: FieldType.decimal, nullable: false),
            ],
          ),
        ),
      ];

      final code = generator.generateMigrationFile('CreateItemsTable', operations);

      expect(code, contains("table.decimal('price', precision: 8, scale: 2)"));
      expect(code, contains("table.decimal('rate', precision: 10, scale: 2)"));
    });

    test('generates code for date column', () {
      final operations = [
        CreateTable(
          TableDefinition(
            name: 'items',
            columns: [
              const ColumnDefinition(name: 'id', type: FieldType.serial, primaryKey: true),
              const ColumnDefinition(name: 'birth_date', type: FieldType.date, nullable: false),
            ],
          ),
        ),
      ];

      final code = generator.generateMigrationFile('CreateItemsTable', operations);

      expect(code, contains("table.date('birth_date')"));
    });

    test('generates code for time column', () {
      final operations = [
        CreateTable(
          TableDefinition(
            name: 'items',
            columns: [
              const ColumnDefinition(name: 'id', type: FieldType.serial, primaryKey: true),
              const ColumnDefinition(name: 'start_time', type: FieldType.time, nullable: false),
            ],
          ),
        ),
      ];

      final code = generator.generateMigrationFile('CreateItemsTable', operations);

      expect(code, contains("table.time('start_time')"));
    });

    test('generates code for timestamp column', () {
      final operations = [
        CreateTable(
          TableDefinition(
            name: 'items',
            columns: [
              const ColumnDefinition(name: 'id', type: FieldType.serial, primaryKey: true),
              const ColumnDefinition(name: 'logged_at', type: FieldType.timestamp, nullable: false),
              const ColumnDefinition(
                  name: 'created_at', type: FieldType.timestamp, nullable: false, defaultValue: 'CURRENT_TIMESTAMP'),
            ],
          ),
        ),
      ];

      final code = generator.generateMigrationFile('CreateItemsTable', operations);

      expect(code, contains("table.timestamp('logged_at')"));
      expect(code, contains("table.timestamp('created_at'"));
      expect(code, contains('useCurrent: true'));
    });

    test('generates code for timestampTz column', () {
      final operations = [
        CreateTable(
          TableDefinition(
            name: 'items',
            columns: [
              const ColumnDefinition(name: 'id', type: FieldType.serial, primaryKey: true),
              const ColumnDefinition(name: 'updated_at', type: FieldType.timestampTz, nullable: false),
              const ColumnDefinition(
                  name: 'created_at', type: FieldType.timestampTz, nullable: false, defaultValue: 'CURRENT_TIMESTAMP'),
            ],
          ),
        ),
      ];

      final code = generator.generateMigrationFile('CreateItemsTable', operations);

      expect(code, contains("table.timestampTz('updated_at')"));
      expect(code, contains("table.timestampTz('created_at'"));
      expect(code, contains('useCurrent: true'));
    });

    test('generates code for uuid primary key column', () {
      final operations = [
        CreateTable(
          TableDefinition(
            name: 'items',
            columns: [
              const ColumnDefinition(name: 'id', type: FieldType.uuid, primaryKey: true),
            ],
          ),
        ),
      ];

      final code = generator.generateMigrationFile('CreateItemsTable', operations);

      expect(code, contains("table.uuid('id')"));
    });

    test('generates code for uuid non-primary-key column', () {
      final operations = [
        CreateTable(
          TableDefinition(
            name: 'items',
            columns: [
              const ColumnDefinition(name: 'id', type: FieldType.serial, primaryKey: true),
              const ColumnDefinition(name: 'external_id', type: FieldType.uuid, nullable: true),
            ],
          ),
        ),
      ];

      final code = generator.generateMigrationFile('CreateItemsTable', operations);

      expect(code, contains("table.uuidColumn('external_id', nullable: true)"));
    });

    test('generates code for json column', () {
      final operations = [
        CreateTable(
          TableDefinition(
            name: 'items',
            columns: [
              const ColumnDefinition(name: 'id', type: FieldType.serial, primaryKey: true),
              const ColumnDefinition(name: 'metadata', type: FieldType.json, nullable: true),
            ],
          ),
        ),
      ];

      final code = generator.generateMigrationFile('CreateItemsTable', operations);

      expect(code, contains("table.json('metadata', nullable: true)"));
    });

    test('generates code for jsonb column', () {
      final operations = [
        CreateTable(
          TableDefinition(
            name: 'items',
            columns: [
              const ColumnDefinition(name: 'id', type: FieldType.serial, primaryKey: true),
              const ColumnDefinition(name: 'data', type: FieldType.jsonb, nullable: true),
            ],
          ),
        ),
      ];

      final code = generator.generateMigrationFile('CreateItemsTable', operations);

      expect(code, contains("table.jsonb('data', nullable: true)"));
    });

    test('generates code for blob column', () {
      final operations = [
        CreateTable(
          TableDefinition(
            name: 'items',
            columns: [
              const ColumnDefinition(name: 'id', type: FieldType.serial, primaryKey: true),
              const ColumnDefinition(name: 'content', type: FieldType.blob, nullable: false),
            ],
          ),
        ),
      ];

      final code = generator.generateMigrationFile('CreateItemsTable', operations);

      expect(code, contains("table.binary('content')"));
    });

    test('generates code for interval column', () {
      final operations = [
        CreateTable(
          TableDefinition(
            name: 'items',
            columns: [
              const ColumnDefinition(name: 'id', type: FieldType.serial, primaryKey: true),
              const ColumnDefinition(name: 'duration', type: FieldType.interval, nullable: false),
            ],
          ),
        ),
      ];

      final code = generator.generateMigrationFile('CreateItemsTable', operations);

      expect(code, contains("table.text('duration')"));
    });

    test('generates code for array column', () {
      final operations = [
        CreateTable(
          TableDefinition(
            name: 'items',
            columns: [
              const ColumnDefinition(name: 'id', type: FieldType.serial, primaryKey: true),
              const ColumnDefinition(name: 'tags', type: FieldType.array, nullable: false),
            ],
          ),
        ),
      ];

      final code = generator.generateMigrationFile('CreateItemsTable', operations);

      expect(code, contains("table.text('tags')"));
    });
  });
}

// Test enum for EnumField tests
enum TestEnum { a, b, c }
