import 'package:jao/jao.dart';
import 'package:test/test.dart';

/// Tests for cross-database type compatibility.
///
/// These tests verify that fromRow() handles types correctly across different
/// database adapters using the type converter functions. Different databases
/// return different types:
/// - SQLite: String for timestamps, int (0/1) for booleans
/// - PostgreSQL: DateTime objects, bool values
///
/// The type converters (dbDateTime, dbBool, dbInt, dbDouble, dbDuration)
/// normalize these differences so models work across all databases.
///
/// See: https://github.com/nexlabstudio/jao/issues/4

// Test model with DateTime field
class Post {
  final int? id;
  final String title;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Post({this.id, required this.title, required this.createdAt, this.updatedAt});

  // Updated to use type converters (matches new generator output)
  static Post fromRow(Map<String, dynamic> row) {
    return Post(
      id: dbIntOrNull(row['id']),
      title: row['title'] as String,
      createdAt: dbDateTime(row['created_at']),
      updatedAt: dbDateTimeOrNull(row['updated_at']),
    );
  }

  static Map<String, dynamic> toRow(Post post) {
    return {
      if (post.id != null) 'id': post.id,
      'title': post.title,
      'created_at': post.createdAt.toIso8601String(),
      if (post.updatedAt != null) 'updated_at': post.updatedAt!.toIso8601String(),
    };
  }
}

// Test model with boolean field
class User {
  final int? id;
  final String name;
  final bool isActive;
  final bool? isAdmin;

  User({this.id, required this.name, required this.isActive, this.isAdmin});

  // Updated to use type converters (matches new generator output)
  static User fromRow(Map<String, dynamic> row) {
    return User(
      id: dbIntOrNull(row['id']),
      name: row['name'] as String,
      isActive: dbBool(row['is_active']),
      isAdmin: dbBoolOrNull(row['is_admin']),
    );
  }

  static Map<String, dynamic> toRow(User user) {
    return {
      if (user.id != null) 'id': user.id,
      'name': user.name,
      'is_active': user.isActive,
      if (user.isAdmin != null) 'is_admin': user.isAdmin,
    };
  }
}

// Test model with numeric fields
class Product {
  final int? id;
  final String name;
  final int quantity;
  final double price;

  Product({this.id, required this.name, required this.quantity, required this.price});

  // Updated to use type converters (matches new generator output)
  static Product fromRow(Map<String, dynamic> row) {
    return Product(
      id: dbIntOrNull(row['id']),
      name: row['name'] as String,
      quantity: dbInt(row['quantity']),
      price: dbDouble(row['price']),
    );
  }

  static Map<String, dynamic> toRow(Product product) {
    return {
      if (product.id != null) 'id': product.id,
      'name': product.name,
      'quantity': product.quantity,
      'price': product.price,
    };
  }
}

