/// Migration Operations - Individual schema change operations.
///
/// Each operation can generate SQL for applying and reversing the change.
library;

import 'package:meta/meta.dart';
import '../db/connection.dart';
import 'schema.dart';

/// Base class for all migration operations.
@immutable
abstract class MigrationOperation {
  const MigrationOperation();

  /// Generate SQL to apply this operation
  String toSql(SqlDialect dialect);

  /// Generate SQL to reverse this operation (if reversible)
  String? toReverseSql(SqlDialect dialect);

  /// Whether this operation is reversible
  bool get isReversible;
}

// === Table Operations ===

/// Create a new table.
@immutable
class CreateTable extends MigrationOperation {
  final TableDefinition table;

  const CreateTable(this.table);

  @override
  String toSql(SqlDialect dialect) {
    final buffer = StringBuffer();

    buffer.write('CREATE TABLE ');
    if (table.ifNotExists) buffer.write('IF NOT EXISTS ');
    buffer.write(dialect.quoteIdentifier(table.name));
    buffer.write(' (\n');

    final columnDefs = <String>[];

    for (final col in table.columns) {
      columnDefs.add(_columnToSql(col, dialect));
    }

    // Add primary key constraint if not inline
    if (table.primaryKey != null) {
      final pkCol = table.columns.firstWhere(
        (c) => c.name == table.primaryKey,
        orElse: () => throw StateError('Primary key column not found'),
      );
      // Only add explicit PK if not SERIAL type
      if (pkCol.type != FieldType.serial && pkCol.type != FieldType.bigSerial) {
        columnDefs.add('PRIMARY KEY (${dialect.quoteIdentifier(table.primaryKey!)})');
      }
    }

    // Add foreign key constraints
    for (final fk in table.foreignKeys) {
      columnDefs.add(_foreignKeyToSql(fk, dialect));
    }

    buffer.write('  ${columnDefs.join(',\n  ')}');
    buffer.write('\n)');

    return buffer.toString();
  }

  String _columnToSql(ColumnDefinition col, SqlDialect dialect) {
    final buffer = StringBuffer();

    buffer.write(dialect.quoteIdentifier(col.name));
    buffer.write(' ');

    // Type with length/precision
    String typeStr = dialect.sqlType(col.type);
    if (col.length != null && col.type == FieldType.varchar) {
      typeStr = 'VARCHAR(${col.length})';
    } else if (col.length != null && col.type == FieldType.char) {
      typeStr = 'CHAR(${col.length})';
    } else if (col.precision != null && col.type == FieldType.decimal) {
      typeStr = 'DECIMAL(${col.precision}, ${col.scale ?? 0})';
    }
    buffer.write(typeStr);

    // Nullability
    if (!col.nullable && col.type != FieldType.serial && col.type != FieldType.bigSerial) {
      buffer.write(' NOT NULL');
    }

    // Default value
    if (col.defaultValue != null) {
      buffer.write(' DEFAULT ${col.defaultValue}');
    }

    // Check constraint
    if (col.check != null) {
      buffer.write(' CHECK (${col.check})');
    }

    return buffer.toString();
  }

  String _foreignKeyToSql(ForeignKeyDefinition fk, SqlDialect dialect) {
    final buffer = StringBuffer();

    buffer.write('FOREIGN KEY (${dialect.quoteIdentifier(fk.column)}) ');
    buffer.write('REFERENCES ${dialect.quoteIdentifier(fk.referencedTable)}');
    buffer.write('(${dialect.quoteIdentifier(fk.referencedColumn)})');

    buffer.write(' ON DELETE ${_actionToSql(fk.onDelete)}');
    buffer.write(' ON UPDATE ${_actionToSql(fk.onUpdate)}');

    return buffer.toString();
  }

  String _actionToSql(dynamic action) {
    if (action is OnDeleteAction) {
      return switch (action) {
        OnDeleteAction.cascade => 'CASCADE',
        OnDeleteAction.restrict => 'RESTRICT',
        OnDeleteAction.setNull => 'SET NULL',
        OnDeleteAction.setDefault => 'SET DEFAULT',
        OnDeleteAction.noAction => 'NO ACTION',
      };
    }
    if (action is OnUpdateAction) {
      return switch (action) {
        OnUpdateAction.cascade => 'CASCADE',
        OnUpdateAction.restrict => 'RESTRICT',
        OnUpdateAction.setNull => 'SET NULL',
        OnUpdateAction.setDefault => 'SET DEFAULT',
        OnUpdateAction.noAction => 'NO ACTION',
      };
    }
    return 'NO ACTION';
  }

  @override
  String? toReverseSql(SqlDialect dialect) => 'DROP TABLE ${dialect.quoteIdentifier(table.name)}';

  @override
  bool get isReversible => true;
}

/// Drop a table.
@immutable
class DropTable extends MigrationOperation {
  final String name;
  final bool ifExists;
  final bool cascade;

  const DropTable(this.name, {this.ifExists = false, this.cascade = false});

