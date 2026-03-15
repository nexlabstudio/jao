/// Schema Builder - Fluent API for defining database schema changes.
///
/// Used within migrations to create tables, add columns, create indexes, etc.
library;

import 'package:meta/meta.dart';
import '../db/connection.dart';

/// Fluent builder for creating table schemas.
class TableBuilder {
  final String name;
  final List<ColumnDefinition> _columns = [];
  final List<IndexDefinition> _indexes = [];
  final List<ForeignKeyDefinition> _foreignKeys = [];
  String? _primaryKey;
  bool _ifNotExists = false;

  TableBuilder(this.name);

  /// Only create if table doesn't exist
  TableBuilder ifNotExists() {
    _ifNotExists = true;
    return this;
  }

  // Primary Key Columns

  /// Auto-incrementing integer primary key
  TableBuilder id([String name = 'id']) {
    _columns.add(ColumnDefinition(name: name, type: FieldType.serial, nullable: false, primaryKey: true));
    _primaryKey = name;
    return this;
  }

  /// Big auto-incrementing integer primary key
  TableBuilder bigId([String name = 'id']) {
    _columns.add(ColumnDefinition(name: name, type: FieldType.bigSerial, nullable: false, primaryKey: true));
    _primaryKey = name;
    return this;
  }

  /// UUID primary key (UUID is generated in Dart by the executor)
  TableBuilder uuid([String name = 'id']) {
    _columns.add(
      ColumnDefinition(
        name: name,
        type: FieldType.uuid,
        nullable: false,
        primaryKey: true,
      ),
    );
    _primaryKey = name;
    return this;
  }

  // String Columns

  /// VARCHAR column
  TableBuilder string(String name, {int length = 255, bool nullable = false, String? defaultValue}) {
    _columns.add(
      ColumnDefinition(
        name: name,
        type: FieldType.varchar,
        nullable: nullable,
        length: length,
        defaultValue: defaultValue,
      ),
    );
    return this;
  }

  /// TEXT column (unlimited length)
  TableBuilder text(String name, {bool nullable = false, String? defaultValue}) {
    _columns.add(ColumnDefinition(name: name, type: FieldType.text, nullable: nullable, defaultValue: defaultValue));
    return this;
  }

  /// CHAR column (fixed length)
  TableBuilder char(String name, {int length = 1, bool nullable = false, String? defaultValue}) {
    _columns.add(
      ColumnDefinition(
        name: name,
        type: FieldType.char,
        nullable: nullable,
        length: length,
        defaultValue: defaultValue,
      ),
    );
    return this;
  }

  // Numeric Columns

  /// INTEGER column
  TableBuilder integer(String name, {bool nullable = false, int? defaultValue}) {
    _columns.add(
      ColumnDefinition(name: name, type: FieldType.integer, nullable: nullable, defaultValue: defaultValue?.toString()),
    );
    return this;
  }

  /// SMALLINT column
  TableBuilder smallInteger(String name, {bool nullable = false, int? defaultValue}) {
    _columns.add(
      ColumnDefinition(
        name: name,
        type: FieldType.smallInt,
        nullable: nullable,
        defaultValue: defaultValue?.toString(),
      ),
    );
    return this;
  }

  /// BIGINT column
  TableBuilder bigInteger(String name, {bool nullable = false, int? defaultValue}) {
    _columns.add(
      ColumnDefinition(name: name, type: FieldType.bigInt, nullable: nullable, defaultValue: defaultValue?.toString()),
    );
    return this;
  }

  /// FLOAT/REAL column
  TableBuilder float(String name, {bool nullable = false, double? defaultValue}) {
    _columns.add(
      ColumnDefinition(name: name, type: FieldType.real, nullable: nullable, defaultValue: defaultValue?.toString()),
    );
    return this;
  }

  /// DOUBLE PRECISION column
  TableBuilder doublePrecision(String name, {bool nullable = false, double? defaultValue}) {
    _columns.add(
      ColumnDefinition(
        name: name,
        type: FieldType.doublePrecision,
        nullable: nullable,
        defaultValue: defaultValue?.toString(),
      ),
    );
    return this;
  }

  /// DECIMAL column
  TableBuilder decimal(String name, {int precision = 10, int scale = 2, bool nullable = false, String? defaultValue}) {
    _columns.add(
      ColumnDefinition(
        name: name,
        type: FieldType.decimal,
        nullable: nullable,
        precision: precision,
        scale: scale,
        defaultValue: defaultValue,
      ),
    );
    return this;
  }

  // Boolean

  /// BOOLEAN column
  TableBuilder boolean(String name, {bool nullable = false, bool? defaultValue}) {
    _columns.add(
      ColumnDefinition(name: name, type: FieldType.boolean, nullable: nullable, defaultValue: defaultValue?.toString()),
    );
    return this;
  }

