/// Database configuration.
///
/// This is the single source of truth for database settings.
/// Used by both the migration CLI and the application runtime.
library;

import 'package:jao/jao.dart';

/// Database configuration.
final databaseConfig = DatabaseConfig.sqlite('hospitable-cook.db');

/// Database adapter.
const databaseAdapter = SqliteAdapter();

// PostgreSQL example:
// final databaseConfig = DatabaseConfig.postgres(
//   database: 'myapp',
//   username: String.fromEnvironment('DB_USER', defaultValue: 'postgres'),
//   password: String.fromEnvironment('DB_PASSWORD', defaultValue: 'password'),
// );
// const databaseAdapter = PostgresAdapter();

// MySQL example:
// final databaseConfig = DatabaseConfig.mysql(
//   database: 'myapp',
//   username: String.fromEnvironment('DB_USER', defaultValue: 'root'),
//   password: String.fromEnvironment('DB_PASSWORD', defaultValue: 'password'),
// );
// const databaseAdapter = MySqlAdapter();
