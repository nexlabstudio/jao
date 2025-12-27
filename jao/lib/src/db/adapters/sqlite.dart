/// SQLite database adapter.
///
/// Provides SQLite-specific SQL generation and database operations
/// using the `sqlite3` package.
library;

import 'dart:async';
import 'dart:io';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import '../connection.dart';

/// SQLite SQL dialect.
class SqliteDialect implements SqlDialect {
  const SqliteDialect();

  @override
  String parameterPlaceholder(int index) => '?$index';

  @override
  String quoteIdentifier(String name) => '"$name"';

  @override
  String sqlType(FieldType type) => switch (type) {
    FieldType.smallInt => 'INTEGER',
    FieldType.integer => 'INTEGER',
    FieldType.bigInt => 'INTEGER',
    FieldType.serial => 'INTEGER PRIMARY KEY AUTOINCREMENT',
    FieldType.bigSerial => 'INTEGER PRIMARY KEY AUTOINCREMENT',
    FieldType.real => 'REAL',
    FieldType.doublePrecision => 'REAL',
    FieldType.decimal => 'REAL',
    FieldType.varchar => 'TEXT',
    FieldType.text => 'TEXT',
    FieldType.char => 'TEXT',
    FieldType.bytea => 'BLOB',
    FieldType.blob => 'BLOB',
    FieldType.date => 'TEXT',
    FieldType.time => 'TEXT',
    FieldType.timestamp => 'TEXT',
    FieldType.timestampTz => 'TEXT',
    FieldType.interval => 'TEXT',
    FieldType.boolean => 'INTEGER',
    FieldType.uuid => 'TEXT',
    FieldType.json => 'TEXT',
    FieldType.jsonb => 'TEXT',
    FieldType.array => 'TEXT',
  };

  @override
  String autoIncrement() => 'AUTOINCREMENT';

  @override
  String booleanLiteral(bool value) => value ? '1' : '0';

  @override
  String currentTimestamp() => "datetime('now')";

  @override
  String concat(List<String> parts) => parts.join(' || ');

  @override
  String limitOffset(int? limit, int? offset) {
    if (limit == null && offset == null) return '';
    if (limit != null && offset == null) return ' LIMIT $limit';
    if (limit == null && offset != null) {
      return ' LIMIT -1 OFFSET $offset';
    }
    return ' LIMIT $limit OFFSET $offset';
  }

  @override
  bool get supportsReturning => true; // SQLite 3.35.0+

  @override
  String upsert(String table, List<String> columns, List<String> conflictColumns) {
    final conflictCols = conflictColumns.map(quoteIdentifier).join(', ');
    final updateCols = columns
        .where((c) => !conflictColumns.contains(c))
        .map((c) => '${quoteIdentifier(c)} = excluded.${quoteIdentifier(c)}')
        .join(', ');
    return 'ON CONFLICT ($conflictCols) DO UPDATE SET $updateCols';
  }

  @override
  String caseInsensitiveLike(String column, String param) {
    // SQLite LIKE is case-insensitive for ASCII by default, but use LOWER for consistency
    return 'LOWER($column) LIKE LOWER($param)';
  }
}

/// SQLite database connection implementation.
class SqliteConnection implements DatabaseConnection {
  final sqlite.Database _db;
  final String _path;
  bool _isOpen = true;

  SqliteConnection._(this._db, this._path);

  /// The path to the database file (or ':memory:' for in-memory databases).
  String get path => _path;

  /// Create a new connection from config.
  static Future<SqliteConnection> connect(DatabaseConfig config) async {
    final path = config.database;

    // Handle in-memory database
    if (path == ':memory:') {
      final db = sqlite.sqlite3.openInMemory();
      return SqliteConnection._(db, path);
    }

    // Open file-based database
    final db = sqlite.sqlite3.open(path);

    // Enable foreign keys
    db.execute('PRAGMA foreign_keys = ON');

    // Enable WAL mode for better concurrency
    db.execute('PRAGMA journal_mode = DELETE');

    return SqliteConnection._(db, path);
  }

  @override
  bool get isOpen => _isOpen;

