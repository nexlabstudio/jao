/// Database initialization for the Dart Frog API.
library;

import 'package:dartonic/dartonic.dart';

/// Initialize the SQLite database connection.
///
/// Run migrations separately via the CLI:
/// ```
/// dartonic migrate
/// ```
Future<void> initializeDatabase() async {
  const adapter = SqliteAdapter();
  final config = DatabaseConfig.sqlite('database.db');
  final pool = await adapter.createPool(config);

  await Dartonic.configure(pool: pool, compiler: SqlCompiler(adapter.dialect));
}

/// Close the database connection.
Future<void> closeDatabase() async {
  if (Dartonic.isInitialized) {
    await Dartonic.instance.pool.close();
  }
}
