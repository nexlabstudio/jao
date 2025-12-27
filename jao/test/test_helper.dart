/// Test utilities and fixtures for JAO tests.
library;

import 'package:jao/jao.dart';

/// Creates an in-memory SQLite database for testing
Future<TestDatabase> createTestDb() async {
  final adapter = SqliteAdapter();
  final config = DatabaseConfig.sqliteMemory();
  final pool = await adapter.createPool(config);
  return TestDatabase(pool, adapter);
}

class TestDatabase {
  final ConnectionPool pool;
  final DatabaseAdapter adapter;

  TestDatabase(this.pool, this.adapter);

  Future<void> close() => pool.close();
}

/// Run migrations for test models
Future<void> setupTestSchema(TestDatabase db) async {
  await db.pool.withConnection((conn) async {
    // Create test_users table
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS test_users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        age INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create test_posts table
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS test_posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        author_id INTEGER NOT NULL,
        is_published INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (author_id) REFERENCES test_users(id) ON DELETE CASCADE
      )
    ''');
  });
}

/// Clear all test data
Future<void> clearTestData(TestDatabase db) async {
  await db.pool.withConnection((conn) async {
    await conn.execute('DELETE FROM test_posts');
    await conn.execute('DELETE FROM test_users');
  });
}
