library;

import 'dart:async';
import '../query/queryset.dart';
import '../query/expressions.dart';
import '../model/manager.dart';
import '../utils/uuid.dart';
import 'connection.dart';
import 'compiler.dart';

class ModelExecutor<T> implements QueryExecutor<T>, CreateCapable<T>, RawQueryCapable {
  final ConnectionPool pool;
  final SqlCompiler compiler;
  final String tableName;
  final String pkField;
  final T Function(Map<String, dynamic> row) fromRow;
  final Map<String, dynamic> Function(T model) toRow;
  final List<String> autoNowAddFields;
  final List<String> autoNowFields;
  final List<String> autoGenerateUuidFields;

  ModelExecutor({
    required this.pool,
    required this.compiler,
    required this.tableName,
    required this.pkField,
    required this.fromRow,
    required this.toRow,
    this.autoNowAddFields = const [],
    this.autoNowFields = const [],
    this.autoGenerateUuidFields = const [],
  });

  String _currentTimestamp() => DateTime.now().toUtc().toIso8601String();

  Map<String, Object?> _injectCreateValues(Map<String, Object?> values) {
    final result = Map<String, Object?>.from(values);
    final now = _currentTimestamp();

    for (final field in autoGenerateUuidFields) {
      if (!result.containsKey(field) || result[field] == null) {
        result[field] = generateUuidV4();
      }
    }

    for (final field in autoNowAddFields) {
      if (!result.containsKey(field)) {
        result[field] = now;
      }
    }
    for (final field in autoNowFields) {
      if (!result.containsKey(field)) {
        result[field] = now;
      }
    }
    return result;
  }

  Map<String, Object?> _injectUpdateTimestamps(Map<String, Object?> values) {
    final result = Map<String, Object?>.from(values);
    final now = _currentTimestamp();
    for (final field in autoNowFields) {
      result[field] = now;
    }
    return result;
  }

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
    final valuesWithTimestamps = _injectUpdateTimestamps(values);

    final query = compiler.compileUpdate(table: tableName, config: config, values: valuesWithTimestamps);

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
    final valuesWithTimestamps = _injectCreateValues(values);

    final query = compiler.compileInsert(
      table: tableName,
      values: valuesWithTimestamps,
      returning: compiler.dialect.supportsReturning,
      returningColumn: '*',
    );

    return pool.withConnection((conn) async {
      final result = await conn.execute(query.sql, query.parameters);

      if (compiler.dialect.supportsReturning && result.rows.isNotEmpty) {
        return fromRow(result.rows.first);
      }

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

      return fromRow(valuesWithTimestamps.cast<String, dynamic>());
    });
  }

  @override
  Future<List<T>> bulkCreate(List<Map<String, Object?>> objects) async {
    if (objects.isEmpty) return [];
    final objectsWithTimestamps = objects.map(_injectCreateValues).toList();

    final query = compiler.compileBulkInsert(
      table: tableName,
      rows: objectsWithTimestamps,
      returning: compiler.dialect.supportsReturning,
      returningColumn: '*',
    );

    return pool.withConnection((conn) async {
      final result = await conn.execute(query.sql, query.parameters);

      if (compiler.dialect.supportsReturning && result.rows.isNotEmpty) {
        return result.rows.map(fromRow).toList();
      }

      return objectsWithTimestamps.map((obj) => fromRow(obj.cast<String, dynamic>())).toList();
    });
  }

  @override
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<Object?>? params]) async {
    return pool.withConnection((conn) async {
      return conn.query(sql, params);
    });
  }

  @override
  Future<List<Map<String, dynamic>>> executeValues(QueryConfig config, List<String> fields) async {
    final query = compiler.compileSelect(table: tableName, config: config, columns: fields);

    return pool.withConnection((conn) async {
      return conn.query(query.sql, query.parameters);
    });
  }

  @override
  Future<List<V>> executeValuesFlat<V>(QueryConfig config, String field) async {
    final query = compiler.compileSelect(table: tableName, config: config, columns: [field]);

    return pool.withConnection((conn) async {
      final rows = await conn.query(query.sql, query.parameters);
      return rows.map((row) => row[field] as V).toList();
    });
  }

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
