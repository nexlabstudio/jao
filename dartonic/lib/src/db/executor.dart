/// Model Executor - Executes queries for a specific model.
///
/// This bridges the QuerySet/Manager API with the database adapter,
/// handling SQL compilation and result mapping.
library;

import 'dart:async';
import '../query/queryset.dart';
import '../query/expressions.dart';
import '../model/manager.dart';
import 'connection.dart';
import 'compiler.dart';

/// Executes queries for a specific model type.
///
/// Handles SQL compilation, query execution, and result mapping.
class ModelExecutor<T> implements QueryExecutor<T>, CreateCapable<T>, RawQueryCapable {
  /// The database connection pool
  final ConnectionPool pool;

  /// The SQL compiler for query generation
  final SqlCompiler compiler;

  /// The table name for this model
  final String tableName;

  /// The primary key field name
  final String pkField;

  /// Function to create model instance from row data
  final T Function(Map<String, dynamic> row) fromRow;

  /// Function to convert model instance to row data
  final Map<String, dynamic> Function(T model) toRow;

  ModelExecutor({
    required this.pool,
    required this.compiler,
    required this.tableName,
    required this.pkField,
    required this.fromRow,
    required this.toRow,
  });

  @override
  Future<List<T>> execute(QueryConfig config) async {
    final query = compiler.compileSelect(table: tableName, config: config);

    return pool.withConnection((conn) async {
      final rows = await conn.query(query.sql, query.parameters);
      return rows.map(fromRow).toList();
    });
  }

  @override
  Future<int> count(QueryConfig config) async {
    final query = compiler.compileCount(table: tableName, config: config);

    return pool.withConnection((conn) async {
      final result = await conn.scalar<int>(query.sql, query.parameters);
      return result ?? 0;
    });
  }

  @override
  Future<Map<String, dynamic>> aggregate(QueryConfig config, Map<String, Expression> aggregates) async {
    final query = compiler.compileAggregate(table: tableName, config: config, aggregates: aggregates);

    return pool.withConnection((conn) async {
      final rows = await conn.query(query.sql, query.parameters);
      return rows.firstOrNull ?? {};
    });
  }

  @override
  Stream<T> stream(QueryConfig config) async* {
    final query = compiler.compileSelect(table: tableName, config: config);

    final conn = await pool.acquire();
    try {
      final rows = await conn.query(query.sql, query.parameters);
      for (final row in rows) {
        yield fromRow(row);
      }
    } finally {
      await pool.release(conn);
    }
  }

  @override
  Future<int> update(QueryConfig config, Map<String, Object?> values) async {
    final query = compiler.compileUpdate(table: tableName, config: config, values: values);

    return pool.withConnection((conn) async {
      final result = await conn.execute(query.sql, query.parameters);
      return result.affectedRows;
    });
  }

  @override
  Future<int> delete(QueryConfig config) async {
    final query = compiler.compileDelete(table: tableName, config: config);

    return pool.withConnection((conn) async {
      final result = await conn.execute(query.sql, query.parameters);
      return result.affectedRows;
    });
  }

  @override
  Future<T> create(Map<String, Object?> values) async {
    final query = compiler.compileInsert(
      table: tableName,
      values: values,
      returning: compiler.dialect.supportsReturning,
      returningColumn: '*',
    );

    return pool.withConnection((conn) async {
      final result = await conn.execute(query.sql, query.parameters);

      if (compiler.dialect.supportsReturning && result.rows.isNotEmpty) {
        return fromRow(result.rows.first);
      }

      // For databases without RETURNING, fetch the inserted row
      final insertId = result.lastInsertId;
      if (insertId != null) {
        final fetchQuery = compiler.compileSelect(
          table: tableName,
          config: QueryConfig(filters: [Q(Comparison(ColumnRef(pkField), ComparisonOp.eq, Value(insertId)))], limit: 1),
        );
        final rows = await conn.query(fetchQuery.sql, fetchQuery.parameters);
        if (rows.isNotEmpty) {
          return fromRow(rows.first);
        }
      }

      // Return a model with the provided values as fallback
      return fromRow(values.cast<String, dynamic>());
    });
  }

  @override
  Future<List<T>> bulkCreate(List<Map<String, Object?>> objects) async {
    if (objects.isEmpty) return [];

    final query = compiler.compileBulkInsert(
      table: tableName,
      rows: objects,
      returning: compiler.dialect.supportsReturning,
      returningColumn: '*',
    );

    return pool.withConnection((conn) async {
      final result = await conn.execute(query.sql, query.parameters);

      if (compiler.dialect.supportsReturning && result.rows.isNotEmpty) {
        return result.rows.map(fromRow).toList();
      }

      // For databases without RETURNING, we can't efficiently get all inserted rows
      // Return models from the input data
      return objects.map((obj) => fromRow(obj.cast<String, dynamic>())).toList();
    });
  }

  @override
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<Object?>? params]) async {
    return pool.withConnection((conn) async {
      return conn.query(sql, params);
    });
  }

  /// Execute within a transaction
  Future<R> transaction<R>(Future<R> Function(TransactionExecutor<T> tx) fn) async {
    return pool.withTransaction((tx) async {
      final txExecutor = TransactionExecutor<T>(
        transaction: tx,
        compiler: compiler,
        tableName: tableName,
        pkField: pkField,
        fromRow: fromRow,
        toRow: toRow,
      );
      return fn(txExecutor);
    });
  }
}

/// Executor for operations within a transaction.
class TransactionExecutor<T> implements CreateCapable<T> {
  final Transaction transaction;
  final SqlCompiler compiler;
  final String tableName;
  final String pkField;
  final T Function(Map<String, dynamic> row) fromRow;
  final Map<String, dynamic> Function(T model) toRow;

  TransactionExecutor({
    required this.transaction,
    required this.compiler,
    required this.tableName,
    required this.pkField,
    required this.fromRow,
    required this.toRow,
  });

  Future<List<T>> query(QueryConfig config) async {
    final query = compiler.compileSelect(table: tableName, config: config);
    final result = await transaction.execute(query.sql, query.parameters);
    return result.rows.map(fromRow).toList();
  }

  Future<int> update(QueryConfig config, Map<String, Object?> values) async {
    final query = compiler.compileUpdate(table: tableName, config: config, values: values);
    final result = await transaction.execute(query.sql, query.parameters);
    return result.affectedRows;
  }

  Future<int> delete(QueryConfig config) async {
    final query = compiler.compileDelete(table: tableName, config: config);
    final result = await transaction.execute(query.sql, query.parameters);
    return result.affectedRows;
  }

  @override
  Future<T> create(Map<String, Object?> values) async {
    final query = compiler.compileInsert(
      table: tableName,
      values: values,
      returning: compiler.dialect.supportsReturning,
      returningColumn: '*',
    );

    final result = await transaction.execute(query.sql, query.parameters);

    if (compiler.dialect.supportsReturning && result.rows.isNotEmpty) {
      return fromRow(result.rows.first);
    }

    return fromRow(values.cast<String, dynamic>());
  }

  @override
  Future<List<T>> bulkCreate(List<Map<String, Object?>> objects) async {
    if (objects.isEmpty) return [];

    final query = compiler.compileBulkInsert(
      table: tableName,
      rows: objects,
      returning: compiler.dialect.supportsReturning,
      returningColumn: '*',
    );

    final result = await transaction.execute(query.sql, query.parameters);

    if (compiler.dialect.supportsReturning && result.rows.isNotEmpty) {
      return result.rows.map(fromRow).toList();
    }

    return objects.map((obj) => fromRow(obj.cast<String, dynamic>())).toList();
  }
}
