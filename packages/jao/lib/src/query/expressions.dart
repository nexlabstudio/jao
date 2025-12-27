/// Expression system for building SQL queries.
///
/// Expressions represent operations that can be compiled to SQL.
/// They form an AST that gets translated by database adapters.
library;

import 'package:meta/meta.dart';

/// Base class for all expressions in the query system.
///
/// An expression represents a value or operation that can be
/// compiled to SQL by a database adapter.
@immutable
sealed class Expression {
  const Expression();
}

/// A reference to a column/field in the database.
@immutable
class ColumnRef extends Expression {
  final String table;
  final String column;

  const ColumnRef(this.column, {this.table = ''});

  @override
  String toString() => table.isEmpty ? column : '$table.$column';
}

/// A literal value (string, int, bool, etc.)
@immutable
class Value extends Expression {
  final Object? value;

  const Value(this.value);

  @override
  String toString() => 'Value($value)';
}

/// A comparison expression (=, !=, <, >, <=, >=, LIKE, IN, etc.)
@immutable
class Comparison extends Expression {
  final Expression left;
  final ComparisonOp op;
  final Expression right;

  const Comparison(this.left, this.op, this.right);

  @override
  String toString() => '($left ${op.name} $right)';
}

/// Comparison operators
enum ComparisonOp {
  eq, // =
  ne, // !=
  lt, // <
  lte, // <=
  gt, // >
  gte, // >=
  like, // LIKE
  ilike, // ILIKE (case-insensitive)
  inList, // IN (...)
  isNull, // IS NULL
  isNotNull, // IS NOT NULL
  between, // BETWEEN
}

/// Boolean combination (AND, OR)
@immutable
class BooleanExpr extends Expression {
  final Expression left;
  final BooleanOp op;
  final Expression right;

  const BooleanExpr(this.left, this.op, this.right);

  @override
  String toString() => '($left ${op.name} $right)';
}

enum BooleanOp { and, or }

/// Negation (NOT)
@immutable
class NotExpr extends Expression {
  final Expression expr;

  const NotExpr(this.expr);

  @override
  String toString() => 'NOT($expr)';
}

/// Arithmetic expression (+, -, *, /, %)
@immutable
class ArithmeticExpr extends Expression {
  final Expression left;
  final ArithmeticOp op;
  final Expression right;

  const ArithmeticExpr(this.left, this.op, this.right);

  @override
  String toString() => '($left ${op.symbol} $right)';
}

enum ArithmeticOp {
  add('+'),
  subtract('-'),
  multiply('*'),
  divide('/'),
  modulo('%');

  final String symbol;
  const ArithmeticOp(this.symbol);
}

/// Function call (COUNT, SUM, AVG, etc.)
@immutable
class FunctionCall extends Expression {
  final String name;
  final List<Expression> args;
  final bool distinct;

  const FunctionCall(this.name, this.args, {this.distinct = false});

  @override
  String toString() {
    final distinctStr = distinct ? 'DISTINCT ' : '';
    return '$name($distinctStr${args.join(', ')})';
  }
}

/// Ordering specification
@immutable
class OrderBy {
  final Expression expr;
  final bool ascending;
  final NullsPosition? nulls;

  const OrderBy(this.expr, {this.ascending = true, this.nulls});

  OrderBy asc() => OrderBy(expr, ascending: true, nulls: nulls);
  OrderBy desc() => OrderBy(expr, ascending: false, nulls: nulls);
  OrderBy nullsFirst() => OrderBy(expr, ascending: ascending, nulls: NullsPosition.first);
  OrderBy nullsLast() => OrderBy(expr, ascending: ascending, nulls: NullsPosition.last);

  @override
  String toString() {
    final dir = ascending ? 'ASC' : 'DESC';
    final nullsStr = switch (nulls) {
      final n? => ' NULLS ${n.name.toUpperCase()}',
      null => '',
    };
    return '$expr $dir$nullsStr';
  }
}

enum NullsPosition { first, last }

/// A reference to another field (like Django's F expression)
@immutable
class F extends Expression {
  final String fieldPath;

  const F(this.fieldPath);

  /// Arithmetic operations
  ArithmeticExpr operator +(Object other) => ArithmeticExpr(this, ArithmeticOp.add, _toExpr(other));

  ArithmeticExpr operator -(Object other) => ArithmeticExpr(this, ArithmeticOp.subtract, _toExpr(other));

  ArithmeticExpr operator *(Object other) => ArithmeticExpr(this, ArithmeticOp.multiply, _toExpr(other));

  ArithmeticExpr operator /(Object other) => ArithmeticExpr(this, ArithmeticOp.divide, _toExpr(other));

  ArithmeticExpr operator %(Object other) => ArithmeticExpr(this, ArithmeticOp.modulo, _toExpr(other));

  @override
  String toString() => 'F($fieldPath)';
}

/// Convert various types to expressions
Expression _toExpr(Object value) {
  return switch (value) {
    Expression e => e,
    _ => Value(value),
  };
}

/// Base class for Q (query) objects that can be combined with & and |
@immutable
class Q extends Expression {
  final Expression _expr;

  const Q(this._expr);

  /// Factory for creating Q from a condition
  factory Q.condition(Expression expr) => Q(expr);

  Expression get expression => _expr;

  /// Combine with AND
  Q operator &(Q other) => Q(BooleanExpr(_expr, BooleanOp.and, other._expr));

  /// Combine with OR
  Q operator |(Q other) => Q(BooleanExpr(_expr, BooleanOp.or, other._expr));

  /// Negate
  Q operator ~() => Q(NotExpr(_expr));

  @override
  String toString() => 'Q($_expr)';
}

/// CASE WHEN expression
@immutable
class Case extends Expression {
  final List<When> whens;
  final Expression? elseResult;

  const Case(this.whens, {this.elseResult});

  @override
  String toString() {
    final whenStr = whens.map((w) => w.toString()).join(' ');
    final elseStr = elseResult != null ? ' ELSE $elseResult' : '';
    return 'CASE $whenStr$elseStr END';
  }
}

/// WHEN clause for CASE expression
@immutable
class When {
  final Expression condition;
  final Expression then;

  const When(this.condition, this.then);

  @override
  String toString() => 'WHEN $condition THEN $then';
}
