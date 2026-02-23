import 'package:jao/jao.dart';
import 'package:test/test.dart';

class User {
  final int? id;
  final String name;

  User({this.id, required this.name});

  static User fromRow(Map<String, dynamic> row) =>
      User(id: row['id'] as int?, name: row['name'] as String);

  static Map<String, dynamic> toRow(User u) => {
        if (u.id != null) 'id': u.id,
        'name': u.name,
      };
}

class Order {
  final int? id;
  final int userId;
  final int total;

  Order({this.id, required this.userId, required this.total});

  static Order fromRow(Map<String, dynamic> row) => Order(
        id: row['id'] as int?,
        userId: row['user_id'] as int,
        total: row['total'] as int,
      );

  static Map<String, dynamic> toRow(Order o) => {
        if (o.id != null) 'id': o.id,
        'user_id': o.userId,
        'total': o.total,
      };
}

Future<ConnectionPool> _configureJao() async {
  Jao.reset();
  await Jao.configure(
    adapter: const SqliteAdapter(),
    config: DatabaseConfig.sqliteMemory(),
  );

  final pool = Jao.instance.pool;

  await pool.withConnection((conn) async {
    await conn.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');
    await conn.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        total INTEGER NOT NULL
      )
    ''');
  });

  Jao.registerModel<User>(ModelRegistration<User>(
    tableName: 'users',
    pkField: 'id',
    fromRow: User.fromRow,
    toRow: User.toRow,
  ));

  Jao.registerModel<Order>(ModelRegistration<Order>(
    tableName: 'orders',
    pkField: 'id',
    fromRow: Order.fromRow,
    toRow: Order.toRow,
  ));

  return pool;
}

void main() {
  group('Jao.transaction() — multi-model', () {
    late ConnectionPool pool;
    late ModelExecutor<User> userExecutor;
    late ModelExecutor<Order> orderExecutor;

    setUp(() async {
      pool = await _configureJao();
      userExecutor = Jao.instance.executor<User>()!;
      orderExecutor = Jao.instance.executor<Order>()!;
    });

    tearDown(() async {
      await pool.close();
      Jao.reset();
    });

    test('commits all models atomically on success', () async {
      await Jao.instance.transaction((tx) async {
        final user = await tx.on<User>().create({'name': 'Alice'});
        await tx.on<Order>().create({'user_id': user.id, 'total': 100});
      });

      expect(await userExecutor.count(const QueryConfig()), equals(1));
      expect(await orderExecutor.count(const QueryConfig()), equals(1));
    });

    test('rolls back all models on error', () async {
      try {
        await Jao.instance.transaction((tx) async {
          await tx.on<User>().create({'name': 'Alice'});
          throw Exception('simulated failure');
        });
      } catch (_) {}

      expect(await userExecutor.count(const QueryConfig()), equals(0));
      expect(await orderExecutor.count(const QueryConfig()), equals(0));
    });

    test('rolls back partial work across multiple models', () async {
      await userExecutor.create({'name': 'Pre-existing'});

      try {
        await Jao.instance.transaction((tx) async {
          await tx.on<User>().create({'name': 'Alice'});
          await tx.on<Order>().create({'user_id': 1, 'total': 50});
          throw Exception('simulated failure');
        });
      } catch (_) {}

      // Only the pre-existing user survives
      expect(await userExecutor.count(const QueryConfig()), equals(1));
      expect(await orderExecutor.count(const QueryConfig()), equals(0));
    });

    test('uncommitted changes are visible within the same transaction',
        () async {
      await Jao.instance.transaction((tx) async {
        final user = await tx.on<User>().create({'name': 'Alice'});
        await tx.on<Order>().create({'user_id': user.id, 'total': 99});

        final users = await tx.on<User>().query(const QueryConfig());
        final orders = await tx.on<Order>().query(const QueryConfig());

        expect(users.length, equals(1));
        expect(orders.length, equals(1));
      });
    });

    test('throws StateError for unregistered model type', () async {
      await expectLater(Jao.instance.transaction((tx) async {
        tx.on<String>();
      }), throwsStateError);
    });
  });

  group('JaoTransaction.savepoint()', () {
    late ConnectionPool pool;
    late ModelExecutor<User> userExecutor;
    late ModelExecutor<Order> orderExecutor;

    setUp(() async {
      pool = await _configureJao();
      userExecutor = Jao.instance.executor<User>()!;
      orderExecutor = Jao.instance.executor<Order>()!;
    });

    tearDown(() async {
      await pool.close();
      Jao.reset();
    });

    test('commits savepoint work when block succeeds', () async {
      await Jao.instance.transaction((tx) async {
        final user = await tx.on<User>().create({'name': 'Alice'});

        await tx.savepoint((tx) async {
          await tx.on<Order>().create({'user_id': user.id, 'total': 50});
        });
      });

      expect(await userExecutor.count(const QueryConfig()), equals(1));
      expect(await orderExecutor.count(const QueryConfig()), equals(1));
    });

    test('rolls back only savepoint work when exception is caught', () async {
      await Jao.instance.transaction((tx) async {
        final user = await tx.on<User>().create({'name': 'Alice'});

        try {
          await tx.savepoint((tx) async {
            await tx.on<Order>().create({'user_id': user.id, 'total': 50});
            throw Exception('savepoint failure');
          });
        } catch (_) {}
        // Alice's create is still alive; order was rolled back
      });

      expect(await userExecutor.count(const QueryConfig()), equals(1));
      expect(await orderExecutor.count(const QueryConfig()), equals(0));
    });

    test('propagates error to outer transaction when exception is not caught',
        () async {
      try {
        await Jao.instance.transaction((tx) async {
          await tx.on<User>().create({'name': 'Alice'});

          await tx.savepoint((tx) async {
            await tx.on<Order>().create({'user_id': 1, 'total': 50});
            throw Exception('uncaught savepoint failure');
          });
        });
      } catch (_) {}

      // Entire transaction rolled back
      expect(await userExecutor.count(const QueryConfig()), equals(0));
      expect(await orderExecutor.count(const QueryConfig()), equals(0));
    });

    test('multiple sequential savepoints each roll back independently',
        () async {
      await Jao.instance.transaction((tx) async {
        final user = await tx.on<User>().create({'name': 'Alice'});

        // First savepoint succeeds
        await tx.savepoint((tx) async {
          await tx.on<Order>().create({'user_id': user.id, 'total': 10});
        });

        // Second savepoint fails and is caught
        try {
          await tx.savepoint((tx) async {
            await tx.on<Order>().create({'user_id': user.id, 'total': 20});
            throw Exception('second savepoint fails');
          });
        } catch (_) {}
      });

      expect(await userExecutor.count(const QueryConfig()), equals(1));
      // Only the first savepoint's order survives
      final orders = await orderExecutor.execute(const QueryConfig());
      expect(orders.length, equals(1));
      expect(orders[0].total, equals(10));
    });

    test('nested savepoints: inner rollback does not affect outer savepoint',
        () async {
      await Jao.instance.transaction((tx) async {
        final user = await tx.on<User>().create({'name': 'Alice'});

        await tx.savepoint((tx) async {
          await tx.on<Order>().create({'user_id': user.id, 'total': 100});

          try {
            await tx.savepoint((tx) async {
              await tx.on<Order>().create({'user_id': user.id, 'total': 999});
              throw Exception('inner savepoint fails');
            });
          } catch (_) {}
          // Outer savepoint continues; inner work was rolled back
        });
      });

      expect(await userExecutor.count(const QueryConfig()), equals(1));
      final orders = await orderExecutor.execute(const QueryConfig());
      expect(orders.length, equals(1));
      expect(orders[0].total, equals(100));
    });

    test('optional name parameter does not affect commit behaviour', () async {
      await Jao.instance.transaction((tx) async {
        final user = await tx.on<User>().create({'name': 'Alice'});

        await tx.savepoint(
          (tx) async {
            await tx.on<Order>().create({'user_id': user.id, 'total': 42});
          },
          name: 'create_order',
        );
      });

      expect(await orderExecutor.count(const QueryConfig()), equals(1));
    });

    test('optional name parameter does not affect rollback behaviour',
        () async {
      await Jao.instance.transaction((tx) async {
        final user = await tx.on<User>().create({'name': 'Alice'});

        try {
          await tx.savepoint(
            (tx) async {
              await tx.on<Order>().create({'user_id': user.id, 'total': 42});
              throw Exception('named savepoint fails');
            },
            name: 'create_order',
          );
        } catch (_) {}
      });

      expect(await userExecutor.count(const QueryConfig()), equals(1));
      expect(await orderExecutor.count(const QueryConfig()), equals(0));
    });
  });
}
