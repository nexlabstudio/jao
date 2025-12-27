/// Example database setup and migration runner usage.
///
/// This shows how to configure a database connection and run migrations
/// with fully functional database adapters.
library;

import 'package:dartonic/dartonic.dart';
import 'migrations/migrations.dart';

/// Main entry point - demonstrates database operations with real adapters.
Future<void> main() async {
  print('Dartonic ORM - Database Examples');
  print('=================================\n');

  // Run SQLite example (works without external database)
  await sqliteExample();

  // Show PostgreSQL and MySQL examples (requires running databases)
  print('\n--- PostgreSQL Configuration Example ---');
  postgresExample();

  print('\n--- MySQL Configuration Example ---');
  mysqlExample();

  // Show migration SQL generation
  print('\n--- Migration SQL Generation ---');
  showMigrationSql();
}

/// SQLite example - fully functional with in-memory database.
Future<void> sqliteExample() async {
  print('--- SQLite In-Memory Example ---\n');

  // Configure SQLite in-memory database
  final config = DatabaseConfig.sqliteMemory();
  final adapter = SqliteAdapter();

  // Connect to database
  final conn = await adapter.connect(config);

  try {
    // Create a table
    await conn.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        age INTEGER,
        is_active INTEGER DEFAULT 1,
        created_at TEXT DEFAULT (datetime('now'))
      )
    ''');
    print('✓ Created users table');

    // Insert some data
    await conn.execute('INSERT INTO users (name, email, age) VALUES (?, ?, ?)', ['Alice', 'alice@example.com', 30]);
    await conn.execute('INSERT INTO users (name, email, age) VALUES (?, ?, ?)', ['Bob', 'bob@example.com', 25]);
    await conn.execute('INSERT INTO users (name, email, age) VALUES (?, ?, ?)', ['Charlie', 'charlie@example.com', 35]);
    print('✓ Inserted 3 users');

    // Query all users
    final allUsers = await conn.query('SELECT * FROM users ORDER BY name');
    print('\nAll users:');
    for (final user in allUsers) {
      print('  ${user['id']}: ${user['name']} (${user['email']}) - age ${user['age']}');
    }

    // Query with filter
    final adults = await conn.query('SELECT * FROM users WHERE age >= ? ORDER BY age DESC', [30]);
    print('\nUsers age >= 30:');
    for (final user in adults) {
      print('  ${user['name']}: ${user['age']}');
    }

    // Aggregate query
    final stats = await conn.query('''
      SELECT 
        COUNT(*) as count,
        AVG(age) as avg_age,
        MIN(age) as min_age,
        MAX(age) as max_age
      FROM users
    ''');
    final s = stats.first;
    print('\nUser statistics:');
    print('  Count: ${s['count']}');
    print('  Average age: ${s['avg_age']}');
    print('  Age range: ${s['min_age']} - ${s['max_age']}');

    // Transaction example
    final tx = await conn.beginTransaction();
    try {
      await tx.execute('UPDATE users SET age = age + 1 WHERE name = ?', ['Alice']);
      await tx.execute('INSERT INTO users (name, email, age) VALUES (?, ?, ?)', ['Diana', 'diana@example.com', 28]);
      await tx.commit();
      print('\n✓ Transaction committed');
    } catch (e) {
      await tx.rollback();
      print('\n✗ Transaction rolled back: $e');
    }

    // Verify transaction results
    final updatedAlice = await conn.query('SELECT age FROM users WHERE name = ?', ['Alice']);
    print('  Alice new age: ${updatedAlice.first['age']}');

    final diana = await conn.query('SELECT * FROM users WHERE name = ?', ['Diana']);
    print('  Diana added: ${diana.isNotEmpty}');

    // Table introspection
    final tables = await adapter.getTables(conn);
    print('\nTables in database: ${tables.join(', ')}');

    final schema = await adapter.getTableSchema(conn, 'users');
    print('Users table schema:');
    for (final col in schema.columns) {
      final pk = col.isPrimaryKey ? ' [PK]' : '';
      final nullable = col.nullable ? '' : ' NOT NULL';
      print('  ${col.name}: ${col.type}$nullable$pk');
    }
  } finally {
    await conn.close();
    print('\n✓ Connection closed');
  }
}

/// PostgreSQL configuration example.
void postgresExample() {
  // From individual settings
  final config1 = DatabaseConfig(
    host: 'localhost',
    port: 5432,
    database: 'myapp',
    username: 'postgres',
    password: 'secret',
    useSsl: false,
    minConnections: 2,
    maxConnections: 10,
  );

  // From connection URL
  final config2 = DatabaseConfig.fromUrl('postgres://user:pass@localhost:5432/mydb?sslmode=require');

  print('Config 1: ${config1.toUrl('postgres')}');
  print('Config 2: host=${config2.host}, db=${config2.database}');

  print('''

To connect to PostgreSQL:

  final adapter = PostgresAdapter();
  final pool = await adapter.createPool(config);
  
  await pool.withConnection((conn) async {
    final users = await conn.query('SELECT * FROM users');
    // ...
  });
  
  await pool.close();
''');
}

/// MySQL configuration example.
void mysqlExample() {
  final config = DatabaseConfig(
    host: 'localhost',
    port: 3306,
    database: 'myapp',
    username: 'root',
    password: 'password',
  );

  print('Config: ${config.host}:${config.port}/${config.database}');

  print('''

To connect to MySQL:

  final adapter = MySqlAdapter();
  final pool = await adapter.createPool(config);
  
  await pool.withTransaction((tx) async {
    await tx.execute('INSERT INTO users (name) VALUES (?)', ['Alice']);
    await tx.execute('INSERT INTO users (name) VALUES (?)', ['Bob']);
  });
  
  await pool.close();
''');
}

/// Show SQL generated by migrations.
void showMigrationSql() {
  final adapters = {'PostgreSQL': PostgresAdapter(), 'MySQL': MySqlAdapter(), 'SQLite': SqliteAdapter()};

  final migration = Migration001Initial();

  for (final entry in adapters.entries) {
    print('\n${entry.key} SQL for ${migration.name}:');
    print('-' * 40);

    final builder = MigrationBuilder();
    migration.up(builder);

    for (final operation in builder.operations.take(2)) {
      // Show first 2 operations
      final sql = operation.toSql(entry.value.dialect);
      print(sql);
      print(';');
    }
    print('... (${builder.operations.length} operations total)');
  }
}

/// Full connection pool example.
Future<void> connectionPoolExample() async {
  final config = DatabaseConfig(
    host: 'localhost',
    port: 5432,
    database: 'myapp',
    username: 'postgres',
    password: 'secret',
    minConnections: 2,
    maxConnections: 10,
  );

  final adapter = PostgresAdapter();

  // Create pool
  final pool = await adapter.createPool(config);

  try {
    print('Pool size: ${pool.size}');
    print('Available: ${pool.available}');
    print('In use: ${pool.inUse}');

    // Use connection with automatic release
    await pool.withConnection((conn) async {
      final result = await conn.query('SELECT NOW() as now');
      print('Server time: ${result.first['now']}');
    });

    // Transaction with automatic commit/rollback
    await pool.withTransaction((tx) async {
      await tx.execute('INSERT INTO logs (message) VALUES (?)', ['Event 1']);
      await tx.execute('INSERT INTO logs (message) VALUES (?)', ['Event 2']);
      // Automatically commits if no exception
    });

    // Manual connection management
    final conn = await pool.acquire();
    try {
      await conn.execute('UPDATE stats SET views = views + 1 WHERE page = ?', ['/home']);
    } finally {
      await pool.release(conn);
    }
  } finally {
    await pool.close();
  }
}