  // Date/Time Columns

  /// DATE column
  TableBuilder date(String name, {bool nullable = false, String? defaultValue}) {
    _columns.add(ColumnDefinition(name: name, type: FieldType.date, nullable: nullable, defaultValue: defaultValue));
    return this;
  }

  /// TIME column
  TableBuilder time(String name, {bool nullable = false, String? defaultValue}) {
    _columns.add(ColumnDefinition(name: name, type: FieldType.time, nullable: nullable, defaultValue: defaultValue));
    return this;
  }

  /// TIMESTAMP column
  TableBuilder timestamp(String name, {bool nullable = false, bool useCurrent = false}) {
    _columns.add(
      ColumnDefinition(
        name: name,
        type: FieldType.timestamp,
        nullable: nullable,
        defaultValue: useCurrent ? 'CURRENT_TIMESTAMP' : null,
      ),
    );
    return this;
  }

  /// TIMESTAMP WITH TIME ZONE column
  TableBuilder timestampTz(String name, {bool nullable = false, bool useCurrent = false}) {
    _columns.add(
      ColumnDefinition(
        name: name,
        type: FieldType.timestampTz,
        nullable: nullable,
        defaultValue: useCurrent ? 'CURRENT_TIMESTAMP' : null,
      ),
    );
    return this;
  }

  /// Add created_at timestamp
  TableBuilder createdAt() => timestampTz('created_at', useCurrent: true);

  /// Add updated_at timestamp
  TableBuilder updatedAt() => timestampTz('updated_at', useCurrent: true);

  /// Add both created_at and updated_at
  TableBuilder timestamps() {
    createdAt();
    updatedAt();
    return this;
  }

  // Special Types

  /// BYTEA/BLOB column
  TableBuilder binary(String name, {bool nullable = false}) {
    _columns.add(ColumnDefinition(name: name, type: FieldType.bytea, nullable: nullable));
    return this;
  }

  /// UUID column
  TableBuilder uuidColumn(String name, {bool nullable = false, String? defaultValue}) {
    _columns.add(ColumnDefinition(name: name, type: FieldType.uuid, nullable: nullable, defaultValue: defaultValue));
    return this;
  }

  /// JSON column
  TableBuilder json(String name, {bool nullable = false, String? defaultValue}) {
    _columns.add(ColumnDefinition(name: name, type: FieldType.json, nullable: nullable, defaultValue: defaultValue));
    return this;
  }

  /// JSONB column (PostgreSQL)
  TableBuilder jsonb(String name, {bool nullable = false, String? defaultValue}) {
    _columns.add(ColumnDefinition(name: name, type: FieldType.jsonb, nullable: nullable, defaultValue: defaultValue));
    return this;
  }

  // Enum

  /// Enum column (stored as string)
  TableBuilder enumString(String name, List<String> values, {bool nullable = false, String? defaultValue}) {
    // Store as VARCHAR with a CHECK constraint
    _columns.add(
      ColumnDefinition(
        name: name,
        type: FieldType.varchar,
        nullable: nullable,
        length: values.map((v) => v.length).reduce((a, b) => a > b ? a : b),
        defaultValue: defaultValue,
        check: "${name} IN (${values.map((v) => "'$v'").join(', ')})",
      ),
    );
    return this;
  }

  // Foreign Keys

  /// Foreign key reference to another table
  TableBuilder foreignKey(
    String column,
    String referencedTable, {
    String referencedColumn = 'id',
    OnDeleteAction onDelete = OnDeleteAction.cascade,
    OnUpdateAction onUpdate = OnUpdateAction.cascade,
    bool nullable = false,
  }) {
    // Add the column
    _columns.add(ColumnDefinition(name: column, type: FieldType.integer, nullable: nullable));

    // Add the foreign key constraint
    _foreignKeys.add(
      ForeignKeyDefinition(
        column: column,
        referencedTable: referencedTable,
        referencedColumn: referencedColumn,
        onDelete: onDelete,
        onUpdate: onUpdate,
      ),
    );

    return this;
  }

  /// Big integer foreign key
  TableBuilder bigForeignKey(
    String column,
    String referencedTable, {
    String referencedColumn = 'id',
    OnDeleteAction onDelete = OnDeleteAction.cascade,
    OnUpdateAction onUpdate = OnUpdateAction.cascade,
    bool nullable = false,
  }) {
    _columns.add(ColumnDefinition(name: column, type: FieldType.bigInt, nullable: nullable));

    _foreignKeys.add(
      ForeignKeyDefinition(
        column: column,
        referencedTable: referencedTable,
        referencedColumn: referencedColumn,
        onDelete: onDelete,
        onUpdate: onUpdate,
      ),
    );

    return this;
  }

