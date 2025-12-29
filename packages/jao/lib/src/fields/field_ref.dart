/// Field reference system for type-safe queries.
///
/// These classes are used in the generated `$` companion to provide
/// typed field accessors with Django-style lookups.
library;

import 'package:meta/meta.dart';
import '../query/expressions.dart';

/// Base class for all field references.
///
/// A field reference represents a database column and provides
/// type-safe methods for creating query expressions.
@immutable
abstract class FieldRef<T> {
  /// The name of this field in the model
  final String name;

  /// The table/model this field belongs to (for joins)
  final String? table;

  const FieldRef(this.name, {this.table});

  /// Get the column reference expression
  ColumnRef get col => ColumnRef(name, table: table ?? '');

  // === Common lookups available on all fields ===

  /// Exact match: field = value
  Q eq(T value) => Q(Comparison(col, ComparisonOp.eq, Value(value)));

  /// Not equal: field != value
  Q ne(T value) => Q(Comparison(col, ComparisonOp.ne, Value(value)));

  /// Is null
  Q isNull() => Q(Comparison(col, ComparisonOp.isNull, Value(null)));

  /// Is not null
  Q isNotNull() => Q(Comparison(col, ComparisonOp.isNotNull, Value(null)));

  /// In list: field IN (values)
  Q inList(List<T> values) => Q(Comparison(col, ComparisonOp.inList, Value(values)));

  // === Ordering ===

  /// Order ascending
  OrderBy asc() => OrderBy(col, ascending: true);

  /// Order descending
  OrderBy desc() => OrderBy(col, ascending: false);

  // === F-expression comparison ===

  /// Compare with another field
  Q eqField(FieldRef<T> other) => Q(Comparison(col, ComparisonOp.eq, other.col));

  /// Compare with F expression
  Q eqF(F f) => Q(Comparison(col, ComparisonOp.eq, f));

  @override
  String toString() => 'FieldRef<$T>($name)';
}

/// Field reference for comparable types (int, double, DateTime, etc.)
@immutable
abstract class ComparableFieldRef<T> extends FieldRef<T> {
  const ComparableFieldRef(super.name, {super.table});

  /// Less than: field < value
  Q lt(T value) => Q(Comparison(col, ComparisonOp.lt, Value(value)));

  /// Less than or equal: field <= value
  Q lte(T value) => Q(Comparison(col, ComparisonOp.lte, Value(value)));

  /// Greater than: field > value
  Q gt(T value) => Q(Comparison(col, ComparisonOp.gt, Value(value)));

  /// Greater than or equal: field >= value
  Q gte(T value) => Q(Comparison(col, ComparisonOp.gte, Value(value)));

  /// Between: field BETWEEN low AND high
  Q between(T low, T high) => Q(
        BooleanExpr(
          Comparison(col, ComparisonOp.gte, Value(low)),
          BooleanOp.and,
          Comparison(col, ComparisonOp.lte, Value(high)),
        ),
      );

  /// Compare less than another field
  Q ltField(FieldRef<T> other) => Q(Comparison(col, ComparisonOp.lt, other.col));

  /// Compare with F expression
  Q ltF(F f) => Q(Comparison(col, ComparisonOp.lt, f));

  Q lteF(F f) => Q(Comparison(col, ComparisonOp.lte, f));
  Q gtF(F f) => Q(Comparison(col, ComparisonOp.gt, f));
  Q gteF(F f) => Q(Comparison(col, ComparisonOp.gte, f));
}

/// Field reference for numeric types with arithmetic support
@immutable
abstract class NumericFieldRef<T extends num> extends ComparableFieldRef<T> {
  const NumericFieldRef(super.name, {super.table});

  /// Add to field value
  ArithmeticExpr operator +(Object other) => ArithmeticExpr(col, ArithmeticOp.add, _toExpr(other));

  /// Subtract from field value
  ArithmeticExpr operator -(Object other) => ArithmeticExpr(col, ArithmeticOp.subtract, _toExpr(other));

