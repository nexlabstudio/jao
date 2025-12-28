/// PostgreSQL database adapter.
///
/// Provides PostgreSQL-specific SQL generation and database operations
/// using the `postgres` package.
library;

import 'dart:async';
import 'package:postgres/postgres.dart' as pg;
import '../connection.dart';

/// PostgreSQL SQL dialect.
class PostgresDialect implements SqlDialect {
  const PostgresDialect();

  @override
  String parameterPlaceholder(int index) => '\$$index';

  @override
  String quoteIdentifier(String name) => '"$name"';

  @override
  String sqlType(FieldType type) => switch (type) {
        FieldType.smallInt => 'SMALLINT',
        FieldType.integer => 'INTEGER',
        FieldType.bigInt => 'BIGINT',
        FieldType.serial => 'SERIAL',
        FieldType.bigSerial => 'BIGSERIAL',
        FieldType.real => 'REAL',
        FieldType.doublePrecision => 'DOUBLE PRECISION',
        FieldType.decimal => 'DECIMAL',
        FieldType.varchar => 'VARCHAR',
        FieldType.text => 'TEXT',
        FieldType.char => 'CHAR',
        FieldType.bytea => 'BYTEA',
        FieldType.blob => 'BYTEA',
        FieldType.date => 'DATE',
        FieldType.time => 'TIME',
        FieldType.timestamp => 'TIMESTAMP',
        FieldType.timestampTz => 'TIMESTAMPTZ',
        FieldType.interval => 'INTERVAL',
        FieldType.boolean => 'BOOLEAN',
        FieldType.uuid => 'UUID',
        FieldType.json => 'JSON',
        FieldType.jsonb => 'JSONB',
        FieldType.array => 'ARRAY',
      };

  @override
  String autoIncrement() => 'SERIAL';

  @override
  String booleanLiteral(bool value) => value ? 'TRUE' : 'FALSE';

  @override
  String currentTimestamp() => 'CURRENT_TIMESTAMP';

  @override
  String concat(List<String> parts) => parts.join(' || ');

  @override
  String limitOffset(int? limit, int? offset) {
    final buffer = StringBuffer();
    if (limit != null) buffer.write(' LIMIT $limit');
    if (offset != null) buffer.write(' OFFSET $offset');
    return buffer.toString();
  }

  @override
  bool get supportsReturning => true;

  @override
  String upsert(String table, List<String> columns, List<String> conflictColumns) {
    final conflictCols = conflictColumns.map(quoteIdentifier).join(', ');
    final updateCols = columns
        .where((c) => !conflictColumns.contains(c))
        .map((c) => '${quoteIdentifier(c)} = EXCLUDED.${quoteIdentifier(c)}')
        .join(', ');
    return 'ON CONFLICT ($conflictCols) DO UPDATE SET $updateCols';
  }

  @override
  String caseInsensitiveLike(String column, String param) {
    // PostgreSQL has native ILIKE
    return '$column ILIKE $param';
  }
}

/// PostgreSQL database connection implementation.
class PostgresConnection implements DatabaseConnection {
  final pg.Connection _conn;
  bool _isOpen = true;

  PostgresConnection._(this._conn);

  /// Create a new connection from config.
  static Future<PostgresConnection> connect(DatabaseConfig config) async {
    final endpoint = pg.Endpoint(
      host: config.host,
      port: config.port,
      database: config.database,
      username: config.username,
      password: config.password,
    );

    final settings = pg.ConnectionSettings(
      sslMode: config.useSsl ? pg.SslMode.require : pg.SslMode.disable,
      connectTimeout: Duration(seconds: config.connectTimeout),
      queryTimeout: Duration(seconds: config.queryTimeout),
    );

    final conn = await pg.Connection.open(endpoint, settings: settings);
    return PostgresConnection._(conn);
  }

  @override
  bool get isOpen => _isOpen;

