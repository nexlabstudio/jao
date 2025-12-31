## [0.2.0] - 2025-12-31

### Changed

- `fromRow()` generation now uses type converter functions (`dbDateTime`, `dbBool`, `dbInt`, `dbDouble`, `dbDuration`) instead of direct type casts
- This enables cross-database compatibility where SQLite returns String/int and PostgreSQL returns native DateTime/bool types

### Fixed

- Cross-database type compatibility issue ([#4](https://github.com/nexlabstudio/jao/issues/4))

## [0.1.0] - 2025-12-28

- Version bump to align with jao and jao_cli packages

## [0.0.1] - 2025-12-28

### Added

- Initial release
- Code generation for JAO models
- Typed field accessors (`$` companion class)
- `fromRow` factory for database row mapping
- `toRow` method for serialization
- Schema generation for migrations
- Support for all JAO field types
- Integration with `build_runner`