  /// Multiply field value
  ArithmeticExpr operator *(Object other) => ArithmeticExpr(col, ArithmeticOp.multiply, _toExpr(other));

  /// Divide field value
  ArithmeticExpr operator /(Object other) => ArithmeticExpr(col, ArithmeticOp.divide, _toExpr(other));

  /// Modulo
  ArithmeticExpr operator %(Object other) => ArithmeticExpr(col, ArithmeticOp.modulo, _toExpr(other));

  Expression _toExpr(Object value) => switch (value) {
        Expression e => e,
        FieldRef f => f.col,
        _ => Value(value),
      };
}

// === Concrete Field Reference Types ===

/// String field reference with text-specific lookups
@immutable
class StringFieldRef extends FieldRef<String> {
  const StringFieldRef(super.name, {super.table});

  /// Case-sensitive contains: field LIKE '%value%'
  Q contains(String value) => Q(Comparison(col, ComparisonOp.like, Value('%$value%')));

  /// Case-insensitive contains
  Q iContains(String value) => Q(Comparison(col, ComparisonOp.ilike, Value('%$value%')));

  /// Starts with: field LIKE 'value%'
  Q startsWith(String value) => Q(Comparison(col, ComparisonOp.like, Value('$value%')));

  /// Case-insensitive starts with
  Q iStartsWith(String value) => Q(Comparison(col, ComparisonOp.ilike, Value('$value%')));

  /// Ends with: field LIKE '%value'
  Q endsWith(String value) => Q(Comparison(col, ComparisonOp.like, Value('%$value')));

  /// Case-insensitive ends with
  Q iEndsWith(String value) => Q(Comparison(col, ComparisonOp.ilike, Value('%$value')));

  /// Case-insensitive exact match
  Q iEq(String value) => Q(Comparison(col, ComparisonOp.ilike, Value(value)));

  /// Regex match (database-specific)
  Q regex(String pattern) => Q(Comparison(FunctionCall('REGEXP', [col, Value(pattern)]), ComparisonOp.eq, Value(true)));
}

/// Integer field reference
@immutable
class IntFieldRef extends NumericFieldRef<int> {
  const IntFieldRef(super.name, {super.table});
}

/// Double/decimal field reference
@immutable
class DoubleFieldRef extends NumericFieldRef<double> {
  const DoubleFieldRef(super.name, {super.table});
}

/// Boolean field reference
@immutable
class BoolFieldRef extends FieldRef<bool> {
  const BoolFieldRef(super.name, {super.table});

  /// Is true
  Q isTrue() => eq(true);

  /// Is false
  Q isFalse() => eq(false);
}

/// DateTime field reference
@immutable
class DateTimeFieldRef extends ComparableFieldRef<DateTime> {
  const DateTimeFieldRef(super.name, {super.table});

  /// Extract year
  Q year(int value) => Q(Comparison(FunctionCall('EXTRACT', [Value('YEAR'), col]), ComparisonOp.eq, Value(value)));

  /// Extract month (1-12)
  Q month(int value) => Q(Comparison(FunctionCall('EXTRACT', [Value('MONTH'), col]), ComparisonOp.eq, Value(value)));

  /// Extract day of month
  Q day(int value) => Q(Comparison(FunctionCall('EXTRACT', [Value('DAY'), col]), ComparisonOp.eq, Value(value)));

  /// Date only comparison (ignores time)
  Q date(DateTime value) => Q(Comparison(FunctionCall('DATE', [col]), ComparisonOp.eq, Value(value)));
}

/// Duration field reference (for interval types)
@immutable
class DurationFieldRef extends ComparableFieldRef<Duration> {
  const DurationFieldRef(super.name, {super.table});
}

// === Related Field References (for ForeignKey, etc.) ===

/// Reference to a related model for traversing relationships
@immutable
class RelatedFieldRef<T> extends FieldRef<T> {
  /// The related model's fields accessor
  final T Function() fieldsAccessor;

  const RelatedFieldRef(super.name, this.fieldsAccessor, {super.table});

  /// Access the related model's fields for query building
  T get $ => fieldsAccessor();
}
