/// SQL Compiler - Converts expression AST to SQL strings.
///
/// Each database dialect may have slight variations, so the compiler
/// is parameterized by the dialect.
library;

import '../query/expressions.dart';
import '../query/queryset.dart';
import 'connection.dart';

/// Compiles query configurations and expressions to SQL.
class SqlCompiler {
  final SqlDialect dialect;

  /// Collected parameter values (for parameterized queries)
  final List<Object?> _params = [];

  SqlCompiler(this.dialect);

  /// Get the collected parameters
  List<Object?> get parameters => List.unmodifiable(_params);

  /// Reset the compiler state
  void reset() {
    _params.clear();
  }

  /// Compile a full SELECT query
  CompiledQuery compileSelect({required String table, required QueryConfig config, List<String>? columns}) {
    reset();
    final buffer = StringBuffer();

    // SELECT
    buffer.write('SELECT ');
    if (config.distinct) {
      buffer.write('DISTINCT ');
    }

    // Columns
    if (columns != null && columns.isNotEmpty) {
      buffer.write(columns.map((c) => dialect.quoteIdentifier(c)).join(', '));
    } else if (config.only.isNotEmpty) {
      buffer.write(config.only.map((c) => dialect.quoteIdentifier(c)).join(', '));
    } else {
      buffer.write('*');
    }

    // Annotations (calculated fields)
    if (config.annotations.isNotEmpty) {
      for (final entry in config.annotations.entries) {
        buffer.write(', ');
        buffer.write(compileExpression(entry.value));
        buffer.write(' AS ');
        buffer.write(dialect.quoteIdentifier(entry.key));
      }
    }

    // FROM
    buffer.write(' FROM ');
    buffer.write(dialect.quoteIdentifier(table));

    // JOINs for selectRelated
    for (final relation in config.selectRelated) {
      buffer.write(_compileJoin(table, relation));
    }

    // WHERE
    final whereClause = _compileWhere(config.filters, config.excludes);
    if (whereClause.isNotEmpty) {
      buffer.write(' WHERE ');
      buffer.write(whereClause);
    }

    // ORDER BY
    if (config.ordering.isNotEmpty) {
      buffer.write(' ORDER BY ');
      buffer.write(config.ordering.map(_compileOrderBy).join(', '));
    }

    // LIMIT / OFFSET
    buffer.write(dialect.limitOffset(config.limit, config.offset));

    return CompiledQuery(buffer.toString(), parameters);
  }

  /// Compile a COUNT query
  CompiledQuery compileCount({required String table, required QueryConfig config}) {
    reset();
    final buffer = StringBuffer();

    buffer.write('SELECT COUNT(*) FROM ');
    buffer.write(dialect.quoteIdentifier(table));

    final whereClause = _compileWhere(config.filters, config.excludes);
    if (whereClause.isNotEmpty) {
      buffer.write(' WHERE ');
      buffer.write(whereClause);
    }

    return CompiledQuery(buffer.toString(), parameters);
  }

  /// Compile an aggregate query
  CompiledQuery compileAggregate({
    required String table,
    required QueryConfig config,
    required Map<String, Expression> aggregates,
  }) {
    reset();
    final buffer = StringBuffer();

    buffer.write('SELECT ');
    final aggParts = <String>[];
    for (final entry in aggregates.entries) {
      final compiled = compileExpression(entry.value);
      aggParts.add('$compiled AS ${dialect.quoteIdentifier(entry.key)}');
    }
    buffer.write(aggParts.join(', '));

    buffer.write(' FROM ');
    buffer.write(dialect.quoteIdentifier(table));

    final whereClause = _compileWhere(config.filters, config.excludes);
    if (whereClause.isNotEmpty) {
      buffer.write(' WHERE ');
      buffer.write(whereClause);
    }

    return CompiledQuery(buffer.toString(), parameters);
  }

  /// Compile an INSERT query
  CompiledQuery compileInsert({
    required String table,
    required Map<String, Object?> values,
    bool returning = false,
    String? returningColumn,
  }) {
    reset();
    final buffer = StringBuffer();

    final columns = values.keys.toList();
    final placeholders = <String>[];

    for (final value in values.values) {
      placeholders.add(_addParam(value));
    }

    buffer.write('INSERT INTO ');
    buffer.write(dialect.quoteIdentifier(table));
    buffer.write(' (');
    buffer.write(columns.map((c) => dialect.quoteIdentifier(c)).join(', '));
    buffer.write(') VALUES (');
    buffer.write(placeholders.join(', '));
    buffer.write(')');

    if (returning && dialect.supportsReturning) {
      buffer.write(' RETURNING ');
      buffer.write(returningColumn ?? '*');
    }

    return CompiledQuery(buffer.toString(), parameters);
  }

