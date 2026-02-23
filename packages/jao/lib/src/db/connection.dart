/// Database connection and adapter interfaces.
///
/// Adapters provide database-specific implementations for query execution,
/// schema operations, and SQL generation.
library;

import 'dart:async';
import 'package:meta/meta.dart';

/// Configuration for a database connection.
@immutable
class DatabaseConfig {
  /// Database host
  final String host;

  /// Database port
  final int port;

  /// Database name
  final String database;

  /// Username for authentication
  final String? username;

  /// Password for authentication
  final String? password;

  /// Whether to use SSL
  final bool useSsl;

  /// Connection pool minimum size
  final int minConnections;

  /// Connection pool maximum size
  final int maxConnections;

  /// Connection timeout in seconds
  final int connectTimeout;

  /// Query timeout in seconds
  final int queryTimeout;

  /// Additional driver-specific options
  final Map<String, dynamic> options;

  const DatabaseConfig({
    required this.host,
    required this.port,
    required this.database,
    this.username,
    this.password,
    this.useSsl = false,
    this.minConnections = 1,
    this.maxConnections = 10,
    this.connectTimeout = 30,
    this.queryTimeout = 30,
    this.options = const {},
  });

  /// Create config for SQLite file database
  factory DatabaseConfig.sqlite(String path) => DatabaseConfig(host: path, port: 0, database: path);

  /// Create config for SQLite in-memory database
  factory DatabaseConfig.sqliteMemory() => DatabaseConfig(host: ':memory:', port: 0, database: ':memory:');

  /// Create config for PostgreSQL database
  factory DatabaseConfig.postgres({
    String host = 'localhost',
    int port = 5432,
    required String database,
    String? username,
    String? password,
    bool useSsl = false,
    int minConnections = 1,
    int maxConnections = 10,
  }) =>
      DatabaseConfig(
        host: host,
        port: port,
        database: database,
        username: username,
        password: password,
        useSsl: useSsl,
        minConnections: minConnections,
        maxConnections: maxConnections,
      );

  /// Create config for MySQL database
  factory DatabaseConfig.mysql({
    String host = 'localhost',
    int port = 3306,
    required String database,
    String? username,
    String? password,
    bool useSsl = false,
    int minConnections = 1,
    int maxConnections = 10,
  }) =>
      DatabaseConfig(
        host: host,
        port: port,
        database: database,
        username: username,
        password: password,
        useSsl: useSsl,
        minConnections: minConnections,
        maxConnections: maxConnections,
      );

  /// Create config from connection URL
  factory DatabaseConfig.fromUrl(String url) {
    final uri = Uri.parse(url);
    return DatabaseConfig(
      host: uri.host,
      port: uri.port,
      database: uri.path.replaceFirst('/', ''),
      username: uri.userInfo.split(':').firstOrNull,
      password: uri.userInfo.contains(':') ? uri.userInfo.split(':').last : null,
      useSsl: uri.queryParameters['sslmode'] == 'require',
    );
  }

  /// Convert to connection URL
  String toUrl(String scheme) {
    final auth = username != null ? '$username${password != null ? ':$password' : ''}@' : '';
    return '$scheme://$auth$host:$port/$database';
  }
}

/// Result of a database query.
@immutable
class QueryResult {
  /// Rows returned by the query
  final List<Map<String, dynamic>> rows;

  /// Number of rows affected (for INSERT/UPDATE/DELETE)
  final int affectedRows;

  /// Last inserted ID (for INSERT)
  final Object? lastInsertId;

  /// Column names in result order
  final List<String> columns;

  const QueryResult({this.rows = const [], this.affectedRows = 0, this.lastInsertId, this.columns = const []});

  bool get isEmpty => rows.isEmpty;
  bool get isNotEmpty => rows.isNotEmpty;
  int get length => rows.length;

  Map<String, dynamic>? get first => rows.firstOrNull;
  Map<String, dynamic>? get single => rows.length == 1 ? rows.first : null;

  /// Get a single column value from first row
  T? value<T>(String column) => first?[column] as T?;
}

/// Abstract database connection.
abstract class DatabaseConnection {
  /// Whether the connection is open
  bool get isOpen;

  /// Execute a raw SQL query
  Future<QueryResult> execute(String sql, [List<Object?>? params]);

  /// Execute a query and return rows
  Future<List<Map<String, dynamic>>> query(String sql, [List<Object?>? params]);

  /// Execute a query and return single value
  Future<T?> scalar<T>(String sql, [List<Object?>? params]);

  /// Begin a transaction
  Future<Transaction> beginTransaction();

  /// Close the connection
  Future<void> close();
}

/// Database transaction.
abstract class Transaction {
  /// Execute a query within this transaction
  Future<QueryResult> execute(String sql, [List<Object?>? params]);

  /// Commit the transaction
  Future<void> commit();

  /// Rollback the transaction
  Future<void> rollback();

  /// Create a savepoint with the given name
  Future<void> savepoint(String name);

  /// Rollback to a previously created savepoint
  Future<void> rollbackToSavepoint(String name);

  /// Release (remove) a savepoint
  Future<void> releaseSavepoint(String name);