void main() {
  group('Post.fromRow - @DateTimeField', () {
    test('should work with SQLite (String timestamps)', () {
      final row = {
        'id': 1,
        'title': 'Hello World',
        'created_at': '2024-01-15T10:30:00.000',
        'updated_at': '2024-01-16T12:00:00.000',
      };

      final post = Post.fromRow(row);

      expect(post.id, equals(1));
      expect(post.title, equals('Hello World'));
      expect(post.createdAt, equals(DateTime(2024, 1, 15, 10, 30, 0)));
      expect(post.updatedAt, equals(DateTime(2024, 1, 16, 12, 0, 0)));
    });

    test('should work with SQLite (null timestamp)', () {
      final row = {
        'id': 1,
        'title': 'Hello World',
        'created_at': '2024-01-15T10:30:00.000',
        'updated_at': null,
      };

      final post = Post.fromRow(row);

      expect(post.updatedAt, isNull);
    });

    test('should work with PostgreSQL (DateTime objects)', () {
      final row = {
        'id': 1,
        'title': 'Hello World',
        'created_at': DateTime(2024, 1, 15, 10, 30, 0),
        'updated_at': DateTime(2024, 1, 16, 12, 0, 0),
      };

      final post = Post.fromRow(row);

      expect(post.id, equals(1));
      expect(post.title, equals('Hello World'));
      expect(post.createdAt, equals(DateTime(2024, 1, 15, 10, 30, 0)));
      expect(post.updatedAt, equals(DateTime(2024, 1, 16, 12, 0, 0)));
    });
  });

  group('User.fromRow - @BooleanField', () {
    test('should work with PostgreSQL (bool values)', () {
      final row = {
        'id': 1,
        'name': 'Alice',
        'is_active': true,
        'is_admin': false,
      };

      final user = User.fromRow(row);

      expect(user.id, equals(1));
      expect(user.name, equals('Alice'));
      expect(user.isActive, isTrue);
      expect(user.isAdmin, isFalse);
    });

    test('should work with PostgreSQL (null bool)', () {
      final row = {
        'id': 1,
        'name': 'Alice',
        'is_active': true,
        'is_admin': null,
      };

      final user = User.fromRow(row);

      expect(user.isAdmin, isNull);
    });

    test('should work with SQLite (int 0/1)', () {
      final row = {
        'id': 1,
        'name': 'Alice',
        'is_active': 1,
        'is_admin': 0,
      };

      final user = User.fromRow(row);

      expect(user.isActive, isTrue);
      expect(user.isAdmin, isFalse);
    });
  });

  group('Product.fromRow - @IntegerField / @FloatField', () {
    test('should work with native types', () {
      final row = {
        'id': 1,
        'name': 'Widget',
        'quantity': 100,
        'price': 19.99,
      };

      final product = Product.fromRow(row);

      expect(product.quantity, equals(100));
      expect(product.price, equals(19.99));
    });

    test('should work with double for int (some drivers)', () {
      final row = {
        'id': 1,
        'name': 'Widget',
        'quantity': 100.0, // Some drivers return double for numeric
        'price': 19.99,
      };

      final product = Product.fromRow(row);

      expect(product.quantity, equals(100));
    });

    test('should work with int for double (whole numbers)', () {
      final row = {
        'id': 1,
        'name': 'Widget',
        'quantity': 100,
        'price': 20, // Some drivers return int for whole numbers
      };

      final product = Product.fromRow(row);

      expect(product.price, equals(20.0));
    });

    test('should work with String values (some drivers)', () {
      final row = {
        'id': 1,
        'name': 'Widget',
        'quantity': '100',
        'price': '19.99',
      };

      final product = Product.fromRow(row);

      expect(product.quantity, equals(100));
      expect(product.price, equals(19.99));
    });
  });

  group('Integration with ModelExecutor', () {
    late SqliteAdapter adapter;
    late ConnectionPool pool;
    late SqlCompiler compiler;
    late ModelExecutor<Post> postExecutor;

    setUp(() async {
      final config = DatabaseConfig.sqliteMemory();
      adapter = const SqliteAdapter();
      pool = await adapter.createPool(config);
      compiler = SqlCompiler(adapter.dialect);

      await pool.withConnection((conn) async {
        await conn.execute('''
          CREATE TABLE posts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT
          )
        ''');
      });

      postExecutor = ModelExecutor<Post>(
        pool: pool,
        compiler: compiler,
        tableName: 'posts',
        pkField: 'id',
        fromRow: Post.fromRow,
        toRow: Post.toRow,
      );
    });

    tearDown(() async {
      await pool.close();
    });

    test('create and read back with SQLite', () async {
      final post = await postExecutor.create({
        'title': 'Test Post',
        'created_at': DateTime.now().toIso8601String(),
      });

      expect(post.id, isNotNull);
      expect(post.title, equals('Test Post'));
      expect(post.createdAt, isNotNull);
    });

    test('read existing records with SQLite', () async {
      await pool.withConnection((conn) async {
        await conn.execute('''
          INSERT INTO posts (title, created_at, updated_at)
          VALUES ('Post 1', '2024-01-15T10:30:00.000', '2024-01-16T12:00:00.000')
        ''');
      });

      final posts = await postExecutor.execute(const QueryConfig());

      expect(posts.length, equals(1));
      expect(posts[0].title, equals('Post 1'));
      expect(posts[0].createdAt, equals(DateTime(2024, 1, 15, 10, 30, 0)));
      expect(posts[0].updatedAt, equals(DateTime(2024, 1, 16, 12, 0, 0)));
    });
  });
}
