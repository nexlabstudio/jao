library;

import '../meta/model_registry.dart';
import '../query/expressions.dart';
import '../query/queryset.dart';
import 'connection.dart';

class SqlCompiler {
  final SqlDialect dialect;
  final List<Object?> _params = [];

  SqlCompiler(this.dialect);

  List<Object?> get parameters => List.unmodifiable(_params);

  void reset() {
    _params.clear();
  }

  CompiledQuery compileSelect({required String table, required QueryConfig config, List<String>? columns}) {
    reset();
    final buffer = StringBuffer();

    if (config.ctes.isNotEmpty) {
      buffer.write(_compileCtes(config.ctes));
      buffer.write(' ');
    }

    buffer.write('SELECT ');
    if (config.distinct) {
      buffer.write('DISTINCT ');
    }

    if (columns != null && columns.isNotEmpty) {
      buffer.write(columns.map((c) => dialect.quoteIdentifier(c)).join(', '));
    } else if (config.only.isNotEmpty) {
      buffer.write(config.only.map((c) => dialect.quoteIdentifier(c)).join(', '));
    } else {
      buffer.write('*');
    }

    if (config.annotations.isNotEmpty) {
      for (final entry in config.annotations.entries) {
        buffer.write(', ');
        buffer.write(compileExpression(entry.value));
        buffer.write(' AS ');
        buffer.write(dialect.quoteIdentifier(entry.key));
      }
    }

    buffer.write(' FROM ');
    final fromTable = config.fromCte ?? table;
    buffer.write(dialect.quoteIdentifier(fromTable));

    for (final relation in config.selectRelated) {
      buffer.write(_compileJoin(fromTable, relation));
    }

    final whereClause = _compileWhere(config.filters, config.excludes);
    if (whereClause.isNotEmpty) {
      buffer.write(' WHERE ');
      buffer.write(whereClause);
    }

    if (config.ordering.isNotEmpty) {
      buffer.write(' ORDER BY ');
      buffer.write(config.ordering.map(_compileOrderBy).join(', '));
    }

    buffer.write(dialect.limitOffset(config.limit, config.offset));

    return CompiledQuery(buffer.toString(), parameters);
  }

  String _compileCtes(List<Object> ctes) {
    final hasRecursive = ctes.any((c) => c is RecursiveCte);
    final buffer = StringBuffer();

    buffer.write('WITH ');
    if (hasRecursive) {
      buffer.write('RECURSIVE ');
    }

    final cteParts = <String>[];
    for (final cte in ctes) {
      cteParts.add(_compileCte(cte));
    }
    buffer.write(cteParts.join(', '));

    return buffer.toString();
  }

  String _compileCte(Object cte) {
    return switch (cte) {
      Cte c => _compileSimpleCte(c),
      RecursiveCte c => _compileRecursiveCte(c),
      _ => throw ArgumentError('Expected Cte or RecursiveCte, got ${cte.runtimeType}'),
    };
  }

  String _compileSimpleCte(Cte cte) {
    final queryConfig = cte.query.cteConfig;
    final innerQuery = _compileCteQuery(queryConfig);
    return '${dialect.quoteIdentifier(cte.name)} AS ($innerQuery)';
  }

  String _compileRecursiveCte(RecursiveCte cte) {
    final baseConfig = cte.base.cteConfig;
    final baseQuery = _compileCteQuery(baseConfig);

    // Build the recursive part by invoking the callback with a CteRef
    final cteRef = CteRef(cte.name);
    final recursiveConfig = cte.recursive(cteRef).cteConfig;
    final recursiveQuery = _compileCteQuery(recursiveConfig);

    return '${dialect.quoteIdentifier(cte.name)} AS ($baseQuery UNION ALL $recursiveQuery)';
  }

  String _compileCteQuery(CteQueryConfig config) {
    final buffer = StringBuffer();

    buffer.write('SELECT ');

    if (config.distinct) {
      buffer.write('DISTINCT ');
    }

    if (config.only.isNotEmpty) {
      buffer.write(config.only.map((c) => dialect.quoteIdentifier(c)).join(', '));
    } else {
      buffer.write('*');
    }

    if (config.tableName != null) {
      buffer.write(' FROM ');
      buffer.write(dialect.quoteIdentifier(config.tableName!));
    }

    final whereClause = _compileWhere(config.filters, config.excludes);
    if (whereClause.isNotEmpty) {
      buffer.write(' WHERE ');
      buffer.write(whereClause);
    }

    if (config.ordering.isNotEmpty) {
      buffer.write(' ORDER BY ');
      buffer.write(config.ordering.map(_compileOrderBy).join(', '));
    }

    if (config.limit != null || config.offset != null) {
      buffer.write(dialect.limitOffset(config.limit, config.offset));
    }

    return buffer.toString();
  }

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