  /// Whether the transaction is still active
  bool get isActive;
}

/// Connection pool for managing multiple connections.
abstract class ConnectionPool {
  /// Get a connection from the pool
  Future<DatabaseConnection> acquire();

  /// Return a connection to the pool
  Future<void> release(DatabaseConnection connection);

  /// Execute with automatic connection management
  Future<T> withConnection<T>(Future<T> Function(DatabaseConnection conn) fn);

  /// Execute within a transaction
  Future<T> withTransaction<T>(Future<T> Function(Transaction tx) fn);

  /// Close all connections in the pool
  Future<void> close();

  /// Number of available connections
  int get available;

  /// Number of connections in use
  int get inUse;

  /// Total pool size
  int get size;
}

/// Database adapter interface.
///
/// Each database type (PostgreSQL, MySQL, SQLite) implements this
/// to provide database-specific behavior.
abstract class DatabaseAdapter {
  /// The database type identifier
  String get name;

  /// The SQL dialect this adapter uses
  SqlDialect get dialect;

  /// Create a connection pool
  Future<ConnectionPool> createPool(DatabaseConfig config);

  /// Create a single connection
  Future<DatabaseConnection> connect(DatabaseConfig config);

  /// Check if the database exists
  Future<bool> databaseExists(DatabaseConfig config);

  /// Create the database
  Future<void> createDatabase(DatabaseConfig config);

  /// Drop the database
  Future<void> dropDatabase(DatabaseConfig config);

  /// Get list of table names
  Future<List<String>> getTables(DatabaseConnection conn);

  /// Get table schema information
  Future<TableSchema> getTableSchema(DatabaseConnection conn, String table);

  /// Check if a table exists
  Future<bool> tableExists(DatabaseConnection conn, String table);
}

/// SQL dialect differences between databases.
abstract class SqlDialect {
  /// Parameter placeholder style
  String parameterPlaceholder(int index);

  /// Quote an identifier (table/column name)
  String quoteIdentifier(String name);

  /// Get the SQL type for a field type
  String sqlType(FieldType type);

  /// AUTO_INCREMENT or SERIAL syntax
  String autoIncrement();

  /// Boolean literal
  String booleanLiteral(bool value);

  /// Current timestamp function
  String currentTimestamp();

  /// String concatenation operator
  String concat(List<String> parts);

  /// LIMIT/OFFSET syntax
  String limitOffset(int? limit, int? offset);

  /// RETURNING clause support
  bool get supportsReturning;

  /// UPSERT syntax
  String upsert(String table, List<String> columns, List<String> conflictColumns);

  /// Case-insensitive LIKE expression.
  /// PostgreSQL uses ILIKE, SQLite uses LIKE with LOWER().
  String caseInsensitiveLike(String column, String param);
}

/// Represents a database field type for schema operations.
enum FieldType {
  // Integers
  smallInt,
  integer,
  bigInt,
  serial,
  bigSerial,

  // Floating point
  real,
  doublePrecision,
  decimal,

  // Strings
  varchar,
  text,
  char,

  // Binary
  bytea,
  blob,

  // Date/Time
  date,
  time,
  timestamp,
  timestampTz,
  interval,

  // Boolean
  boolean,

  // UUID
  uuid,

  // JSON
  json,
  jsonb,

  // Arrays (PostgreSQL)
  array,
}

/// Schema information for a table.
@immutable
class TableSchema {
  final String name;
  final List<ColumnSchema> columns;
  final List<IndexSchema> indexes;
  final List<ConstraintSchema> constraints;
  final String? primaryKey;

  const TableSchema({
    required this.name,
    required this.columns,
    this.indexes = const [],
    this.constraints = const [],
    this.primaryKey,
  });

  ColumnSchema? getColumn(String name) => columns.where((c) => c.name == name).firstOrNull;
}

/// Schema information for a column.
@immutable
class ColumnSchema {
  final String name;
  final String type;
  final bool nullable;
  final String? defaultValue;
  final bool isPrimaryKey;
  final bool isAutoIncrement;
  final int? maxLength;
  final int? precision;
  final int? scale;

  const ColumnSchema({
    required this.name,
    required this.type,
    this.nullable = true,
    this.defaultValue,
    this.isPrimaryKey = false,
    this.isAutoIncrement = false,
    this.maxLength,
    this.precision,
    this.scale,
  });
}

/// Schema information for an index.
@immutable
class IndexSchema {
  final String name;
  final List<String> columns;
  final bool unique;
  final String? type; // btree, hash, gin, etc.

  const IndexSchema({required this.name, required this.columns, this.unique = false, this.type});
}

/// Schema information for a constraint.
@immutable
class ConstraintSchema {
  final String name;
  final ConstraintType type;
  final List<String> columns;
  final String? referencedTable;
  final List<String>? referencedColumns;
  final String? onDelete;
  final String? onUpdate;

  const ConstraintSchema({
    required this.name,
    required this.type,
    required this.columns,
    this.referencedTable,
    this.referencedColumns,
    this.onDelete,
    this.onUpdate,
  });
}

enum ConstraintType { primaryKey, foreignKey, unique, check }
