import 'package:jao/jao.dart';
import 'package:test/test.dart';

void main() {
  group('TableBuilder', () {
    group('Primary Keys', () {
      test('id() adds auto-increment primary key', () {
        final table = TableBuilder('users').id().build();

        expect(table.columns.length, equals(1));
        final idCol = table.columns.first;
        expect(idCol.name, equals('id'));
        expect(idCol.type, equals(FieldType.serial));
        expect(idCol.primaryKey, isTrue);
        expect(idCol.nullable, isFalse);
        expect(table.primaryKey, equals('id'));
      });

      test('id() with custom name', () {
        final table = TableBuilder('users').id('user_id').build();

        expect(table.columns.first.name, equals('user_id'));
        expect(table.primaryKey, equals('user_id'));
      });

      test('bigId() adds big auto-increment', () {
        final table = TableBuilder('events').bigId().build();

        expect(table.columns.first.type, equals(FieldType.bigSerial));
        expect(table.columns.first.primaryKey, isTrue);
      });

      test('uuid() as primary key', () {
        final table = TableBuilder('documents').uuid().build();

        final idCol = table.columns.first;
        expect(idCol.type, equals(FieldType.uuid));
        expect(idCol.primaryKey, isTrue);
        expect(idCol.defaultValue, isNotNull);
      });
    });

    group('String Columns', () {
      test('string() adds varchar column', () {
        final table = TableBuilder('users').id().string('name').build();

        final nameCol = table.columns.firstWhere((c) => c.name == 'name');
        expect(nameCol.type, equals(FieldType.varchar));
        expect(nameCol.length, equals(255));
        expect(nameCol.nullable, isFalse);
      });

      test('string() with maxLength', () {
        final table = TableBuilder('users').id().string('email', length: 100).build();

        final emailCol = table.columns.firstWhere((c) => c.name == 'email');
        expect(emailCol.length, equals(100));
      });

      test('string() with nullable', () {
        final table = TableBuilder('users').id().string('nickname', nullable: true).build();

        final nickCol = table.columns.firstWhere((c) => c.name == 'nickname');
        expect(nickCol.nullable, isTrue);
      });

      test('string() with defaultValue', () {
        final table = TableBuilder('users').id().string('status', defaultValue: "'active'").build();

        final statusCol = table.columns.firstWhere((c) => c.name == 'status');
        expect(statusCol.defaultValue, equals("'active'"));
      });

      test('text() adds text column', () {
        final table = TableBuilder('posts').id().text('content').build();

        final contentCol = table.columns.firstWhere((c) => c.name == 'content');
        expect(contentCol.type, equals(FieldType.text));
      });

      test('char() adds fixed length char column', () {
        final table = TableBuilder('codes').id().char('code', length: 6).build();

        final codeCol = table.columns.firstWhere((c) => c.name == 'code');
        expect(codeCol.type, equals(FieldType.char));
        expect(codeCol.length, equals(6));
      });
    });

    group('Numeric Columns', () {
      test('integer() adds integer column', () {
        final table = TableBuilder('users').id().integer('age').build();

        final ageCol = table.columns.firstWhere((c) => c.name == 'age');
        expect(ageCol.type, equals(FieldType.integer));
      });

      test('integer() with defaultValue', () {
        final table = TableBuilder('items').id().integer('quantity', defaultValue: 0).build();

        final qtyCol = table.columns.firstWhere((c) => c.name == 'quantity');
        expect(qtyCol.defaultValue, equals('0'));
      });

      test('smallInteger() adds smallint column', () {
        final table = TableBuilder('ratings').id().smallInteger('score').build();

        final scoreCol = table.columns.firstWhere((c) => c.name == 'score');
        expect(scoreCol.type, equals(FieldType.smallInt));
      });

      test('bigInteger() adds bigint column', () {
        final table = TableBuilder('analytics').id().bigInteger('views').build();

        final viewsCol = table.columns.firstWhere((c) => c.name == 'views');
        expect(viewsCol.type, equals(FieldType.bigInt));
      });

      test('float() adds float column', () {
        final table = TableBuilder('sensors').id().float('reading').build();

        final readCol = table.columns.firstWhere((c) => c.name == 'reading');
        expect(readCol.type, equals(FieldType.real));
      });

      test('doublePrecision() adds double column', () {
        final table = TableBuilder('positions').id().doublePrecision('latitude').build();

        final latCol = table.columns.firstWhere((c) => c.name == 'latitude');
        expect(latCol.type, equals(FieldType.doublePrecision));
      });

      test('decimal() adds decimal with precision', () {
        final table = TableBuilder('products').id().decimal('price', precision: 10, scale: 2).build();

        final priceCol = table.columns.firstWhere((c) => c.name == 'price');
        expect(priceCol.type, equals(FieldType.decimal));
        expect(priceCol.precision, equals(10));
        expect(priceCol.scale, equals(2));
      });
    });

    group('Boolean Columns', () {
      test('boolean() adds boolean column', () {
        final table = TableBuilder('users').id().boolean('active').build();

        final activeCol = table.columns.firstWhere((c) => c.name == 'active');
        expect(activeCol.type, equals(FieldType.boolean));
      });

      test('boolean() with default true', () {
        final table = TableBuilder('settings').id().boolean('enabled', defaultValue: true).build();

        final enabledCol = table.columns.firstWhere((c) => c.name == 'enabled');
        expect(enabledCol.defaultValue, equals('true'));
      });

      test('boolean() with default false', () {
        final table = TableBuilder('flags').id().boolean('archived', defaultValue: false).build();

        final archivedCol = table.columns.firstWhere((c) => c.name == 'archived');
        expect(archivedCol.defaultValue, equals('false'));
      });
    });

    group('Date/Time Columns', () {
      test('date() adds date column', () {
        final table = TableBuilder('events').id().date('event_date').build();

        final dateCol = table.columns.firstWhere((c) => c.name == 'event_date');
        expect(dateCol.type, equals(FieldType.date));
      });

      test('time() adds time column', () {
        final table = TableBuilder('schedules').id().time('start_time').build();

        final timeCol = table.columns.firstWhere((c) => c.name == 'start_time');
        expect(timeCol.type, equals(FieldType.time));
      });

      test('timestamp() adds timestamp column', () {
        final table = TableBuilder('logs').id().timestamp('logged_at').build();

        final tsCol = table.columns.firstWhere((c) => c.name == 'logged_at');
        expect(tsCol.type, equals(FieldType.timestamp));
      });

      test('timestamp() with useCurrent', () {
        final table = TableBuilder('logs').id().timestamp('logged_at', useCurrent: true).build();

        final tsCol = table.columns.firstWhere((c) => c.name == 'logged_at');
        expect(tsCol.defaultValue, equals('CURRENT_TIMESTAMP'));
      });

      test('timestampTz() adds timestamptz column', () {
        final table = TableBuilder('events').id().timestampTz('event_time').build();

        final tsCol = table.columns.firstWhere((c) => c.name == 'event_time');
        expect(tsCol.type, equals(FieldType.timestampTz));
      });

      test('createdAt() adds created_at with current timestamp', () {
        final table = TableBuilder('posts').id().createdAt().build();

        final createdCol = table.columns.firstWhere((c) => c.name == 'created_at');
        expect(createdCol.type, equals(FieldType.timestampTz));
        expect(createdCol.defaultValue, equals('CURRENT_TIMESTAMP'));
      });

      test('updatedAt() adds updated_at with current timestamp', () {
        final table = TableBuilder('posts').id().updatedAt().build();

        final updatedCol = table.columns.firstWhere((c) => c.name == 'updated_at');
        expect(updatedCol.type, equals(FieldType.timestampTz));
        expect(updatedCol.defaultValue, equals('CURRENT_TIMESTAMP'));
      });

      test('timestamps() adds both created_at and updated_at', () {
        final table = TableBuilder('posts').id().timestamps().build();

        expect(table.columns.any((c) => c.name == 'created_at'), isTrue);
        expect(table.columns.any((c) => c.name == 'updated_at'), isTrue);
      });
    });

    group('Special Types', () {
      test('binary() adds binary column', () {
        final table = TableBuilder('files').id().binary('data').build();

        final dataCol = table.columns.firstWhere((c) => c.name == 'data');
        expect(dataCol.type, equals(FieldType.bytea));
      });

      test('uuidColumn() adds uuid column', () {
        final table = TableBuilder('refs').id().uuidColumn('external_id').build();

        final uuidCol = table.columns.firstWhere((c) => c.name == 'external_id');
        expect(uuidCol.type, equals(FieldType.uuid));
      });

      test('json() adds json column', () {
        final table = TableBuilder('settings').id().json('config').build();

        final configCol = table.columns.firstWhere((c) => c.name == 'config');
        expect(configCol.type, equals(FieldType.json));
      });

      test('jsonb() adds jsonb column', () {
        final table = TableBuilder('documents').id().jsonb('metadata').build();

        final metaCol = table.columns.firstWhere((c) => c.name == 'metadata');
        expect(metaCol.type, equals(FieldType.jsonb));
      });
    });

    group('Enum Columns', () {
      test('enumString() adds varchar with check constraint', () {
        final table = TableBuilder('orders').id().enumString('status', ['pending', 'processing', 'completed']).build();

        final statusCol = table.columns.firstWhere((c) => c.name == 'status');
        expect(statusCol.type, equals(FieldType.varchar));
        expect(statusCol.check, contains('pending'));
        expect(statusCol.check, contains('processing'));
        expect(statusCol.check, contains('completed'));
      });
    });

    group('Foreign Keys', () {
      test('foreignKey() adds foreign key column', () {
        final table = TableBuilder('posts').id().string('title').foreignKey('author_id', 'users').build();

        final fkCol = table.columns.firstWhere((c) => c.name == 'author_id');
        expect(fkCol.type, equals(FieldType.integer));
        expect(fkCol.nullable, isFalse);

        expect(table.foreignKeys.length, equals(1));
        final fk = table.foreignKeys.first;
        expect(fk.column, equals('author_id'));
        expect(fk.referencedTable, equals('users'));
        expect(fk.referencedColumn, equals('id'));
      });

      test('foreignKey() with custom reference column', () {
        final table = TableBuilder('posts').id().foreignKey('author_uuid', 'users', referencedColumn: 'uuid').build();

        final fk = table.foreignKeys.first;
        expect(fk.referencedColumn, equals('uuid'));
      });

      test('foreignKey() with nullable', () {
        final table = TableBuilder('posts').id().foreignKey('category_id', 'categories', nullable: true).build();

        final fkCol = table.columns.firstWhere((c) => c.name == 'category_id');
        expect(fkCol.nullable, isTrue);
      });

      test('foreignKey() with onDelete cascade', () {
        final table = TableBuilder(
          'comments',
        ).id().foreignKey('post_id', 'posts', onDelete: OnDeleteAction.cascade).build();

        expect(table.foreignKeys.first.onDelete, equals(OnDeleteAction.cascade));
      });

      test('foreignKey() with onDelete setNull', () {
        final table = TableBuilder(
          'posts',
        ).id().foreignKey('author_id', 'users', onDelete: OnDeleteAction.setNull).build();

        expect(table.foreignKeys.first.onDelete, equals(OnDeleteAction.setNull));
      });

      test('foreignKey() with onDelete restrict', () {
        final table = TableBuilder(
          'orders',
        ).id().foreignKey('customer_id', 'customers', onDelete: OnDeleteAction.restrict).build();

        expect(table.foreignKeys.first.onDelete, equals(OnDeleteAction.restrict));
      });

      test('foreignKey() with onUpdate cascade', () {
        final table = TableBuilder(
          'posts',
        ).id().foreignKey('author_id', 'users', onUpdate: OnUpdateAction.cascade).build();

        expect(table.foreignKeys.first.onUpdate, equals(OnUpdateAction.cascade));
      });

      test('bigForeignKey() adds bigint foreign key', () {
        final table = TableBuilder('large_refs').id().bigForeignKey('big_table_id', 'big_table').build();

        final fkCol = table.columns.firstWhere((c) => c.name == 'big_table_id');
        expect(fkCol.type, equals(FieldType.bigInt));
      });
    });

    group('Indexes', () {
      test('index() on single column', () {
        final table = TableBuilder('users').id().string('email').index(['email']).build();

        expect(table.indexes.length, equals(1));
        final idx = table.indexes.first;
        expect(idx.columns, equals(['email']));
        expect(idx.unique, isFalse);
      });

      test('index() on multiple columns', () {
        final table = TableBuilder(
          'products',
        ).id().string('name').string('category').index(['name', 'category']).build();

        final idx = table.indexes.first;
        expect(idx.columns, equals(['name', 'category']));
      });

      test('index() with custom name', () {
        final table = TableBuilder('users').id().string('email').index(['email'], name: 'custom_email_idx').build();

        expect(table.indexes.first.name, equals('custom_email_idx'));
      });

      test('index() generates default name', () {
        final table = TableBuilder('users').id().string('email').index(['email']).build();

        expect(table.indexes.first.name, equals('idx_users_email'));
      });

      test('index() with unique flag', () {
        final table = TableBuilder('users').id().string('email').index(['email'], unique: true).build();

        expect(table.indexes.first.unique, isTrue);
      });

      test('uniqueIndex() creates unique index', () {
        final table = TableBuilder('users').id().string('email').uniqueIndex(['email']).build();

        expect(table.indexes.first.unique, isTrue);
      });

      test('unique() creates single column unique constraint', () {
        final table = TableBuilder('users').id().string('email').unique('email').build();

        expect(table.indexes.first.columns, equals(['email']));
        expect(table.indexes.first.unique, isTrue);
      });
    });

    group('Special Builders', () {
      test('ifNotExists() sets flag', () {
        final table = TableBuilder('users').ifNotExists().id().string('name').build();

        expect(table.ifNotExists, isTrue);
      });

      test('softDeletes() adds is_deleted and deleted_at', () {
        final table = TableBuilder('posts').id().softDeletes().build();

        final isDeleted = table.columns.firstWhere((c) => c.name == 'is_deleted');
        expect(isDeleted.type, equals(FieldType.boolean));
        expect(isDeleted.defaultValue, equals('false'));

        final deletedAt = table.columns.firstWhere((c) => c.name == 'deleted_at');
        expect(deletedAt.type, equals(FieldType.timestampTz));
        expect(deletedAt.nullable, isTrue);
      });
    });

    group('Fluent Chaining', () {
      test('all methods return TableBuilder for chaining', () {
        final table = TableBuilder('complex')
            .ifNotExists()
            .id()
            .string('name')
            .text('description', nullable: true)
            .integer('count', defaultValue: 0)
            .boolean('active', defaultValue: true)
            .timestamps()
            .foreignKey('category_id', 'categories')
            .index(['name']).build();

        expect(table.name, equals('complex'));
        expect(table.columns.length, equals(8)); // id, name, desc, count, active, created_at, updated_at, category_id
        expect(table.foreignKeys.length, equals(1));
        expect(table.indexes.length, equals(1));
        expect(table.ifNotExists, isTrue);
      });
    });

    group('TableDefinition', () {
      test('build() returns immutable TableDefinition', () {
        final builder = TableBuilder('users').id().string('name');
        final table = builder.build();

        expect(table, isA<TableDefinition>());
        expect(table.name, equals('users'));
        expect(table.columns, isA<List<ColumnDefinition>>());
      });

      test('columns list is populated', () {
        final table = TableBuilder('test').id().string('a').string('b').string('c').build();

        expect(table.columns.length, equals(4)); // id + a + b + c
      });
    });
  });

  group('ColumnDefinition', () {
    test('stores all properties', () {
      const col = ColumnDefinition(
        name: 'test',
        type: FieldType.varchar,
        nullable: true,
        primaryKey: false,
        length: 100,
        precision: 10,
        scale: 2,
        defaultValue: "'default'",
        check: "test IN ('a', 'b')",
      );

      expect(col.name, equals('test'));
      expect(col.type, equals(FieldType.varchar));
      expect(col.nullable, isTrue);
      expect(col.primaryKey, isFalse);
      expect(col.length, equals(100));
      expect(col.precision, equals(10));
      expect(col.scale, equals(2));
      expect(col.defaultValue, equals("'default'"));
      expect(col.check, equals("test IN ('a', 'b')"));
    });

    test('defaults are correct', () {
      const col = ColumnDefinition(name: 'test', type: FieldType.integer);

      expect(col.nullable, isTrue);
      expect(col.primaryKey, isFalse);
      expect(col.length, isNull);
      expect(col.precision, isNull);
      expect(col.scale, isNull);
      expect(col.defaultValue, isNull);
      expect(col.check, isNull);
    });
  });

  group('IndexDefinition', () {
    test('stores properties', () {
      const idx = IndexDefinition(name: 'idx_test', columns: ['a', 'b'], unique: true);

      expect(idx.name, equals('idx_test'));
      expect(idx.columns, equals(['a', 'b']));
      expect(idx.unique, isTrue);
    });

    test('unique defaults to false', () {
      const idx = IndexDefinition(name: 'idx_test', columns: ['a']);

      expect(idx.unique, isFalse);
    });
  });

  group('ForeignKeyDefinition', () {
    test('stores properties', () {
      const fk = ForeignKeyDefinition(
        column: 'user_id',
        referencedTable: 'users',
        referencedColumn: 'id',
        onDelete: OnDeleteAction.cascade,
        onUpdate: OnUpdateAction.setNull,
      );

      expect(fk.column, equals('user_id'));
      expect(fk.referencedTable, equals('users'));
      expect(fk.referencedColumn, equals('id'));
      expect(fk.onDelete, equals(OnDeleteAction.cascade));
      expect(fk.onUpdate, equals(OnUpdateAction.setNull));
    });

    test('defaults are cascade', () {
      const fk = ForeignKeyDefinition(column: 'ref_id', referencedTable: 'refs', referencedColumn: 'id');

      expect(fk.onDelete, equals(OnDeleteAction.cascade));
      expect(fk.onUpdate, equals(OnUpdateAction.cascade));
    });
  });

  group('ColumnModifier', () {
    test('builds ColumnModification', () {
      final mod = ColumnModifier('users', 'email').type(FieldType.text).nullable().defaultValue("'none'").build();

      expect(mod.table, equals('users'));
      expect(mod.column, equals('email'));
      expect(mod.type, equals(FieldType.text));
      expect(mod.nullable, isTrue);
      expect(mod.defaultValue, equals("'none'"));
    });

    test('notNullable() sets nullable to false', () {
      final mod = ColumnModifier('users', 'name').notNullable().build();

      expect(mod.nullable, isFalse);
    });

    test('dropDefault() sets flag', () {
      final mod = ColumnModifier('users', 'status').dropDefault().build();

      expect(mod.dropDefault, isTrue);
    });

    test('renameTo() sets rename', () {
      final mod = ColumnModifier('users', 'email').renameTo('email_address').build();

      expect(mod.rename, equals('email_address'));
    });
  });

  group('ColumnModification', () {
    test('stores all properties', () {
      const mod = ColumnModification(
        table: 'users',
        column: 'age',
        type: FieldType.bigInt,
        nullable: false,
        defaultValue: '18',
        rename: 'user_age',
        dropDefault: false,
      );

      expect(mod.table, equals('users'));
      expect(mod.column, equals('age'));
      expect(mod.type, equals(FieldType.bigInt));
      expect(mod.nullable, isFalse);
      expect(mod.defaultValue, equals('18'));
      expect(mod.rename, equals('user_age'));
      expect(mod.dropDefault, isFalse);
    });

    test('dropDefault defaults to false', () {
      const mod = ColumnModification(table: 'test', column: 'col');

      expect(mod.dropDefault, isFalse);
    });
  });

  group('OnDeleteAction', () {
    test('has all values', () {
      expect(
        OnDeleteAction.values,
        containsAll([
          OnDeleteAction.cascade,
          OnDeleteAction.restrict,
          OnDeleteAction.setNull,
          OnDeleteAction.setDefault,
          OnDeleteAction.noAction,
        ]),
      );
    });
  });

  group('OnUpdateAction', () {
    test('has all values', () {
      expect(
        OnUpdateAction.values,
        containsAll([
          OnUpdateAction.cascade,
          OnUpdateAction.restrict,
          OnUpdateAction.setNull,
          OnUpdateAction.setDefault,
          OnUpdateAction.noAction,
        ]),
      );
    });
  });
}