  String _compileWhere(List<Q> filters, List<Q> excludes) {
    final parts = <String>[];
    for (final filter in filters) {
      parts.add(compileExpression(filter.expression));
    }
    for (final exclude in excludes) {
      parts.add('NOT (${compileExpression(exclude.expression)})');
    }
    if (parts.isEmpty) return '';
    return parts.join(' AND ');
  }

  String _compileOrderBy(OrderBy order) {
    final expr = compileExpression(order.expr);
    final dir = order.ascending ? 'ASC' : 'DESC';
    final nulls = order.nulls != null ? ' NULLS ${order.nulls == NullsPosition.first ? 'FIRST' : 'LAST'}' : '';
    return '$expr $dir$nulls';
  }

  String _compileJoin(String baseTable, String relation) {
    final registry = ModelRegistry.instance;
    final joins = registry.resolveJoinPath(baseTable, relation);

    if (joins case final joins? when joins.isNotEmpty) {
      final buffer = StringBuffer();
      for (final join in joins) {
        buffer.write(' LEFT JOIN ${dialect.quoteIdentifier(join.toTable)} ON ');
        buffer.write('${dialect.quoteIdentifier(join.fromTable)}.');
        buffer.write('${dialect.quoteIdentifier(join.fromColumn)} = ');
        buffer.write('${dialect.quoteIdentifier(join.toTable)}.');
        buffer.write(dialect.quoteIdentifier(join.toColumn));
      }
      return buffer.toString();
    }

    // Fallback: convention-based join (table_id -> table.id)
    final parts = relation.split('__');
    final joinTable = parts.first;
    return ' LEFT JOIN ${dialect.quoteIdentifier(joinTable)} ON '
        '${dialect.quoteIdentifier(baseTable)}.${dialect.quoteIdentifier('${joinTable}_id')} = '
        '${dialect.quoteIdentifier(joinTable)}.${dialect.quoteIdentifier('id')}';
  }

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
      Case e => _compileCase(e),
      CteColumnRef e => _compileCteColumnRef(e),
    };
  }

  String _compileCteColumnRef(CteColumnRef expr) {
    return '${dialect.quoteIdentifier(expr.cteName)}.${dialect.quoteIdentifier(expr.column)}';
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

    return switch (expr.op) {
      ComparisonOp.inList => _compileInList(left, expr.right),
      ComparisonOp.isNull => '$left IS NULL',
      ComparisonOp.isNotNull => '$left IS NOT NULL',
      ComparisonOp.between => throw UnsupportedError('Use BooleanExpr for BETWEEN'),
      _ => () {
          final right = compileExpression(expr.right);
          return switch (expr.op) {
            ComparisonOp.eq => '$left = $right',
            ComparisonOp.ne => '$left != $right',
            ComparisonOp.lt => '$left < $right',
            ComparisonOp.lte => '$left <= $right',
            ComparisonOp.gt => '$left > $right',
            ComparisonOp.gte => '$left >= $right',
            ComparisonOp.like => '$left LIKE $right',
            ComparisonOp.ilike => dialect.caseInsensitiveLike(left, right),
            _ => throw StateError('Unhandled comparison op: ${expr.op}'),
          };
        }(),
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
    final parts = expr.fieldPath.split('__');
    if (parts.length == 1) {
      return dialect.quoteIdentifier(parts.first);
    }
    return '${dialect.quoteIdentifier(parts.first)}.${dialect.quoteIdentifier(parts.last)}';
  }

  String _compileCase(Case expr) {
    final buffer = StringBuffer('CASE');
    for (final when in expr.whens) {
      buffer.write(' WHEN ');
      buffer.write(compileExpression(when.condition));
      buffer.write(' THEN ');
      buffer.write(compileExpression(when.then));
    }
    if (expr.elseResult != null) {
      buffer.write(' ELSE ');
      buffer.write(compileExpression(expr.elseResult!));
    }
    buffer.write(' END');
    return buffer.toString();
  }

  String _addParam(Object? value) {
    _params.add(value);
    return dialect.parameterPlaceholder(_params.length);
  }
}

class CompiledQuery {
  final String sql;
  final List<Object?> parameters;

  const CompiledQuery(this.sql, this.parameters);

  @override
  String toString() => 'CompiledQuery($sql, $parameters)';

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
      result = result.replaceAll('\$${i + 1}', value);
      result = result.replaceAll('?', value);
    }
    return result;
  }
}
