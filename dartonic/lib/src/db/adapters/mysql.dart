/// MySQL database adapter.
///
/// Provides MySQL-specific SQL generation and database operations
/// using the `mysql1` package.
library;

import 'dart:async';
import 'package:mysql1/mysql1.dart' as mysql;
import '../connection.dart';

/// MySQL SQL dialect.
class MySqlDialect implements SqlDialect {
  const MySqlDialect();

  @override
  String parameterPlaceholder(int index) => '?';

  @override
  String quoteIdentifier(String name) => '`$name`';

  @override
  String sqlType(FieldType type) => switch (type) {
    FieldType.smallInt => 'SMALLINT',
    FieldType.integer => 'INT',
    FieldType.bigInt => 'BIGINT',
    FieldType.serial => 'INT AUTO_INCREMENT',
    FieldType.bigSerial => 'BIGINT AUTO_INCREMENT',
    FieldType.real => 'FLOAT',
    FieldType.doublePrecision => 'DOUBLE',
    FieldType.decimal => 'DECIMAL',
    FieldType.varchar => 'VARCHAR',
    FieldType.text => 'TEXT',
    FieldType.char => 'CHAR',
    FieldType.bytea => 'BLOB',
    FieldType.blob => 'BLOB',
    FieldType.date => 'DATE',
    FieldType.time => 'TIME',
    FieldType.timestamp => 'DATETIME',
    FieldType.timestampTz => 'DATETIME',
    FieldType.interval => 'TIME',
    FieldType.boolean => 'TINYINT(1)',
    FieldType.uuid => 'CHAR(36)',
    FieldType.json => 'JSON',
    FieldType.jsonb => 'JSON',
    FieldType.array => 'JSON',
  };

  @override
  String autoIncrement() => 'AUTO_INCREMENT';

  @override
  String booleanLiteral(bool value) => value ? '1' : '0';

  @override
  String currentTimestamp() => 'NOW()';

  @override
  String concat(List<String> parts) => 'CONCAT(${parts.join(', ')})';

  @override
  String limitOffset(int? limit, int? offset) {
    if (limit == null && offset == null) return '';
    if (limit != null && offset == null) return ' LIMIT $limit';
    if (limit == null && offset != null) {
      // MySQL requires LIMIT with OFFSET
      return ' LIMIT 18446744073709551615 OFFSET $offset';
    }
    return ' LIMIT $limit OFFSET $offset';
  }

  @override
  bool get supportsReturning => false;

  @override
  String upsert(String table, List<String> columns, List<String> conflictColumns) {
    final updateCols = columns
        .where((c) => !conflictColumns.contains(c))
        .map((c) => '${quoteIdentifier(c)} = VALUES(${quoteIdentifier(c)})')
        .join(', ');
    return 'ON DUPLICATE KEY UPDATE $updateCols';
  }
}

/// MySQL database connection implementation.
class MySqlConnection implements DatabaseConnection {
  final mysql.MySqlConnection _conn;
  bool _isOpen = true;

  MySqlConnection._(this._conn);

  /// Create a new connection from config.
  static Future<MySqlConnection> connect(DatabaseConfig config) async {
    final settings = mysql.ConnectionSettings(
      host: config.host,
      port: config.port,
      db: config.database,
      user: config.username,
      password: config.password,
      useSSL: config.useSsl,
      timeout: Duration(seconds: config.connectTimeout),
    );

    final conn = await mysql.MySqlConnection.connect(settings);
    return MySqlConnection._(conn);
  }

  @override
  bool get isOpen => _isOpen;

