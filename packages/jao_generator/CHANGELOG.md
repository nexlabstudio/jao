## [Unreleased]

## [0.3.3] - 2026-03-16

### Changed

- `_extractDefaultValue` now returns typed values (`int`, `double`, `bool`, `String`) instead of stringifying all defaults
- Generated `ModelFieldSchema.defaultValue` emits typed literals (`false`, `0`, `3.14`) instead of quoted strings (`'false'`, `'0'`)
- Generated `defaultValues` map in `ModelRegistration` emits typed values directly

## [0.3.2] - 2026-03-16

### Fixed

- Annotation fields inherited via superclass chain (e.g., `unique` and `maxLength` on `EmailField` which extends `CharField` which extends `Field`) are now correctly resolved
  - `DartObject.getField()` only returns directly declared fields — added `_getInheritedField()` to walk the `(super)` chain
  - Applied to all annotation field reads: `unique`, `maxLength`, `defaultValue`, `autoNowAdd`, `autoNow`, `autoGenerate`, `maxDigits`, `decimalPlaces`, `storeAsInt`, `onDelete`, `to`, `toColumn`

## [0.3.1] - 2026-03-16

### Fixed

- Generated `ModelFieldSchema` now emits `defaultValue`, `maxLength`, `unique`, `precision`, `scale`, and `onDelete` from field annotations
- Migrations previously lost string lengths, default values, unique constraints, decimal precision/scale, and FK on-delete actions because the code generator did not pass these attributes through
- `@DateField` now correctly extracts `autoNowAdd` and `autoNow` (was previously ignored)

## [0.3.0] - 2026-02-23

### Added

- `EnumField` support for enum-to-database mapping:
  - Generates `fromRow` with `Enum.values.byName()` for string storage (default)
  - Generates `fromRow` with `Enum.values[index]` for int storage (`storeAsInt: true`)
  - Generates `toRow` with `.name` or `.index` based on storage type
  - Handles nullable enum fields correctly
  - Schema uses `varchar` for string-based or `integer` for int-based storage

## [0.2.3] - 2026-02-09

### Added

- `defaultValue` support for field annotations:
  - Extracts `defaultValue` from `@CharField`, `@IntegerField`, `@BooleanField`, `@FloatField`, and other field types
  - Generates `defaultValues` map in `ModelRegistration` for runtime default value injection
  - Supports string, int, bool, and double default values
- `ForeignKeyInfo` in schema for FK fields:
  - Generated `ModelFieldSchema` now includes `foreignKey: ForeignKeyInfo(...)` for `@ForeignKey` and `@OneToOneField`
  - Enables migration generator to create proper foreign key constraints
  - Supports nullable foreign key relationships

## [0.2.2] - 2026-02-02

### Fixed

- Foreign key field type now resolves from the related model's primary key type instead of being hardcoded to `int`
- `@ForeignKey` and `@OneToOneField` to a model with `@UuidPrimaryKey` now correctly generates `String`/`StringFieldRef` instead of `int`/`IntFieldRef`

### Added

- `_resolvePkType` helper for inspecting related model PK annotations at generation time
- Tests for FK type resolution with `@UuidPrimaryKey` and `@AutoField` targets

## [0.2.1] - 2026-01-01

### Added

- Generates `_registerMetadata()` method in companion class for model metadata registration
- Extracts ForeignKey/OneToOneField relationship info for proper JOIN support
- Auto-registers `ModelMetadata` with `ModelRegistry` on first Manager access

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
