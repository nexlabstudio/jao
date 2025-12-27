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
        defaultValue: 'true',
      );

      expect(field.defaultValue, equals('true'));
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
              defaultValue: 'true',
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

    test('EnumField maps to text', () {
      expect(fieldDefToDbType(const EnumField<TestEnum>()), equals(FieldType.text));
    });
  });
}

// Test enum for EnumField tests
enum TestEnum { a, b, c }