  @override
  Future<QueryResult> execute(String sql, [List<Object?>? params]) async {
    try {
      final result = await _conn.query(sql, params ?? []);

      final rows = <Map<String, dynamic>>[];
      final columns = <String>[];

      if (result.fields.isNotEmpty) {
        columns.addAll(result.fields.map((f) => f.name ?? ''));
      }

      for (final row in result) {
        final map = <String, dynamic>{};
        for (var i = 0; i < row.fields.length; i++) {
          final colName = columns.isNotEmpty && i < columns.length ? columns[i] : 'col_$i';
          map[colName] = row[i];
        }
        rows.add(map);
      }

      return QueryResult(
        rows: rows,
        columns: columns,
        affectedRows: result.affectedRows ?? 0,
        lastInsertId: result.insertId,
      );
    } catch (e) {
      throw MySqlException('Query execution failed: $e', sql: sql);
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
  Future<MySqlTransaction> beginTransaction() async {
    await _conn.query('START TRANSACTION');
    return MySqlTransaction._(_conn);
  }

  @override
  Future<void> close() async {
    await _conn.close();
    _isOpen = false;
  }
}

/// MySQL transaction implementation.
class MySqlTransaction implements Transaction {
  final mysql.MySqlConnection _conn;
  bool _isActive = true;

  MySqlTransaction._(this._conn);

  @override
  bool get isActive => _isActive;

  @override
  Future<QueryResult> execute(String sql, [List<Object?>? params]) async {
    if (!_isActive) {
      throw StateError('Transaction is no longer active');
    }

    try {
      final result = await _conn.query(sql, params ?? []);

      final rows = <Map<String, dynamic>>[];
      final columns = <String>[];

      if (result.fields.isNotEmpty) {
        columns.addAll(result.fields.map((f) => f.name ?? ''));
      }

      for (final row in result) {
        final map = <String, dynamic>{};
        for (var i = 0; i < row.fields.length; i++) {
          final colName = columns.isNotEmpty && i < columns.length ? columns[i] : 'col_$i';
          map[colName] = row[i];
        }
        rows.add(map);
      }

      return QueryResult(
        rows: rows,
        columns: columns,
        affectedRows: result.affectedRows ?? 0,
        lastInsertId: result.insertId,
      );
    } catch (e) {
      throw MySqlException('Transaction query failed: $e', sql: sql);
    }
  }

  @override
  Future<void> commit() async {
    if (!_isActive) return;
    await _conn.query('COMMIT');
    _isActive = false;
  }

  @override
  Future<void> rollback() async {
    if (!_isActive) return;
    await _conn.query('ROLLBACK');
    _isActive = false;
  }
}

/// MySQL connection pool implementation.
class MySqlConnectionPool implements ConnectionPool {
  final DatabaseConfig _config;
  final List<MySqlConnection> _available = [];
  final List<MySqlConnection> _inUse = [];
  final int _minConnections;
  final int _maxConnections;
  bool _closed = false;
  final _lock = _SimpleLock();

  MySqlConnectionPool._(this._config, this._minConnections, this._maxConnections);

  /// Create a new connection pool.
  static Future<MySqlConnectionPool> create(DatabaseConfig config) async {
    final pool = MySqlConnectionPool._(config, config.minConnections, config.maxConnections);
    await pool._initialize();
    return pool;
  }

  Future<void> _initialize() async {
    for (var i = 0; i < _minConnections; i++) {
      try {
        final conn = await MySqlConnection.connect(_config);
        _available.add(conn);
      } catch (e) {
        print('Warning: Failed to create initial MySQL connection: $e');
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

      while (_available.isNotEmpty) {
        final conn = _available.removeLast();
        if (conn.isOpen) {
          _inUse.add(conn);
          return conn;
        }
      }

      if (size < _maxConnections) {
        final conn = await MySqlConnection.connect(_config);
        _inUse.add(conn);
        return conn;
      }

      throw StateError('Connection pool exhausted (max: $_maxConnections, in use: ${_inUse.length})');
    });
  }

  @override
  Future<void> release(DatabaseConnection connection) async {
    await _lock.synchronized(() async {
      if (connection is! MySqlConnection) {
        throw ArgumentError('Connection is not a MySqlConnection');
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

/// MySQL database adapter.
class MySqlAdapter implements DatabaseAdapter {
  const MySqlAdapter();

  @override
  String get name => 'mysql';

  @override
  SqlDialect get dialect => const MySqlDialect();

  @override
  Future<ConnectionPool> createPool(DatabaseConfig config) async {
    return MySqlConnectionPool.create(config);
  }

  @override
  Future<DatabaseConnection> connect(DatabaseConfig config) async {
    return MySqlConnection.connect(config);
  }

  @override
  Future<bool> databaseExists(DatabaseConfig config) async {
    final adminConfig = DatabaseConfig(
      host: config.host,
      port: config.port,
      database: 'information_schema',
      username: config.username,
      password: config.password,
      useSsl: config.useSsl,
    );

    final conn = await MySqlConnection.connect(adminConfig);
    try {
      final result = await conn.query('SELECT 1 FROM SCHEMATA WHERE SCHEMA_NAME = ?', [config.database]);
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
      database: 'mysql',
      username: config.username,
      password: config.password,
      useSsl: config.useSsl,
    );

    final conn = await MySqlConnection.connect(adminConfig);
    try {
      await conn.execute(
        'CREATE DATABASE ${dialect.quoteIdentifier(config.database)} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci',
      );
    } finally {
      await conn.close();
    }
  }

  @override
  Future<void> dropDatabase(DatabaseConfig config) async {
    final adminConfig = DatabaseConfig(
      host: config.host,
      port: config.port,
      database: 'mysql',
      username: config.username,
      password: config.password,
      useSsl: config.useSsl,
    );

    final conn = await MySqlConnection.connect(adminConfig);
    try {
      await conn.execute('DROP DATABASE IF EXISTS ${dialect.quoteIdentifier(config.database)}');
    } finally {
      await conn.close();
    }
  }

  @override
  Future<List<String>> getTables(DatabaseConnection conn) async {
    final result = await conn.query('SHOW TABLES');
    return result.map((r) => r.values.first as String).toList();
  }

  @override
  Future<bool> tableExists(DatabaseConnection conn, String table) async {
    final result = await conn.query(
      '''
      SELECT COUNT(*) as count
      FROM information_schema.tables 
      WHERE table_schema = DATABASE()
        AND table_name = ?
    ''',
      [table],
    );
    return (result.first['count'] as int? ?? 0) > 0;
  }

  @override
  Future<TableSchema> getTableSchema(DatabaseConnection conn, String table) async {
    // Get columns
    final columnsResult = await conn.query(
      '''
      SELECT 
        COLUMN_NAME,
        DATA_TYPE,
        IS_NULLABLE,
        COLUMN_DEFAULT,
        CHARACTER_MAXIMUM_LENGTH,
        NUMERIC_PRECISION,
        NUMERIC_SCALE,
        COLUMN_KEY,
        EXTRA
      FROM information_schema.columns
      WHERE table_schema = DATABASE() AND table_name = ?
      ORDER BY ORDINAL_POSITION
    ''',
      [table],
    );

    String? primaryKey;
    final columns = columnsResult.map((row) {
      final isPk = row['COLUMN_KEY'] == 'PRI';
      if (isPk) primaryKey = row['COLUMN_NAME'] as String;

      return ColumnSchema(
        name: row['COLUMN_NAME'] as String,
        type: row['DATA_TYPE'] as String,
        nullable: row['IS_NULLABLE'] == 'YES',
        defaultValue: row['COLUMN_DEFAULT'] as String?,
        isPrimaryKey: isPk,
        isAutoIncrement: (row['EXTRA'] as String?)?.contains('auto_increment') ?? false,
        maxLength: row['CHARACTER_MAXIMUM_LENGTH'] as int?,
        precision: row['NUMERIC_PRECISION'] as int?,
        scale: row['NUMERIC_SCALE'] as int?,
      );
    }).toList();

    // Get indexes
    final indexResult = await conn.query(
      '''
      SELECT 
        INDEX_NAME,
        COLUMN_NAME,
        NON_UNIQUE
      FROM information_schema.statistics
      WHERE table_schema = DATABASE() AND table_name = ?
      ORDER BY INDEX_NAME, SEQ_IN_INDEX
    ''',
      [table],
    );

    final indexMap = <String, IndexSchema>{};
    for (final row in indexResult) {
      final indexName = row['INDEX_NAME'] as String;
      final columnName = row['COLUMN_NAME'] as String;
      final isUnique = row['NON_UNIQUE'] == 0;

      if (indexMap.containsKey(indexName)) {
        indexMap[indexName] = IndexSchema(
          name: indexName,
          columns: [...indexMap[indexName]!.columns, columnName],
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
        CONSTRAINT_NAME,
        COLUMN_NAME,
        REFERENCED_TABLE_NAME,
        REFERENCED_COLUMN_NAME
      FROM information_schema.key_column_usage
      WHERE table_schema = DATABASE() 
        AND table_name = ?
        AND REFERENCED_TABLE_NAME IS NOT NULL
    ''',
      [table],
    );

    final constraints = fkResult.map((row) {
      return ConstraintSchema(
        name: row['CONSTRAINT_NAME'] as String,
        type: ConstraintType.foreignKey,
        columns: [row['COLUMN_NAME'] as String],
        referencedTable: row['REFERENCED_TABLE_NAME'] as String,
        referencedColumns: [row['REFERENCED_COLUMN_NAME'] as String],
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

/// MySQL-specific exception.
class MySqlException implements Exception {
  final String message;
  final String? sql;
  final int? errorCode;

  MySqlException(this.message, {this.sql, this.errorCode});

  @override
  String toString() {
    var result = 'MySqlException: $message';
    if (errorCode != null) result += ' (code: $errorCode)';
    if (sql != null) result += '\nSQL: $sql';
    return result;
  }
}