  @override
  Future<QueryResult> execute(String sql, [List<Object?>? params]) async {
    try {
      // Convert positional params to SQLite format
      final convertedSql = _convertPlaceholders(sql);
      final convertedParams = _convertParams(params);

      final stmt = _db.prepare(convertedSql);
      try {
        final result = stmt.select(convertedParams);

        final rows = <Map<String, dynamic>>[];
        final columns = result.columnNames;

        for (final row in result) {
          final map = <String, dynamic>{};
          for (var i = 0; i < columns.length; i++) {
            map[columns[i]] = _convertValue(row[i]);
          }
          rows.add(map);
        }

        return QueryResult(
          rows: rows,
          columns: columns,
          affectedRows: _db.updatedRows,
          lastInsertId: _db.lastInsertRowId,
        );
      } finally {
        stmt.dispose();
      }
    } catch (e) {
      throw SqliteException('Query execution failed: $e', sql: sql, database: _path);
    }
  }

  /// Execute without returning results (for INSERT/UPDATE/DELETE).
  Future<QueryResult> executeUpdate(String sql, [List<Object?>? params]) async {
    try {
      final convertedSql = _convertPlaceholders(sql);
      final convertedParams = _convertParams(params);

      final stmt = _db.prepare(convertedSql);
      try {
        stmt.execute(convertedParams);

        return QueryResult(affectedRows: _db.updatedRows, lastInsertId: _db.lastInsertRowId);
      } finally {
        stmt.dispose();
      }
    } catch (e) {
      throw SqliteException('Query execution failed: $e', sql: sql, database: _path);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> query(String sql, [List<Object?>? params]) async {
    final result = await execute(sql, params);
    return result.rows;
  }

  @override
  Future<T?> scalar<T>(String sql, [List<Object?>? params]) async {
    final result = await query(sql, params);
    if (result.isEmpty) return null;
    final firstRow = result.first;
    if (firstRow.isEmpty) return null;
    return firstRow.values.first as T?;
  }

  @override
  Future<SqliteTransaction> beginTransaction() async {
    _db.execute('BEGIN TRANSACTION');
    return SqliteTransaction._(_db, _path);
  }

  @override
  Future<void> close() async {
    _db.dispose();
    _isOpen = false;
  }

  /// Convert $1, $2 or ?1, ?2 style to ? placeholders.
  String _convertPlaceholders(String sql) {
    // SQLite uses ? or ?NNN or :name or @name or $name
    // We'll convert $1, $2 style to simple ?
    var result = sql;

    // First, convert $N to ?
    result = result.replaceAllMapped(RegExp(r'\$(\d+)'), (match) => '?');

    // Also convert ?N to ?
    result = result.replaceAllMapped(RegExp(r'\?(\d+)'), (match) => '?');

    return result;
  }

  /// Convert Dart parameters to SQLite-compatible values.
  List<Object?> _convertParams(List<Object?>? params) {
    if (params == null) return [];
    return params.map((p) {
      if (p == null) return null;
      if (p is bool) return p ? 1 : 0;
      if (p is DateTime) return p.toIso8601String();
      if (p is Duration) return p.inMicroseconds;
      return p;
    }).toList();
  }

  /// Convert SQLite values back to Dart types.
  Object? _convertValue(Object? value) {
    // SQLite returns int, double, String, Uint8List, or null
    return value;
  }
}

/// SQLite transaction implementation.
class SqliteTransaction implements Transaction {
  final sqlite.Database _db;
  final String _path;
  bool _isActive = true;

  SqliteTransaction._(this._db, this._path);

  @override
  bool get isActive => _isActive;

  @override
  Future<QueryResult> execute(String sql, [List<Object?>? params]) async {
    if (!_isActive) {
      throw StateError('Transaction is no longer active');
    }

    try {
      final convertedSql = _convertPlaceholders(sql);
      final convertedParams = _convertParams(params);

      final stmt = _db.prepare(convertedSql);
      try {
        final result = stmt.select(convertedParams);

        final rows = <Map<String, dynamic>>[];
        final columns = result.columnNames;

        for (final row in result) {
          final map = <String, dynamic>{};
          for (var i = 0; i < columns.length; i++) {
            map[columns[i]] = row[i];
          }
          rows.add(map);
        }

        return QueryResult(
          rows: rows,
          columns: columns,
          affectedRows: _db.updatedRows,
          lastInsertId: _db.lastInsertRowId,
        );
      } finally {
        stmt.dispose();
      }
    } catch (e) {
      throw SqliteException('Transaction query failed: $e', sql: sql, database: _path);
    }
  }

  @override
  Future<void> commit() async {
    if (!_isActive) return;
    _db.execute('COMMIT');
    _isActive = false;
  }

  @override
  Future<void> rollback() async {
    if (!_isActive) return;
    _db.execute('ROLLBACK');
    _isActive = false;
  }

  String _convertPlaceholders(String sql) {
    var result = sql;
    result = result.replaceAllMapped(RegExp(r'\$(\d+)'), (match) => '?');
    result = result.replaceAllMapped(RegExp(r'\?(\d+)'), (match) => '?');
    return result;
  }

  List<Object?> _convertParams(List<Object?>? params) {
    if (params == null) return [];
    return params.map((p) {
      if (p == null) return null;
      if (p is bool) return p ? 1 : 0;
      if (p is DateTime) return p.toIso8601String();
      if (p is Duration) return p.inMicroseconds;
      return p;
    }).toList();
  }
}

/// SQLite connection pool implementation.
///
/// Note: SQLite is typically single-connection, but we provide a pool
/// interface for API consistency. For WAL mode, multiple readers are
/// supported but only one writer at a time.
class SqliteConnectionPool implements ConnectionPool {
  final DatabaseConfig _config;
  SqliteConnection? _connection;
  bool _inUse = false;
  bool _closed = false;
  final _lock = _SimpleLock();

  SqliteConnectionPool._(this._config);

  /// Create a new connection pool (single connection for SQLite).
  static Future<SqliteConnectionPool> create(DatabaseConfig config) async {
    final pool = SqliteConnectionPool._(config);
    await pool._initialize();
    return pool;
  }

  Future<void> _initialize() async {
    _connection = await SqliteConnection.connect(_config);
  }

  @override
  int get size => _connection != null ? 1 : 0;

  @override
  int get available => (_connection != null && !_inUse) ? 1 : 0;

  @override
  int get inUse => _inUse ? 1 : 0;

  @override
  Future<DatabaseConnection> acquire() async {
    return _lock.synchronized(() async {
      if (_closed) {
        throw StateError('Pool is closed');
      }

      if (_inUse) {
        throw StateError('SQLite connection already in use');
      }

      if (_connection == null || !_connection!.isOpen) {
        _connection = await SqliteConnection.connect(_config);
      }

      _inUse = true;
      return _connection!;
    });
  }

  @override
  Future<void> release(DatabaseConnection connection) async {
    await _lock.synchronized(() async {
      if (connection != _connection) {
        throw ArgumentError('Connection does not belong to this pool');
      }
      _inUse = false;
    });
  }

  @override
  Future<T> withConnection<T>(Future<T> Function(DatabaseConnection conn) fn) async {
    final conn = await acquire();
    try {
      return await fn(conn);
    } finally {
      await release(conn);
    }
  }

  @override
  Future<T> withTransaction<T>(Future<T> Function(Transaction tx) fn) async {
    final conn = await acquire();
    try {
      final tx = await conn.beginTransaction();
      try {
        final result = await fn(tx);
        await tx.commit();
        return result;
      } catch (e) {
        await tx.rollback();
        rethrow;
      }
    } finally {
      await release(conn);
    }
  }

  @override
  Future<void> close() async {
    _closed = true;
    if (_connection != null) {
      await _connection!.close();
      _connection = null;
    }
  }
}

/// Simple lock for synchronizing pool access.
class _SimpleLock {
  Future<void>? _last;

  Future<T> synchronized<T>(Future<T> Function() fn) async {
    final previous = _last;
    final completer = Completer<void>();
    _last = completer.future;

    try {
      if (previous != null) {
        await previous;
      }
      return await fn();
    } finally {
      completer.complete();
    }
  }
}

/// SQLite database adapter.
class SqliteAdapter implements DatabaseAdapter {
  const SqliteAdapter();

  @override
  String get name => 'sqlite';

  @override
  SqlDialect get dialect => const SqliteDialect();

  @override
  Future<ConnectionPool> createPool(DatabaseConfig config) async {
    return SqliteConnectionPool.create(config);
  }

  @override
  Future<DatabaseConnection> connect(DatabaseConfig config) async {
    return SqliteConnection.connect(config);
  }

  @override
  Future<bool> databaseExists(DatabaseConfig config) async {
    if (config.database == ':memory:') {
      return false; // In-memory databases are always new
    }
    return File(config.database).existsSync();
  }

  @override
  Future<void> createDatabase(DatabaseConfig config) async {
    if (config.database == ':memory:') {
      return; // Nothing to create for in-memory
    }

    // Creating a SQLite database just means creating the file
    final file = File(config.database);
    if (!file.existsSync()) {
      // Open and close to create the file
      final db = sqlite.sqlite3.open(config.database);
      db.dispose();
    }
  }

  @override
  Future<void> dropDatabase(DatabaseConfig config) async {
    if (config.database == ':memory:') {
      return;
    }

    final file = File(config.database);
    if (file.existsSync()) {
      file.deleteSync();
    }

    // Also delete WAL and SHM files if they exist
    final walFile = File('${config.database}-wal');
    if (walFile.existsSync()) {
      walFile.deleteSync();
    }

    final shmFile = File('${config.database}-shm');
    if (shmFile.existsSync()) {
      shmFile.deleteSync();
    }
  }

  @override
  Future<List<String>> getTables(DatabaseConnection conn) async {
    final result = await conn.query('''
      SELECT name FROM sqlite_master 
      WHERE type='table' AND name NOT LIKE 'sqlite_%'
      ORDER BY name
    ''');
    return result.map((r) => r['name'] as String).toList();
  }

  @override
  Future<bool> tableExists(DatabaseConnection conn, String table) async {
    final result = await conn.query(
      '''
      SELECT COUNT(*) as count FROM sqlite_master 
      WHERE type='table' AND name=?
    ''',
      [table],
    );
    return (result.first['count'] as int? ?? 0) > 0;
  }

  @override
  Future<TableSchema> getTableSchema(DatabaseConnection conn, String table) async {
    // Get columns using PRAGMA
    final columnsResult = await conn.query('PRAGMA table_info("$table")');

    String? primaryKey;
    final columns = columnsResult.map((row) {
      final isPk = row['pk'] == 1;
      if (isPk) primaryKey = row['name'] as String;

      return ColumnSchema(
        name: row['name'] as String,
        type: row['type'] as String,
        nullable: row['notnull'] == 0,
        defaultValue: row['dflt_value'] as String?,
        isPrimaryKey: isPk,
      );
    }).toList();

    // Get indexes
    final indexListResult = await conn.query('PRAGMA index_list("$table")');

    final indexes = <IndexSchema>[];
    for (final indexRow in indexListResult) {
      final indexName = indexRow['name'] as String;
      final isUnique = indexRow['unique'] == 1;

      final indexInfoResult = await conn.query('PRAGMA index_info("$indexName")');
      final indexColumns = indexInfoResult.map((r) => r['name'] as String).toList();

      indexes.add(IndexSchema(name: indexName, columns: indexColumns, unique: isUnique));
    }

    // Get foreign keys
    final fkResult = await conn.query('PRAGMA foreign_key_list("$table")');

    final constraints = fkResult.map((row) {
      return ConstraintSchema(
        name: 'fk_${table}_${row['from']}',
        type: ConstraintType.foreignKey,
        columns: [row['from'] as String],
        referencedTable: row['table'] as String,
        referencedColumns: [row['to'] as String],
        onDelete: row['on_delete'] as String?,
        onUpdate: row['on_update'] as String?,
      );
    }).toList();

    return TableSchema(
      name: table,
      columns: columns,
      indexes: indexes,
      constraints: constraints,
      primaryKey: primaryKey,
    );
  }
}

/// SQLite-specific exception.
class SqliteException implements Exception {
  final String message;
  final String? sql;
  final int? errorCode;
  final String? database;

  SqliteException(this.message, {this.sql, this.errorCode, this.database});

  @override
  String toString() {
    final buffer = StringBuffer('SqliteException: $message');
    if (errorCode != null) buffer.write(' (code: $errorCode)');
    if (database != null) buffer.write('\nDatabase: $database');
    if (sql != null) buffer.write('\nSQL: $sql');
    return buffer.toString();
  }
}
