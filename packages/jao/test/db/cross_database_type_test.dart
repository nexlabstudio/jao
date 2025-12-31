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
  final double? discount;

  Product({
    this.id,
    required this.name,
    required this.quantity,
    required this.price,
    this.discount,
  });

  // Updated to use type converters (matches new generator output)
  static Product fromRow(Map<String, dynamic> row) {
    return Product(
      id: dbIntOrNull(row['id']),
      name: row['name'] as String,
      quantity: dbInt(row['quantity']),
      price: dbDouble(row['price']),
      discount: dbDoubleOrNull(row['discount']),
    );
  }

  static Map<String, dynamic> toRow(Product product) {
    return {
      if (product.id != null) 'id': product.id,
      'name': product.name,
      'quantity': product.quantity,
      'price': product.price,
      if (product.discount != null) 'discount': product.discount,
    };
  }
}

// Test model with Duration field
class Task {
  final int? id;
  final String name;
  final Duration estimatedTime;
  final Duration? actualTime;

  Task({
    this.id,
    required this.name,
    required this.estimatedTime,
    this.actualTime,
  });

  static Task fromRow(Map<String, dynamic> row) {
    return Task(
      id: dbIntOrNull(row['id']),
      name: row['name'] as String,
      estimatedTime: dbDuration(row['estimated_time']),
      actualTime: dbDurationOrNull(row['actual_time']),
    );
  }

  static Map<String, dynamic> toRow(Task task) {
    return {
      if (task.id != null) 'id': task.id,
      'name': task.name,
      'estimated_time': task.estimatedTime.inMicroseconds,
      if (task.actualTime != null) 'actual_time': task.actualTime!.inMicroseconds,
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

  // Additional Post.fromRow tests for full DateTime coverage
  group('Post.fromRow - additional DateTime coverage', () {
    test('should work with unix timestamp (int milliseconds)', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30, 0).millisecondsSinceEpoch;
      final row = {
        'id': 1,
        'title': 'Hello World',
        'created_at': timestamp,
        'updated_at': null,
      };

      final post = Post.fromRow(row);

      expect(post.createdAt, equals(DateTime.fromMillisecondsSinceEpoch(timestamp)));
    });

    test('throws on null for non-nullable DateTime', () {
      final row = {
        'id': 1,
        'title': 'Hello World',
        'created_at': null,
        'updated_at': null,
      };

      expect(() => Post.fromRow(row), throwsArgumentError);
    });

    test('throws on unsupported type for DateTime', () {
      final row = {
        'id': 1,
        'title': 'Hello World',
        'created_at': [1, 2, 3], // unsupported type
        'updated_at': null,
      };

      expect(() => Post.fromRow(row), throwsArgumentError);
    });
  });

  // Additional User.fromRow tests for full bool coverage
  group('User.fromRow - additional bool coverage', () {
    test('should work with String "true"', () {
      final row = {
        'id': 1,
        'name': 'Alice',
        'is_active': 'true',
        'is_admin': 'TRUE',
      };

      final user = User.fromRow(row);

      expect(user.isActive, isTrue);
      expect(user.isAdmin, isTrue);
    });

    test('should work with String "1"', () {
      final row = {
        'id': 1,
        'name': 'Alice',
        'is_active': '1',
        'is_admin': null,
      };

      final user = User.fromRow(row);

      expect(user.isActive, isTrue);
    });

    test('should work with String "yes"', () {
      final row = {
        'id': 1,
        'name': 'Alice',
        'is_active': 'yes',
        'is_admin': 'YES',
      };

      final user = User.fromRow(row);

      expect(user.isActive, isTrue);
      expect(user.isAdmin, isTrue);
    });

    test('should work with String "false" and other values', () {
      final row = {
        'id': 1,
        'name': 'Alice',
        'is_active': 'false',
        'is_admin': 'anything',
      };

      final user = User.fromRow(row);

      expect(user.isActive, isFalse);
      expect(user.isAdmin, isFalse);
    });

    test('throws on null for non-nullable bool', () {
      final row = {
        'id': 1,
        'name': 'Alice',
        'is_active': null,
        'is_admin': null,
      };

      expect(() => User.fromRow(row), throwsArgumentError);
    });

    test('throws on unsupported type for bool', () {
      final row = {
        'id': 1,
        'name': 'Alice',
        'is_active': 3.14, // unsupported type
        'is_admin': null,
      };

      expect(() => User.fromRow(row), throwsArgumentError);
    });
  });

