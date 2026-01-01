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