  @override
  String toSql(SqlDialect dialect) {
    final buffer = StringBuffer('DROP TABLE ');
    if (ifExists) buffer.write('IF EXISTS ');
    buffer.write(dialect.quoteIdentifier(name));
    if (cascade) buffer.write(' CASCADE');
    return buffer.toString();
  }

  @override
  String? toReverseSql(SqlDialect dialect) => null; // Not reversible without schema backup

  @override
  bool get isReversible => false;
}

/// Rename a table.
@immutable
class RenameTable extends MigrationOperation {
  final String oldName;
  final String newName;

  const RenameTable(this.oldName, this.newName);

  @override
  String toSql(SqlDialect dialect) =>
      'ALTER TABLE ${dialect.quoteIdentifier(oldName)} RENAME TO ${dialect.quoteIdentifier(newName)}';

  @override
  String? toReverseSql(SqlDialect dialect) =>
      'ALTER TABLE ${dialect.quoteIdentifier(newName)} RENAME TO ${dialect.quoteIdentifier(oldName)}';

  @override
  bool get isReversible => true;
}

// === Column Operations ===

/// Add a column to an existing table.
@immutable
class AddColumn extends MigrationOperation {
  final String table;
  final ColumnDefinition column;

  const AddColumn(this.table, this.column);

  @override
  String toSql(SqlDialect dialect) {
    final buffer = StringBuffer();

    buffer.write('ALTER TABLE ${dialect.quoteIdentifier(table)} ADD COLUMN ');
    buffer.write(dialect.quoteIdentifier(column.name));
    buffer.write(' ');

    String typeStr = dialect.sqlType(column.type);
    if (column.length != null && column.type == FieldType.varchar) {
      typeStr = 'VARCHAR(${column.length})';
    }
    buffer.write(typeStr);

    if (!column.nullable) {
      buffer.write(' NOT NULL');
    }

    if (column.defaultValue != null) {
      buffer.write(' DEFAULT ${column.defaultValue}');
    }

    return buffer.toString();
  }

  @override
  String? toReverseSql(SqlDialect dialect) =>
      'ALTER TABLE ${dialect.quoteIdentifier(table)} DROP COLUMN ${dialect.quoteIdentifier(column.name)}';

  @override
  bool get isReversible => true;
}

/// Drop a column from a table.
@immutable
class DropColumn extends MigrationOperation {
  final String table;
  final String column;
  final bool cascade;

  const DropColumn(this.table, this.column, {this.cascade = false});

  @override
  String toSql(SqlDialect dialect) {
    final buffer = StringBuffer();
    buffer.write('ALTER TABLE ${dialect.quoteIdentifier(table)} ');
    buffer.write('DROP COLUMN ${dialect.quoteIdentifier(column)}');
    if (cascade) buffer.write(' CASCADE');
    return buffer.toString();
  }

  @override
  String? toReverseSql(SqlDialect dialect) => null;

  @override
  bool get isReversible => false;
}

/// Rename a column.
@immutable
class RenameColumn extends MigrationOperation {
  final String table;
  final String oldName;
  final String newName;

  const RenameColumn(this.table, this.oldName, this.newName);

  @override
  String toSql(SqlDialect dialect) =>
      'ALTER TABLE ${dialect.quoteIdentifier(table)} RENAME COLUMN ${dialect.quoteIdentifier(oldName)} TO ${dialect.quoteIdentifier(newName)}';

  @override
  String? toReverseSql(SqlDialect dialect) =>
      'ALTER TABLE ${dialect.quoteIdentifier(table)} RENAME COLUMN ${dialect.quoteIdentifier(newName)} TO ${dialect.quoteIdentifier(oldName)}';

  @override
  bool get isReversible => true;
}

/// Alter a column (type, nullability, default).
@immutable
class AlterColumn extends MigrationOperation {
  final ColumnModification modification;

  const AlterColumn(this.modification);

  @override
  String toSql(SqlDialect dialect) {
    final statements = <String>[];
    final table = dialect.quoteIdentifier(modification.table);
    final column = dialect.quoteIdentifier(modification.column);

    // Change type
    if (modification.type != null) {
      statements.add('ALTER TABLE $table ALTER COLUMN $column TYPE ${dialect.sqlType(modification.type!)}');
    }

    // Change nullability
    if (modification.nullable != null) {
      if (modification.nullable!) {
        statements.add('ALTER TABLE $table ALTER COLUMN $column DROP NOT NULL');
      } else {
        statements.add('ALTER TABLE $table ALTER COLUMN $column SET NOT NULL');
      }
    }

    // Change default
    if (modification.defaultValue != null) {
      statements.add('ALTER TABLE $table ALTER COLUMN $column SET DEFAULT ${modification.defaultValue}');
    } else if (modification.dropDefault) {
      statements.add('ALTER TABLE $table ALTER COLUMN $column DROP DEFAULT');
    }

    // Rename
    if (modification.rename != null) {
      statements.add('ALTER TABLE $table RENAME COLUMN $column TO ${dialect.quoteIdentifier(modification.rename!)}');
    }

    return statements.join(';\n');
  }

