/// Aggregate functions for use in annotations and aggregations.
library;

import 'package:meta/meta.dart';
import 'expressions.dart';

/// Count aggregate
@immutable
class Count extends FunctionCall {
  Count(Expression expr, {bool distinct = false}) : super('COUNT', [expr], distinct: distinct);

  /// Count all rows
  factory Count.all() => Count(Value('*'));
}

/// Sum aggregate
@immutable
class Sum extends FunctionCall {
  Sum(Expression expr) : super('SUM', [expr]);
}

/// Average aggregate
@immutable
class Avg extends FunctionCall {
  Avg(Expression expr) : super('AVG', [expr]);
}

/// Maximum aggregate
@immutable
class Max extends FunctionCall {
  Max(Expression expr) : super('MAX', [expr]);
}

/// Minimum aggregate
@immutable
class Min extends FunctionCall {
  Min(Expression expr) : super('MIN', [expr]);
}

/// Standard deviation aggregate
@immutable
class StdDev extends FunctionCall {
  StdDev(Expression expr) : super('STDDEV', [expr]);
}

/// Variance aggregate
@immutable
class Variance extends FunctionCall {
  Variance(Expression expr) : super('VARIANCE', [expr]);
}

/// String concatenation aggregate
@immutable
class StringAgg extends FunctionCall {
  StringAgg(Expression expr, {String separator = ','}) : super('STRING_AGG', [expr, Value(separator)]);
}

/// Array aggregation
@immutable
class ArrayAgg extends FunctionCall {
  ArrayAgg(Expression expr, {bool distinct = false}) : super('ARRAY_AGG', [expr], distinct: distinct);
}

/// JSON aggregation
@immutable
class JsonAgg extends FunctionCall {
  JsonAgg(Expression expr) : super('JSON_AGG', [expr]);
}

// Case and When are defined in expressions.dart (Expression is sealed)

/// Coalesce - return first non-null value
@immutable
class Coalesce extends FunctionCall {
  Coalesce(List<Expression> exprs) : super('COALESCE', exprs);

  factory Coalesce.withDefault(Expression expr, Object defaultValue) => Coalesce([expr, Value(defaultValue)]);
}

/// NullIf - return null if values are equal
@immutable
class NullIf extends FunctionCall {
  NullIf(Expression expr1, Expression expr2) : super('NULLIF', [expr1, expr2]);
}

/// Greatest - return largest value
@immutable
class Greatest extends FunctionCall {
  Greatest(List<Expression> exprs) : super('GREATEST', exprs);
}

/// Least - return smallest value
@immutable
class Least extends FunctionCall {
  Least(List<Expression> exprs) : super('LEAST', exprs);
}

/// String length
@immutable
class Length extends FunctionCall {
  Length(Expression expr) : super('LENGTH', [expr]);
}

/// Lowercase
@immutable
class Lower extends FunctionCall {
  Lower(Expression expr) : super('LOWER', [expr]);
}

/// Uppercase
@immutable
class Upper extends FunctionCall {
  Upper(Expression expr) : super('UPPER', [expr]);
}

/// Trim whitespace
@immutable
class Trim extends FunctionCall {
  Trim(Expression expr) : super('TRIM', [expr]);
}

/// Substring
@immutable
class Substr extends FunctionCall {
  Substr(Expression expr, int start, [int? length])
      : super('SUBSTR', [expr, Value(start), if (length != null) Value(length)]);
}

/// Concatenate strings
@immutable
class Concat extends FunctionCall {
  Concat(List<Expression> exprs) : super('CONCAT', exprs);
}

/// Replace substring
@immutable
class Replace extends FunctionCall {
  Replace(Expression expr, String from, String to) : super('REPLACE', [expr, Value(from), Value(to)]);
}

/// Current date
@immutable
class CurrentDate extends FunctionCall {
  CurrentDate() : super('CURRENT_DATE', const []);
}

/// Current timestamp
@immutable
class Now extends FunctionCall {
  Now() : super('NOW', const []);
}

/// Extract part of date/time
@immutable
class Extract extends FunctionCall {
  Extract(String part, Expression expr) : super('EXTRACT', [Value(part), expr]);

  factory Extract.year(Expression expr) => Extract('YEAR', expr);
  factory Extract.month(Expression expr) => Extract('MONTH', expr);
  factory Extract.day(Expression expr) => Extract('DAY', expr);
  factory Extract.hour(Expression expr) => Extract('HOUR', expr);
  factory Extract.minute(Expression expr) => Extract('MINUTE', expr);
  factory Extract.second(Expression expr) => Extract('SECOND', expr);
}

/// Truncate date/time to specified precision
@immutable
class DateTrunc extends FunctionCall {
  DateTrunc(String precision, Expression expr) : super('DATE_TRUNC', [Value(precision), expr]);
}

/// Absolute value
@immutable
class Abs extends FunctionCall {
  Abs(Expression expr) : super('ABS', [expr]);
}

/// Round to specified decimal places
@immutable
class Round extends FunctionCall {
  Round(Expression expr, [int places = 0]) : super('ROUND', [expr, Value(places)]);
}

/// Floor (round down)
@immutable
class Floor extends FunctionCall {
  Floor(Expression expr) : super('FLOOR', [expr]);
}

/// Ceiling (round up)
@immutable
class Ceil extends FunctionCall {
  Ceil(Expression expr) : super('CEIL', [expr]);
}

/// Power/exponent
@immutable
class Power extends FunctionCall {
  Power(Expression base, Expression exp) : super('POWER', [base, exp]);
}

/// Square root
@immutable
class Sqrt extends FunctionCall {
  Sqrt(Expression expr) : super('SQRT', [expr]);
}

/// Natural logarithm
@immutable
class Ln extends FunctionCall {
  Ln(Expression expr) : super('LN', [expr]);
}

/// Logarithm base 10
@immutable
class Log extends FunctionCall {
  Log(Expression expr) : super('LOG', [expr]);
}
