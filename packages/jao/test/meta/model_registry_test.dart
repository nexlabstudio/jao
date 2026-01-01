import 'package:jao/jao.dart';
import 'package:test/test.dart';

void main() {
  group('ModelRegistry', () {
    setUp(() {
      ModelRegistry.instance.clear();
    });

    tearDown(() {
      ModelRegistry.instance.clear();
    });

    test('registers and retrieves model by type', () {
      ModelRegistry.instance.register(
        const ModelMetadata(
          modelType: _User,
          tableName: 'users',
          primaryKey: 'id',
          fields: {},
          relations: {},
        ),
      );

      final meta = ModelRegistry.instance.get<_User>();
      expect(meta, isNotNull);
      expect(meta!.modelType, equals(_User));
      expect(meta.tableName, equals('users'));
    });

    test('retrieves model by table name', () {
      ModelRegistry.instance.register(
        const ModelMetadata(
          modelType: _User,
          tableName: 'users',
          primaryKey: 'id',
          fields: {},
          relations: {},
        ),
      );

      final meta = ModelRegistry.instance.getByTableName('users');
      expect(meta, isNotNull);
      expect(meta!.modelType, equals(_User));
    });

    test('retrieves model by runtime Type', () {
      ModelRegistry.instance.register(
        const ModelMetadata(
          modelType: _User,
          tableName: 'users',
          primaryKey: 'id',
          fields: {},
          relations: {},
        ),
      );

      final meta = ModelRegistry.instance.getByType(_User);
      expect(meta, isNotNull);
      expect(meta!.tableName, equals('users'));
    });

    test('isRegistered returns correct value', () {
      expect(ModelRegistry.instance.isRegistered<_User>(), isFalse);

      ModelRegistry.instance.register(
        const ModelMetadata(
          modelType: _User,
          tableName: 'users',
          primaryKey: 'id',
          fields: {},
          relations: {},
        ),
      );

      expect(ModelRegistry.instance.isRegistered<_User>(), isTrue);
    });

    test('isTableRegistered returns correct value', () {
      expect(ModelRegistry.instance.isTableRegistered('users'), isFalse);

      ModelRegistry.instance.register(
        const ModelMetadata(
          modelType: _User,
          tableName: 'users',
          primaryKey: 'id',
          fields: {},
          relations: {},
        ),
      );

      expect(ModelRegistry.instance.isTableRegistered('users'), isTrue);
    });

    test('clear removes all registrations', () {
      ModelRegistry.instance.register(
        const ModelMetadata(
          modelType: _User,
          tableName: 'users',
          primaryKey: 'id',
          fields: {},
          relations: {},
        ),
      );

      expect(ModelRegistry.instance.isRegistered<_User>(), isTrue);

      ModelRegistry.instance.clear();

      expect(ModelRegistry.instance.isRegistered<_User>(), isFalse);
    });

    test('all returns all registered models', () {
      ModelRegistry.instance.register(
        const ModelMetadata(
          modelType: _User,
          tableName: 'users',
          primaryKey: 'id',
          fields: {},
          relations: {},
        ),
      );
      ModelRegistry.instance.register(
        const ModelMetadata(
          modelType: _Post,
          tableName: 'posts',
          primaryKey: 'id',
          fields: {},
          relations: {},
        ),
      );

      expect(ModelRegistry.instance.all.length, equals(2));
    });
  });

  group('ModelMetadata', () {
    test('getField returns field by name', () {
      const meta = ModelMetadata(
        modelType: _User,
        tableName: 'users',
        primaryKey: 'id',
        fields: {
          'id': FieldMeta(
            fieldName: 'id',
            columnName: 'id',
            dartType: int,
            isPrimaryKey: true,
          ),
          'name': FieldMeta(
            fieldName: 'name',
            columnName: 'name',
            dartType: String,
          ),
          'email': FieldMeta(
            fieldName: 'email',
            columnName: 'email',
            dartType: String,
          ),
        },
        relations: {},
      );

      final field = meta.getField('name');
      expect(field, isNotNull);
      expect(field!.columnName, equals('name'));
    });

    test('getField returns null for unknown field', () {
      const meta = ModelMetadata(
        modelType: _User,
        tableName: 'users',
        primaryKey: 'id',
        fields: {},
        relations: {},
      );

      expect(meta.getField('unknown'), isNull);
    });

    test('getRelation returns relation by field name', () {
      const meta = ModelMetadata(
        modelType: _Post,
        tableName: 'posts',
        primaryKey: 'id',
        fields: {},
        relations: {
          'author': RelationMeta(
            fieldName: 'author',
            columnName: 'author_id',
            relatedModel: _User,
            relatedColumn: 'id',
          ),
        },
      );

      final relation = meta.getRelation('author');
      expect(relation, isNotNull);
      expect(relation!.relatedModel, equals(_User));
    });

    test('getRelationByType returns relation by related model type', () {
      const meta = ModelMetadata(
        modelType: _Post,
        tableName: 'posts',
        primaryKey: 'id',
        fields: {},
        relations: {
          'author': RelationMeta(
            fieldName: 'author',
            columnName: 'author_id',
            relatedModel: _User,
            relatedColumn: 'id',
          ),
        },
      );

      final relation = meta.getRelationByType(_User);
      expect(relation, isNotNull);
      expect(relation!.fieldName, equals('author'));
    });
  });

  group('ModelRegistry.resolveJoinPath', () {
    setUp(() {
      ModelRegistry.instance.clear();
    });

    tearDown(() {
      ModelRegistry.instance.clear();
    });

    test('returns null for unregistered base table', () {
      final result = ModelRegistry.instance.resolveJoinPath('unknown', 'author');
      expect(result, isNull);
    });

    test('returns null for unknown relation', () {
      ModelRegistry.instance.register(
        const ModelMetadata(
          modelType: _Post,
          tableName: 'posts',
          primaryKey: 'id',
          fields: {},
          relations: {},
        ),
      );

      final result = ModelRegistry.instance.resolveJoinPath('posts', 'unknown');
      expect(result, isNull);
    });

    test('resolves single-level join by field name', () {
      ModelRegistry.instance.register(
        const ModelMetadata(
          modelType: _Post,
          tableName: 'posts',
          primaryKey: 'id',
          fields: {},
          relations: {
            'author': RelationMeta(
              fieldName: 'author',
              columnName: 'author_id',
              relatedModel: _User,
              relatedColumn: 'id',
            ),
          },
        ),
      );
      ModelRegistry.instance.register(
        const ModelMetadata(
          modelType: _User,
          tableName: 'users',
          primaryKey: 'id',
          fields: {},
          relations: {},
        ),
      );

      final result = ModelRegistry.instance.resolveJoinPath('posts', 'author');
      expect(result, isNotNull);
      expect(result!.length, equals(1));
      expect(result[0].fromTable, equals('posts'));
      expect(result[0].fromColumn, equals('author_id'));
      expect(result[0].toTable, equals('users'));
      expect(result[0].toColumn, equals('id'));
    });

    test('resolves multi-level join', () {
      ModelRegistry.instance.register(
        const ModelMetadata(
          modelType: _Book,
          tableName: 'books',
          primaryKey: 'id',
          fields: {},
          relations: {
            'author': RelationMeta(
              fieldName: 'author',
              columnName: 'author_id',
              relatedModel: _Author,
              relatedColumn: 'id',
            ),
          },
        ),
      );
      ModelRegistry.instance.register(
        const ModelMetadata(
          modelType: _Author,
          tableName: 'authors',
          primaryKey: 'id',
          fields: {},
          relations: {
            'publisher': RelationMeta(
              fieldName: 'publisher',
              columnName: 'publisher_id',
              relatedModel: _Publisher,
              relatedColumn: 'id',
            ),
          },
        ),
      );
      ModelRegistry.instance.register(
        const ModelMetadata(
          modelType: _Publisher,
          tableName: 'publishers',
          primaryKey: 'id',
          fields: {},
          relations: {},
        ),
      );

      final result = ModelRegistry.instance.resolveJoinPath('books', 'author__publisher');
      expect(result, isNotNull);
      expect(result!.length, equals(2));

      expect(result[0].fromTable, equals('books'));
      expect(result[0].toTable, equals('authors'));

      expect(result[1].fromTable, equals('authors'));
      expect(result[1].toTable, equals('publishers'));
    });
  });
}

// Test model classes
class _User {}

class _Post {}

class _Book {}

class _Author {}

class _Publisher {}