  @override
  String? toReverseSql(SqlDialect dialect) => null;

  @override
  bool get isReversible => false;
}

// === Index Operations ===

/// Create an index.
@immutable
class CreateIndex extends MigrationOperation {
  final String table;
  final IndexDefinition index;
  final bool concurrently;

  const CreateIndex(this.table, this.index, {this.concurrently = false});

  @override
  String toSql(SqlDialect dialect) {
    final buffer = StringBuffer('CREATE ');
    if (index.unique) buffer.write('UNIQUE ');
    buffer.write('INDEX ');
    if (concurrently) buffer.write('CONCURRENTLY ');
    buffer.write(dialect.quoteIdentifier(index.name));
    buffer.write(' ON ${dialect.quoteIdentifier(table)} (');
    buffer.write(index.columns.map((c) => dialect.quoteIdentifier(c)).join(', '));
    buffer.write(')');
    return buffer.toString();
  }

  @override
  String? toReverseSql(SqlDialect dialect) => 'DROP INDEX ${dialect.quoteIdentifier(index.name)}';

  @override
  bool get isReversible => true;
}

/// Drop an index.
@immutable
class DropIndex extends MigrationOperation {
  final String name;
  final bool ifExists;
  final bool concurrently;

  const DropIndex(this.name, {this.ifExists = false, this.concurrently = false});

  @override
  String toSql(SqlDialect dialect) {
    final buffer = StringBuffer('DROP INDEX ');
    if (concurrently) buffer.write('CONCURRENTLY ');
    if (ifExists) buffer.write('IF EXISTS ');
    buffer.write(dialect.quoteIdentifier(name));
    return buffer.toString();
  }

  @override
  String? toReverseSql(SqlDialect dialect) => null;

  @override
  bool get isReversible => false;
}

// === Constraint Operations ===

/// Add a foreign key constraint.
@immutable
class AddForeignKey extends MigrationOperation {
  final String table;
  final ForeignKeyDefinition foreignKey;
  final String? constraintName;

  const AddForeignKey(this.table, this.foreignKey, {this.constraintName});

  @override
  String toSql(SqlDialect dialect) {
    final buffer = StringBuffer();
    buffer.write('ALTER TABLE ${dialect.quoteIdentifier(table)} ADD CONSTRAINT ');
    buffer.write(dialect.quoteIdentifier(constraintName ?? 'fk_${table}_${foreignKey.column}'));
    buffer.write(' FOREIGN KEY (${dialect.quoteIdentifier(foreignKey.column)})');
    buffer.write(' REFERENCES ${dialect.quoteIdentifier(foreignKey.referencedTable)}');
    buffer.write('(${dialect.quoteIdentifier(foreignKey.referencedColumn)})');
    return buffer.toString();
  }

  @override
  String? toReverseSql(SqlDialect dialect) {
    final name = constraintName ?? 'fk_${table}_${foreignKey.column}';
    return 'ALTER TABLE ${dialect.quoteIdentifier(table)} DROP CONSTRAINT ${dialect.quoteIdentifier(name)}';
  }

  @override
  bool get isReversible => true;
}

/// Drop a constraint.
@immutable
class DropConstraint extends MigrationOperation {
  final String table;
  final String constraintName;
  final bool cascade;

  const DropConstraint(this.table, this.constraintName, {this.cascade = false});

  @override
  String toSql(SqlDialect dialect) {
    final buffer = StringBuffer();
    buffer.write('ALTER TABLE ${dialect.quoteIdentifier(table)} ');
    buffer.write('DROP CONSTRAINT ${dialect.quoteIdentifier(constraintName)}');
    if (cascade) buffer.write(' CASCADE');
    return buffer.toString();
  }

  @override
  String? toReverseSql(SqlDialect dialect) => null;

  @override
  bool get isReversible => false;
}

// === Raw SQL Operations ===

/// Execute raw SQL.
@immutable
class RawSql extends MigrationOperation {
  final String sql;
  final String? reverseSql;

  const RawSql(this.sql, {this.reverseSql});

  @override
  String toSql(SqlDialect dialect) => sql;

  @override
  String? toReverseSql(SqlDialect dialect) => reverseSql;

  @override
  bool get isReversible => reverseSql != null;
}

/// Run Dart code (data migration).
@immutable
class RunDart extends MigrationOperation {
  final Future<void> Function(DatabaseConnection conn) forward;
  final Future<void> Function(DatabaseConnection conn)? backward;

  const RunDart(this.forward, {this.backward});

  @override
  String toSql(SqlDialect dialect) => '-- Dart code migration';

  @override
  String? toReverseSql(SqlDialect dialect) => backward != null ? '-- Dart code migration (reverse)' : null;

  @override
  bool get isReversible => backward != null;
}
