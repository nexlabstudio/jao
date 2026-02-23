## [0.3.0] - 2026-02-23

- Bump `jao` dependency to `^0.3.0`

## [0.2.0] - 2025-12-31

- Version bump to align with jao and jao_generator packages

## [0.1.0] - 2025-12-28

### Changed

- `jao init` now creates centralized database configuration in `lib/config/database.dart`
- `jao.yaml` now only contains paths configuration (`migrations_path`, `models_path`)
- `bin/migrate.dart` template now imports from `lib/config/database.dart`
- Removed `--db` and `--type` options from `jao init` (database type is now configured in code)

### Added

- `lib/config/database.dart` as single source of truth for database settings
- PostgreSQL and MySQL examples in generated `lib/config/database.dart`

## [0.0.1] - 2025-12-28

### Added

- Initial release
- `jao init` - Initialize JAO in a project
- `jao make` - Create empty migration files
- `jao makemigrations` - Auto-generate migrations from model changes
- `jao migrate` - Apply pending migrations
- `jao rollback` - Rollback migrations
- `jao status` - Show migration status
- `jao reset` - Rollback all migrations
- `jao refresh` - Reset and re-run all migrations
- `jao sql` - Show SQL for migrations
- Support for SQLite, PostgreSQL, and MySQL
- Configuration via `jao.yaml` or environment variables
- Dry-run mode for all commands
