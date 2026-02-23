## [Unreleased] - 2026-02-23

### Added

- Multi-model transaction support via `Jao.instance.transaction()`:
  - New `JaoTransaction` class that holds a shared `Transaction` and vends typed `TransactionExecutor<T>` instances for any registered model
  - New `Jao.transaction<R>()` method — acquires one connection, wraps it in one atomic transaction, and exposes all registered models via `tx.on<T>()`
  - All `tx.on<T>()` calls within a single `transaction()` block share the same underlying DB connection and commit/roll back together
  - Existing single-model `executor.transaction()` API is unchanged (no breaking change)

- `EnumField` support in migration schema generator:
  - `fieldDefToDbType` now handles `EnumField` annotation
  - Returns `FieldType.integer` when `storeAsInt: true`
  - Returns `FieldType.varchar` for string-based storage (default)
- Auto-detection of nullability changes in `_generateTableDiff`:
  - Compares model field nullability with database column nullability
  - Generates `AlterColumn` operations when nullability differs
  - Skips primary key fields (SQLite reports PK as nullable even when NOT NULL)
- Auto-detection of type changes in `_generateTableDiff`:
  - Normalizes raw database type strings to `FieldType` for comparison
  - Supports SQLite, PostgreSQL, and MySQL type naming conventions
  - Generates `AlterColumn` operations when types differ
  - Skips integer-like type mismatches for PKs (serial vs integer)
- `AlterColumn` migration code generation:
  - Generates `builder.alterColumn()` calls with proper modifiers
  - Supports nullability changes (`col.nullable()` / `col.notNullable()`)
  - Supports type changes, default values, and column renames
  - Generates reverse operations in `down()` for nullability changes
- SQLite type equivalence logic in `_generateTableDiff`:
  - Prevents false positive type changes due to SQLite type affinity
  - TEXT types (varchar, timestamp, uuid, json) are equivalent in SQLite
  - INTEGER types (int, bigint, boolean, serial) are equivalent in SQLite
  - REAL types (real, double, decimal) are equivalent in SQLite
  - BLOB types (bytea, blob) are equivalent in SQLite
- SQLite table recreation for `AlterColumn` operations:
  - Implements Django-style `_remake_table` pattern for SQLite
  - Automatically renames old table, creates new table with modified schema
  - Copies data from old table to new table preserving all rows
  - Recreates indexes and foreign key constraints
  - Supports nullability changes, type changes, default values, and renames

## [0.2.5] - 2026-02-09

### Added

- Default values support for model fields:
  - `defaultValues` parameter in `ModelRegistration` and `ModelExecutor`
  - Automatically applies default values during `create()` and `bulkCreate()` when field is not provided or null
  - Works with all field types (string, int, bool, double)

## [0.2.4] - 2026-01-01

### Added

- Common Table Expressions (CTE) support:
  - `Cte` class for defining non-recursive CTEs
  - `RecursiveCte` class for hierarchical/recursive queries
  - `CteRef` and `CteColumnRef` for referencing CTE columns
  - `CteQuery` interface for queries that can be used in CTEs
  - `.with_()` method on QuerySet to attach CTEs
  - `.fromCte()` method on QuerySet to select from a CTE
  - SQL compiler generates `WITH` and `WITH RECURSIVE` clauses

## [0.2.3] - 2026-01-01

### Added

- `values()` method on QuerySet for selecting specific columns as raw maps
- `valuesFlat<V>()` method on QuerySet for selecting a single column as a flat list
- `ValuesQuerySet` and `ValuesListQuerySet` classes with full query chaining support
- New executor methods: `executeValues()` and `executeValuesFlat<V>()`

## [0.2.2] - 2026-01-01

### Added

- Model metadata system for proper JOIN compilation:
  - `ModelMetadata`, `FieldMeta`, `RelationMeta` classes for runtime metadata
  - `ModelRegistry` for global model metadata lookups
  - SQL compiler now uses registry for accurate JOIN clauses
  - Falls back to convention-based joins if metadata not registered

## [0.2.1] - 2026-01-01

### Added

- Case expression support in SQL compiler (`Case`, `When` expressions)

## [0.2.0] - 2025-12-31

### Added

- Type converter functions for cross-database compatibility:
  - `dbDateTime`, `dbDateTimeOrNull` - handles DateTime, String, and int (timestamp)
  - `dbBool`, `dbBoolOrNull` - handles bool, int (0/1), and String
  - `dbInt`, `dbIntOrNull` - handles int, double, and String
  - `dbDouble`, `dbDoubleOrNull` - handles double, int, and String
  - `dbDuration`, `dbDurationOrNull` - handles Duration, int (microseconds), and String

### Fixed

- Cross-database type compatibility issue where `fromRow()` failed with PostgreSQL native types ([#4](https://github.com/nexlabstudio/jao/issues/4))

## [0.1.0] - 2025-12-28

### Added

- `DatabaseConfig.postgres()` factory constructor for PostgreSQL configuration
- `DatabaseConfig.mysql()` factory constructor for MySQL configuration

## [0.0.1] - 2025-12-28

### Added

- Initial release
- Django-style model definitions with field annotations
- Type-safe query building with `Q` expressions
- Multi-database support (SQLite, PostgreSQL, MySQL)
- Schema migrations with up/down support
- Auto-generated `created_at` and `updated_at` timestamps via `autoNow` and `autoNowAdd`
- Manager pattern for database operations
- Field types: `AutoField`, `BigAutoField`, `CharField`, `TextField`, `IntegerField`, `BooleanField`, `FloatField`, `DateTimeField`, `DateField`, `EmailField`, `ForeignKey`
- Query expressions: `eq`, `gt`, `gte`, `lt`, `lte`, `between`, `contains`, `startsWith`, `endsWith`, `iContains`, `isNull`, `isNotNull`
- Logical operators: `&` (AND), `|` (OR) with `Q` expressions