  // Additional Product.fromRow tests for full int/double coverage
  group('Product.fromRow - additional numeric coverage', () {
    test('throws on null for non-nullable int', () {
      final row = {
        'id': 1,
        'name': 'Widget',
        'quantity': null,
        'price': 19.99,
        'discount': null,
      };

      expect(() => Product.fromRow(row), throwsArgumentError);
    });

    test('throws on unsupported type for int', () {
      final row = {
        'id': 1,
        'name': 'Widget',
        'quantity': [1, 2, 3], // unsupported type
        'price': 19.99,
        'discount': null,
      };

      expect(() => Product.fromRow(row), throwsArgumentError);
    });

    test('throws on null for non-nullable double', () {
      final row = {
        'id': 1,
        'name': 'Widget',
        'quantity': 100,
        'price': null,
        'discount': null,
      };

      expect(() => Product.fromRow(row), throwsArgumentError);
    });

    test('throws on unsupported type for double', () {
      final row = {
        'id': 1,
        'name': 'Widget',
        'quantity': 100,
        'price': [1, 2, 3], // unsupported type
        'discount': null,
      };

      expect(() => Product.fromRow(row), throwsArgumentError);
    });

    test('should work with nullable double (null)', () {
      final row = {
        'id': 1,
        'name': 'Widget',
        'quantity': 100,
        'price': 19.99,
        'discount': null,
      };

      final product = Product.fromRow(row);

      expect(product.discount, isNull);
    });

    test('should work with nullable double (value)', () {
      final row = {
        'id': 1,
        'name': 'Widget',
        'quantity': 100,
        'price': 19.99,
        'discount': 5.0,
      };

      final product = Product.fromRow(row);

      expect(product.discount, equals(5.0));
    });

    test('should work with nullable double from int', () {
      final row = {
        'id': 1,
        'name': 'Widget',
        'quantity': 100,
        'price': 19.99,
        'discount': 5,
      };

      final product = Product.fromRow(row);

      expect(product.discount, equals(5.0));
    });

    test('should work with nullable double from String', () {
      final row = {
        'id': 1,
        'name': 'Widget',
        'quantity': 100,
        'price': 19.99,
        'discount': '5.5',
      };

      final product = Product.fromRow(row);

      expect(product.discount, equals(5.5));
    });
  });

  // Task.fromRow tests for Duration coverage
  group('Task.fromRow - @DurationField', () {
    test('should work with Duration (PostgreSQL)', () {
      final duration = Duration(hours: 1, minutes: 30);
      final row = {
        'id': 1,
        'name': 'Task 1',
        'estimated_time': duration,
        'actual_time': Duration(hours: 2),
      };

      final task = Task.fromRow(row);

      expect(task.estimatedTime, equals(duration));
      expect(task.actualTime, equals(Duration(hours: 2)));
    });

    test('should work with int (microseconds from SQLite)', () {
      final micros = 5400000000; // 1.5 hours
      final row = {
        'id': 1,
        'name': 'Task 1',
        'estimated_time': micros,
        'actual_time': 7200000000,
      };

      final task = Task.fromRow(row);

      expect(task.estimatedTime, equals(Duration(microseconds: micros)));
      expect(task.actualTime, equals(Duration(hours: 2)));
    });

    test('should work with String (microseconds)', () {
      final row = {
        'id': 1,
        'name': 'Task 1',
        'estimated_time': '5400000000',
        'actual_time': null,
      };

      final task = Task.fromRow(row);

      expect(task.estimatedTime, equals(Duration(microseconds: 5400000000)));
      expect(task.actualTime, isNull);
    });

    test('should work with null for nullable Duration', () {
      final row = {
        'id': 1,
        'name': 'Task 1',
        'estimated_time': Duration(hours: 1),
        'actual_time': null,
      };

      final task = Task.fromRow(row);

      expect(task.actualTime, isNull);
    });

    test('throws on invalid String for Duration', () {
      final row = {
        'id': 1,
        'name': 'Task 1',
        'estimated_time': 'not-a-number',
        'actual_time': null,
      };

      expect(() => Task.fromRow(row), throwsArgumentError);
    });

    test('throws on null for non-nullable Duration', () {
      final row = {
        'id': 1,
        'name': 'Task 1',
        'estimated_time': null,
        'actual_time': null,
      };

      expect(() => Task.fromRow(row), throwsArgumentError);
    });

    test('throws on unsupported type for Duration', () {
      final row = {
        'id': 1,
        'name': 'Task 1',
        'estimated_time': 3.14, // unsupported type
        'actual_time': null,
      };

      expect(() => Task.fromRow(row), throwsArgumentError);
    });
  });
}
