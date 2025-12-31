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
