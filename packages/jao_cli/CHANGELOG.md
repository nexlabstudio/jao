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
