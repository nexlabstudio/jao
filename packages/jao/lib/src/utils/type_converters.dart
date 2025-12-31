/// Type conversion utilities for cross-database compatibility.
///
/// Different databases return different types:
/// - PostgreSQL: DateTime objects, bool, proper numeric types
/// - SQLite: Strings for timestamps, int (0/1) for bool
/// - MySQL: Various depending on driver
///
/// These helpers normalize the types.
library;

/// Parse a DateTime from a database value.
///
/// Handles:
/// - DateTime (PostgreSQL) → returned as-is
/// - String (SQLite) → parsed via DateTime.parse
/// - int (Unix timestamp) → converted from milliseconds
DateTime dbDateTime(dynamic value) => switch (value) {
      DateTime dt => dt,
      String s => DateTime.parse(s),
      int ms => DateTime.fromMillisecondsSinceEpoch(ms),
      null => throw ArgumentError('Expected DateTime value, got null'),
      _ => throw ArgumentError('Cannot parse DateTime from ${value.runtimeType}: $value'),
    };

/// Parse a nullable DateTime from a database value.
DateTime? dbDateTimeOrNull(dynamic value) => switch (value) {
      null => null,
      _ => dbDateTime(value),
    };

/// Parse a bool from a database value.
///
/// Handles:
/// - bool (PostgreSQL) → returned as-is
/// - int (SQLite: 0/1) → converted
/// - String ('true'/'false', '0'/'1') → parsed
bool dbBool(dynamic value) => switch (value) {
      bool b => b,
      int i => i != 0,
      String s => switch (s.toLowerCase()) {
          'true' || '1' || 'yes' => true,
          _ => false,
        },
      null => throw ArgumentError('Expected bool value, got null'),
      _ => throw ArgumentError('Cannot parse bool from ${value.runtimeType}: $value'),
    };

/// Parse a nullable bool from a database value.
bool? dbBoolOrNull(dynamic value) => switch (value) {
      null => null,
      _ => dbBool(value),
    };

/// Parse an int from a database value.
///
/// Handles:
/// - int → returned as-is
/// - double → truncated
/// - String → parsed
int dbInt(dynamic value) => switch (value) {
      int i => i,
      double d => d.toInt(),
      String s => int.parse(s),
      null => throw ArgumentError('Expected int value, got null'),
      _ => throw ArgumentError('Cannot parse int from ${value.runtimeType}: $value'),
    };

/// Parse a nullable int from a database value.
int? dbIntOrNull(dynamic value) => switch (value) {
      null => null,
      _ => dbInt(value),
    };

/// Parse a double from a database value.
///
/// Handles:
/// - double → returned as-is
/// - int → converted
/// - String → parsed
double dbDouble(dynamic value) => switch (value) {
      double d => d,
      int i => i.toDouble(),
      String s => double.parse(s),
      null => throw ArgumentError('Expected double value, got null'),
      _ => throw ArgumentError('Cannot parse double from ${value.runtimeType}: $value'),
    };

/// Parse a nullable double from a database value.
double? dbDoubleOrNull(dynamic value) => switch (value) {
      null => null,
      _ => dbDouble(value),
    };

/// Parse a Duration from a database value.
///
/// Handles:
/// - Duration → returned as-is
/// - int → microseconds
/// - String → parsed as microseconds
Duration dbDuration(dynamic value) => switch (value) {
      Duration d => d,
      int micros => Duration(microseconds: micros),
      String s => switch (int.tryParse(s)) {
          final micros? => Duration(microseconds: micros),
          null => throw ArgumentError('Cannot parse Duration from String: $s'),
        },
      null => throw ArgumentError('Expected Duration value, got null'),
      _ => throw ArgumentError('Cannot parse Duration from ${value.runtimeType}: $value'),
    };

/// Parse a nullable Duration from a database value.
Duration? dbDurationOrNull(dynamic value) => switch (value) {
      null => null,
      _ => dbDuration(value),
    };