  // Indexes

  /// Create an index on one or more columns
  TableBuilder index(List<String> columns, {String? name, bool unique = false}) {
    _indexes.add(
      IndexDefinition(name: name ?? 'idx_${this.name}_${columns.join('_')}', columns: columns, unique: unique),
    );
    return this;
  }

  /// Create a unique index
  TableBuilder uniqueIndex(List<String> columns, {String? name}) {
    return index(columns, name: name, unique: true);
  }

  /// Create unique constraint on a single column
  TableBuilder unique(String column) {
    return index([column], unique: true);
  }

  // Soft Delete

  /// Add soft delete columns (is_deleted, deleted_at)
  TableBuilder softDeletes() {
    boolean('is_deleted', defaultValue: false);
    timestampTz('deleted_at', nullable: true);
    return this;
  }

  // Build

  /// Build the table definition
  TableDefinition build() {
    return TableDefinition(
      name: name,
      columns: _columns,
      indexes: _indexes,
      foreignKeys: _foreignKeys,
      primaryKey: _primaryKey,
      ifNotExists: _ifNotExists,
    );
  }
}

/// Definition of a database column.
@immutable
class ColumnDefinition {
  final String name;
  final FieldType type;
  final bool nullable;
  final bool primaryKey;
  final int? length;
  final int? precision;
  final int? scale;
  final String? defaultValue;
  final String? check;

  const ColumnDefinition({
    required this.name,
    required this.type,
    this.nullable = true,
    this.primaryKey = false,
    this.length,
    this.precision,
    this.scale,
    this.defaultValue,
    this.check,
  });
}

/// Definition of a database index.
@immutable
class IndexDefinition {
  final String name;
  final List<String> columns;
  final bool unique;

  const IndexDefinition({required this.name, required this.columns, this.unique = false});
}

/// Definition of a foreign key constraint.
@immutable
class ForeignKeyDefinition {
  final String column;
  final String referencedTable;
  final String referencedColumn;
  final OnDeleteAction onDelete;
  final OnUpdateAction onUpdate;

  const ForeignKeyDefinition({
    required this.column,
    required this.referencedTable,
    required this.referencedColumn,
    this.onDelete = OnDeleteAction.cascade,
    this.onUpdate = OnUpdateAction.cascade,
  });
}

/// Foreign key ON DELETE action.
enum OnDeleteAction { cascade, restrict, setNull, setDefault, noAction }

/// Foreign key ON UPDATE action.
enum OnUpdateAction { cascade, restrict, setNull, setDefault, noAction }

/// Complete table definition.
@immutable
class TableDefinition {
  final String name;
  final List<ColumnDefinition> columns;
  final List<IndexDefinition> indexes;
  final List<ForeignKeyDefinition> foreignKeys;
  final String? primaryKey;
  final bool ifNotExists;

  const TableDefinition({
    required this.name,
    required this.columns,
    this.indexes = const [],
    this.foreignKeys = const [],
    this.primaryKey,
    this.ifNotExists = false,
  });
}

// Column Modification Builder

/// Builder for modifying an existing column.
class ColumnModifier {
  final String table;
  final String column;
  FieldType? _type;
  bool? _nullable;
  String? _defaultValue;
  String? _rename;
  bool _dropDefault = false;

  ColumnModifier(this.table, this.column);

  /// Change the column type
  ColumnModifier type(FieldType type) {
    _type = type;
    return this;
  }

  /// Make nullable
  ColumnModifier nullable() {
    _nullable = true;
    return this;
  }

  /// Make not nullable
  ColumnModifier notNullable() {
    _nullable = false;
    return this;
  }

  /// Set default value
  ColumnModifier defaultValue(String value) {
    _defaultValue = value;
    return this;
  }

  /// Drop default value
  ColumnModifier dropDefault() {
    _dropDefault = true;
    return this;
  }

  /// Rename the column
  ColumnModifier renameTo(String newName) {
    _rename = newName;
    return this;
  }

  ColumnModification build() {
    return ColumnModification(
      table: table,
      column: column,
      type: _type,
      nullable: _nullable,
      defaultValue: _defaultValue,
      rename: _rename,
      dropDefault: _dropDefault,
    );
  }
}

/// Represents a column modification.
@immutable
class ColumnModification {
  final String table;
  final String column;
  final FieldType? type;
  final bool? nullable;
  final String? defaultValue;
  final String? rename;
  final bool dropDefault;

  const ColumnModification({
    required this.table,
    required this.column,
    this.type,
    this.nullable,
    this.defaultValue,
    this.rename,
    this.dropDefault = false,
  });
}