  @override
  Future<QueryResult> execute(String sql, [List<Object?>? params]) async {
    try {
      // Convert positional params ($1, $2) to the format postgres package expects
      final pgSql = _convertSqlToNamed(sql, params?.length ?? 0);
      final pgParams = _convertParams(params);

      final result = await _conn.execute(pg.Sql.named(pgSql), parameters: pgParams);

      final rows = result.map((row) => row.toColumnMap()).toList();
      final columns = result.schema.columns.map((c) => c.columnName ?? '').toList();

      return QueryResult(rows: rows, columns: columns, affectedRows: result.affectedRows);
    } catch (e) {
      throw DatabaseException('Query execution failed: $e', sql: sql);
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
  Future<PostgresTransaction> beginTransaction() async {
    // Start a transaction using the connection
    return PostgresTransaction._(_conn);
  }

  @override
  Future<void> close() async {
    await _conn.close();
    _isOpen = false;
  }

  /// Convert $1, $2 style SQL to @1, @2 for postgres package named params.
  String _convertSqlToNamed(String sql, int paramCount) {
    var result = sql;
    for (var i = paramCount; i >= 1; i--) {
      result = result.replaceAll('\$$i', '@p$i');
    }
    return result;
  }

  /// Convert Dart parameters to postgres named parameters.
  Map<String, Object?>? _convertParams(List<Object?>? params) {
    if (params == null || params.isEmpty) return null;
    final map = <String, Object?>{};
    for (var i = 0; i < params.length; i++) {
      map['p${i + 1}'] = _convertValue(params[i]);
    }
    return map;
  }

  /// Convert Dart values to postgres-compatible values.
  Object? _convertValue(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Duration) return value;
    if (value is List) return value;
    return value;
  }
}

/// PostgreSQL transaction implementation.
class PostgresTransaction implements Transaction {
  final pg.Connection _conn;
  bool _isActive = true;
  bool _started = false;

  PostgresTransaction._(this._conn);

  Future<void> _ensureStarted() async {
    if (!_started) {
      await _conn.execute('BEGIN');
      _started = true;
    }
  }

  @override
  bool get isActive => _isActive;

  @override
  Future<QueryResult> execute(String sql, [List<Object?>? params]) async {
    await _ensureStarted();

    try {
      final pgSql = _convertSqlToNamed(sql, params?.length ?? 0);
      final pgParams = _convertParams(params);

      final result = await _conn.execute(pg.Sql.named(pgSql), parameters: pgParams);

      final rows = result.map((row) => row.toColumnMap()).toList();
      final columns = result.schema.columns.map((c) => c.columnName ?? '').toList();

      return QueryResult(rows: rows, columns: columns, affectedRows: result.affectedRows);
    } catch (e) {
      throw DatabaseException('Transaction query failed: $e', sql: sql);
    }
  }

  @override
  Future<void> commit() async {
    if (!_isActive) return;
    if (_started) {
      await _conn.execute('COMMIT');
    }
    _isActive = false;
  }

  @override
  Future<void> rollback() async {
    if (!_isActive) return;
    if (_started) {
      await _conn.execute('ROLLBACK');
    }
    _isActive = false;
  }

  String _convertSqlToNamed(String sql, int paramCount) {
    var result = sql;
    for (var i = paramCount; i >= 1; i--) {
      result = result.replaceAll('\$$i', '@p$i');
    }
    return result;
  }

  Map<String, Object?>? _convertParams(List<Object?>? params) {
    if (params == null || params.isEmpty) return null;
    final map = <String, Object?>{};
    for (var i = 0; i < params.length; i++) {
      map['p${i + 1}'] = params[i];
    }
    return map;
  }
}

/// PostgreSQL connection pool implementation.
class PostgresConnectionPool implements ConnectionPool {
  final DatabaseConfig _config;
  final List<PostgresConnection> _available = [];
  final List<PostgresConnection> _inUse = [];
  final int _minConnections;
  final int _maxConnections;
  bool _closed = false;
  final _lock = _SimpleLock();

  PostgresConnectionPool._(this._config, this._minConnections, this._maxConnections);

  /// Create a new connection pool.
  static Future<PostgresConnectionPool> create(DatabaseConfig config) async {
    final pool = PostgresConnectionPool._(config, config.minConnections, config.maxConnections);
    await pool._initialize();
    return pool;
  }

  Future<void> _initialize() async {
    // Create minimum connections
    for (var i = 0; i < _minConnections; i++) {
      try {
        final conn = await PostgresConnection.connect(_config);
        _available.add(conn);
      } catch (e) {
        // Log but don't fail - pool can grow later
        print('Warning: Failed to create initial connection: $e');
      }
    }
  }