  /// Compile a bulk INSERT query
  CompiledQuery compileBulkInsert({
    required String table,
    required List<Map<String, Object?>> rows,
    bool returning = false,
    String? returningColumn,
  }) {
    if (rows.isEmpty) {
      throw ArgumentError('Cannot insert empty list of rows');
    }

    reset();
    final buffer = StringBuffer();

    final columns = rows.first.keys.toList();
    final allPlaceholders = <String>[];

    for (final row in rows) {
      final rowPlaceholders = <String>[];
      for (final col in columns) {
        rowPlaceholders.add(_addParam(row[col]));
      }
      allPlaceholders.add('(${rowPlaceholders.join(', ')})');
    }

    buffer.write('INSERT INTO ');
    buffer.write(dialect.quoteIdentifier(table));
    buffer.write(' (');
    buffer.write(columns.map((c) => dialect.quoteIdentifier(c)).join(', '));
    buffer.write(') VALUES ');
    buffer.write(allPlaceholders.join(', '));

    if (returning && dialect.supportsReturning) {
      buffer.write(' RETURNING ');
      buffer.write(returningColumn ?? '*');
    }

    return CompiledQuery(buffer.toString(), parameters);
  }

  /// Compile an UPDATE query
  CompiledQuery compileUpdate({
    required String table,
    required QueryConfig config,
    required Map<String, Object?> values,
  }) {
    reset();
    final buffer = StringBuffer();

    buffer.write('UPDATE ');
    buffer.write(dialect.quoteIdentifier(table));
    buffer.write(' SET ');

    final setParts = <String>[];
    for (final entry in values.entries) {
      final col = dialect.quoteIdentifier(entry.key);
      final val = _addParam(entry.value);
      setParts.add('$col = $val');
    }
    buffer.write(setParts.join(', '));

    final whereClause = _compileWhere(config.filters, config.excludes);
    if (whereClause.isNotEmpty) {
      buffer.write(' WHERE ');
      buffer.write(whereClause);
    }

    return CompiledQuery(buffer.toString(), parameters);
  }

  /// Compile a DELETE query
  CompiledQuery compileDelete({required String table, required QueryConfig config}) {
    reset();
    final buffer = StringBuffer();

    buffer.write('DELETE FROM ');
    buffer.write(dialect.quoteIdentifier(table));

    final whereClause = _compileWhere(config.filters, config.excludes);
    if (whereClause.isNotEmpty) {
      buffer.write(' WHERE ');
      buffer.write(whereClause);
    }

    return CompiledQuery(buffer.toString(), parameters);
  }

  /// Compile WHERE clause from filters and excludes
  String _compileWhere(List<Q> filters, List<Q> excludes) {
    final parts = <String>[];

    // Compile filters (ANDed together)
    for (final filter in filters) {
      parts.add(compileExpression(filter.expression));
    }

    // Compile excludes as NOT conditions
    for (final exclude in excludes) {
      parts.add('NOT (${compileExpression(exclude.expression)})');
    }

    if (parts.isEmpty) return '';
    return parts.join(' AND ');
  }

  /// Compile ORDER BY clause
  String _compileOrderBy(OrderBy order) {
    final expr = compileExpression(order.expr);
    final dir = order.ascending ? 'ASC' : 'DESC';
    final nulls = order.nulls != null ? ' NULLS ${order.nulls == NullsPosition.first ? 'FIRST' : 'LAST'}' : '';
    return '$expr $dir$nulls';
  }

  /// Compile a JOIN clause for selectRelated
  String _compileJoin(String baseTable, String relation) {
    // This is a simplified version - real implementation would need
    // model metadata to determine join conditions
    final parts = relation.split('__');
    final joinTable = parts.first;
    return ' LEFT JOIN ${dialect.quoteIdentifier(joinTable)} ON '
        '${dialect.quoteIdentifier(baseTable)}.${dialect.quoteIdentifier('${joinTable}_id')} = '
        '${dialect.quoteIdentifier(joinTable)}.${dialect.quoteIdentifier('id')}';
  }