  @override
  int get size => _available.length + _inUse.length;

  @override
  int get available => _available.length;

  @override
  int get inUse => _inUse.length;

  @override
  Future<DatabaseConnection> acquire() async {
    return _lock.synchronized(() async {
      if (_closed) {
        throw StateError('Pool is closed');
      }

      // Try to get an available connection
      while (_available.isNotEmpty) {
        final conn = _available.removeLast();
        if (conn.isOpen) {
          _inUse.add(conn);
          return conn;
        }
        // Connection was closed, discard it
      }

      // Create a new connection if under max
      if (size < _maxConnections) {
        final conn = await PostgresConnection.connect(_config);
        _inUse.add(conn);
        return conn;
      }

      // Pool exhausted, wait and retry
      throw StateError('Connection pool exhausted (max: $_maxConnections, in use: ${_inUse.length})');
    });
  }

  @override
  Future<void> release(DatabaseConnection connection) async {
    await _lock.synchronized(() async {
      if (connection is! PostgresConnection) {
        throw ArgumentError('Connection is not a PostgresConnection');
      }

      _inUse.remove(connection);

      if (_closed || !connection.isOpen) {
        try {
          await connection.close();
        } catch (_) {}
      } else {
        _available.add(connection);
      }
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

    // Close all connections
    final allConns = [..._available, ..._inUse];
    _available.clear();
    _inUse.clear();

    for (final conn in allConns) {
      try {
        await conn.close();
      } catch (_) {}
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

/// PostgreSQL database adapter.
class PostgresAdapter implements DatabaseAdapter {
  const PostgresAdapter();

  @override
  String get name => 'postgresql';

  @override
  SqlDialect get dialect => const PostgresDialect();

  @override
  Future<ConnectionPool> createPool(DatabaseConfig config) async {
    return PostgresConnectionPool.create(config);
  }

  @override
  Future<DatabaseConnection> connect(DatabaseConfig config) async {
    return PostgresConnection.connect(config);
  }

  @override
  Future<bool> databaseExists(DatabaseConfig config) async {
    // Connect to 'postgres' database to check
    final adminConfig = DatabaseConfig(
      host: config.host,
      port: config.port,
      database: 'postgres',
      username: config.username,
      password: config.password,
      useSsl: config.useSsl,
    );

    final conn = await PostgresConnection.connect(adminConfig);
    try {
      final result = await conn.query('SELECT 1 FROM pg_database WHERE datname = \$1', [config.database]);
      return result.isNotEmpty;
    } finally {
      await conn.close();
    }
  }

  @override
  Future<void> createDatabase(DatabaseConfig config) async {
    final adminConfig = DatabaseConfig(
      host: config.host,
      port: config.port,
      database: 'postgres',
      username: config.username,
      password: config.password,
      useSsl: config.useSsl,
    );

    final conn = await PostgresConnection.connect(adminConfig);
    try {
      await conn.execute('CREATE DATABASE ${dialect.quoteIdentifier(config.database)}');
    } finally {
      await conn.close();
    }
  }

  @override
  Future<void> dropDatabase(DatabaseConfig config) async {
    final adminConfig = DatabaseConfig(
      host: config.host,
      port: config.port,
      database: 'postgres',
      username: config.username,
      password: config.password,
      useSsl: config.useSsl,
    );

    final conn = await PostgresConnection.connect(adminConfig);
    try {
      // Terminate existing connections
      await conn.execute(
        '''
        SELECT pg_terminate_backend(pg_stat_activity.pid)
        FROM pg_stat_activity
        WHERE pg_stat_activity.datname = \$1
          AND pid <> pg_backend_pid()
      ''',
        [config.database],
      );

      await conn.execute('DROP DATABASE IF EXISTS ${dialect.quoteIdentifier(config.database)}');
    } finally {
      await conn.close();
    }
  }

  @override
  Future<List<String>> getTables(DatabaseConnection conn) async {
    final result = await conn.query('''
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
        AND table_type = 'BASE TABLE'
      ORDER BY table_name
    ''');
    return result.map((r) => r['table_name'] as String).toList();
  }

  @override
  Future<bool> tableExists(DatabaseConnection conn, String table) async {
    final result = await conn.query(
      '''
      SELECT EXISTS (
        SELECT 1 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
          AND table_name = \$1
      ) as exists
    ''',
      [table],
    );
    return result.first['exists'] as bool? ?? false;
  }

  @override
  Future<TableSchema> getTableSchema(DatabaseConnection conn, String table) async {
    // Get columns
    final columnsResult = await conn.query(
      '''
      SELECT 
        column_name,
        data_type,
        is_nullable,
        column_default,
        character_maximum_length,
        numeric_precision,
        numeric_scale
      FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = \$1
      ORDER BY ordinal_position
    ''',
      [table],
    );

    final columns = columnsResult.map((row) {
      return ColumnSchema(
        name: row['column_name'] as String,
        type: row['data_type'] as String,
        nullable: row['is_nullable'] == 'YES',
        defaultValue: row['column_default'] as String?,
        maxLength: row['character_maximum_length'] as int?,
        precision: row['numeric_precision'] as int?,
        scale: row['numeric_scale'] as int?,
      );
    }).toList();

    // Get primary key
    final pkResult = await conn.query(
      '''
      SELECT a.attname
      FROM pg_index i
      JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey)
      WHERE i.indrelid = \$1::regclass AND i.indisprimary
    ''',
      [table],
    );
    final primaryKey = pkResult.isNotEmpty ? pkResult.first['attname'] as String : null;

    // Get indexes
    final indexResult = await conn.query(
      '''
      SELECT
        i.relname AS index_name,
        a.attname AS column_name,
        ix.indisunique AS is_unique
      FROM pg_class t
      JOIN pg_index ix ON t.oid = ix.indrelid
      JOIN pg_class i ON i.oid = ix.indexrelid
      JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = ANY(ix.indkey)
      WHERE t.relname = \$1 AND t.relkind = 'r'
    ''',
      [table],
    );

    // Group index columns
    final indexMap = <String, IndexSchema>{};
    for (final row in indexResult) {
      final indexName = row['index_name'] as String;
      final columnName = row['column_name'] as String;
      final isUnique = row['is_unique'] as bool;

      if (indexMap[indexName] case final existing?) {
        indexMap[indexName] = IndexSchema(
          name: indexName,
          columns: [...existing.columns, columnName],
          unique: isUnique,
        );
      } else {
        indexMap[indexName] = IndexSchema(name: indexName, columns: [columnName], unique: isUnique);
      }
    }

    // Get foreign key constraints
    final fkResult = await conn.query(
      '''
      SELECT
        tc.constraint_name,
        kcu.column_name,
        ccu.table_name AS foreign_table_name,
        ccu.column_name AS foreign_column_name,
        rc.delete_rule,
        rc.update_rule
      FROM information_schema.table_constraints AS tc
      JOIN information_schema.key_column_usage AS kcu
        ON tc.constraint_name = kcu.constraint_name
      JOIN information_schema.constraint_column_usage AS ccu
        ON ccu.constraint_name = tc.constraint_name
      JOIN information_schema.referential_constraints AS rc
        ON tc.constraint_name = rc.constraint_name
      WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_name = \$1
    ''',
      [table],
    );

    final constraints = fkResult.map((row) {
      return ConstraintSchema(
        name: row['constraint_name'] as String,
        type: ConstraintType.foreignKey,
        columns: [row['column_name'] as String],
        referencedTable: row['foreign_table_name'] as String,
        referencedColumns: [row['foreign_column_name'] as String],
        onDelete: row['delete_rule'] as String?,
        onUpdate: row['update_rule'] as String?,
      );
    }).toList();

    return TableSchema(
      name: table,
      columns: columns,
      indexes: indexMap.values.toList(),
      constraints: constraints,
      primaryKey: primaryKey,
    );
  }
}

/// Database exception for PostgreSQL-specific errors.
class DatabaseException implements Exception {
  final String message;
  final String? sql;
  final String? code;

  DatabaseException(this.message, {this.sql, this.code});

  @override
  String toString() {
    var result = 'DatabaseException: $message';
    if (code != null) result += ' (code: $code)';
    if (sql != null) result += '\nSQL: $sql';
    return result;
  }
}