  /// Compile any expression to SQL
  String compileExpression(Expression expr) {
    return switch (expr) {
      ColumnRef e => _compileColumnRef(e),
      Value e => _compileValue(e),
      Comparison e => _compileComparison(e),
      BooleanExpr e => _compileBooleanExpr(e),
      NotExpr e => _compileNotExpr(e),
      ArithmeticExpr e => _compileArithmeticExpr(e),
      FunctionCall e => _compileFunctionCall(e),
      F e => _compileF(e),
      Q e => compileExpression(e.expression),
      _ => throw UnsupportedError('Unknown expression type: ${expr.runtimeType}'),
    };
  }

  String _compileColumnRef(ColumnRef expr) {
    if (expr.table.isNotEmpty) {
      return '${dialect.quoteIdentifier(expr.table)}.${dialect.quoteIdentifier(expr.column)}';
    }
    return dialect.quoteIdentifier(expr.column);
  }

  String _compileValue(Value expr) {
    if (expr.value == null) return 'NULL';
    if (expr.value == '*') return '*';
    return _addParam(expr.value);
  }

  String _compileComparison(Comparison expr) {
    final left = compileExpression(expr.left);
    final right = compileExpression(expr.right);

    return switch (expr.op) {
      ComparisonOp.eq => '$left = $right',
      ComparisonOp.ne => '$left != $right',
      ComparisonOp.lt => '$left < $right',
      ComparisonOp.lte => '$left <= $right',
      ComparisonOp.gt => '$left > $right',
      ComparisonOp.gte => '$left >= $right',
      ComparisonOp.like => '$left LIKE $right',
      ComparisonOp.ilike => '$left ILIKE $right',
      ComparisonOp.inList => _compileInList(left, expr.right),
      ComparisonOp.isNull => '$left IS NULL',
      ComparisonOp.isNotNull => '$left IS NOT NULL',
      ComparisonOp.between => throw UnsupportedError('Use BooleanExpr for BETWEEN'),
    };
  }

  String _compileInList(String left, Expression right) {
    if (right is Value && right.value is List) {
      final list = right.value as List;
      final placeholders = list.map((v) => _addParam(v)).join(', ');
      return '$left IN ($placeholders)';
    }
    return '$left IN (${compileExpression(right)})';
  }

  String _compileBooleanExpr(BooleanExpr expr) {
    final left = compileExpression(expr.left);
    final right = compileExpression(expr.right);
    final op = expr.op == BooleanOp.and ? 'AND' : 'OR';
    return '($left $op $right)';
  }

  String _compileNotExpr(NotExpr expr) {
    return 'NOT (${compileExpression(expr.expr)})';
  }

  String _compileArithmeticExpr(ArithmeticExpr expr) {
    final left = compileExpression(expr.left);
    final right = compileExpression(expr.right);
    return '($left ${expr.op.symbol} $right)';
  }

  String _compileFunctionCall(FunctionCall expr) {
    final args = expr.args.map(compileExpression).join(', ');
    final distinct = expr.distinct ? 'DISTINCT ' : '';
    return '${expr.name}($distinct$args)';
  }

  String _compileF(F expr) {
    // F expressions reference other fields
    // Handle nested paths like 'author__name'
    final parts = expr.fieldPath.split('__');
    if (parts.length == 1) {
      return dialect.quoteIdentifier(parts.first);
    }
    // For nested paths, assume table.column format
    return '${dialect.quoteIdentifier(parts.first)}.${dialect.quoteIdentifier(parts.last)}';
  }

  /// Add a parameter and return its placeholder
  String _addParam(Object? value) {
    _params.add(value);
    return dialect.parameterPlaceholder(_params.length);
  }
}

/// A compiled SQL query with its parameters.
class CompiledQuery {
  final String sql;
  final List<Object?> parameters;

  const CompiledQuery(this.sql, this.parameters);

  @override
  String toString() => 'CompiledQuery($sql, $parameters)';

  /// Get SQL with parameters inlined (for debugging only!)
  String toDebugString() {
    var result = sql;
    for (var i = parameters.length - 1; i >= 0; i--) {
      final param = parameters[i];
      final value = switch (param) {
        null => 'NULL',
        String s => "'${s.replaceAll("'", "''")}'",
        bool b => b.toString().toUpperCase(),
        DateTime dt => "'${dt.toIso8601String()}'",
        _ => param.toString(),
      };
      // Replace placeholders (handle different styles)
      result = result.replaceAll('\$${i + 1}', value); // PostgreSQL
      result = result.replaceAll('?', value); // MySQL/SQLite (first occurrence)
    }
    return result;
  }
}
