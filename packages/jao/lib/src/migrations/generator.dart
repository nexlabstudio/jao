/// Schema Generator - Auto-generate migrations from model definitions.
///
/// Compares current model definitions to the database schema and
/// generates the necessary migration operations.
library;

import '../db/adapters/sqlite.dart';
import '../db/connection.dart';
import '../fields/field_def.dart';
import 'schema.dart';
import 'operations.dart';

/// Model schema information extracted from annotations.
class ModelSchema {
  final String className;
  final String tableName;
  final List<ModelFieldSchema> fields;
  final List<String>? uniqueTogether;
  final List<String>? indexTogether;

  const ModelSchema({
    required this.className,
    required this.tableName,
    required this.fields,
    this.uniqueTogether,
    this.indexTogether,
  });
}

/// Field schema information.
class ModelFieldSchema {
  final String name;
  final String columnName;
  final FieldType dbType;
  final bool nullable;
  final bool unique;
  final bool index;
  final bool primaryKey;
  final bool autoIncrement;
  final String? defaultValue;
  final int? maxLength;
  final int? precision;
  final int? scale;
  final ForeignKeyInfo? foreignKey;

  /// Automatically set to current timestamp on creation (like Django's auto_now_add)
  final bool autoNowAdd;

  /// Automatically set to current timestamp on every save (like Django's auto_now)
  final bool autoNow;

  const ModelFieldSchema({
    required this.name,
    required this.columnName,
    required this.dbType,
    this.nullable = false,
    this.unique = false,
    this.index = false,
    this.primaryKey = false,
    this.autoIncrement = false,
    this.defaultValue,
    this.maxLength,
    this.precision,
    this.scale,
    this.foreignKey,
    this.autoNowAdd = false,
    this.autoNow = false,
  });
}

/// Foreign key relationship info.
class ForeignKeyInfo {
  final String referencedTable;
  final String referencedColumn;
  final OnDeleteAction onDelete;

  const ForeignKeyInfo({
    required this.referencedTable,
    this.referencedColumn = 'id',
    this.onDelete = OnDeleteAction.cascade,
  });
}

/// Generates migration operations by comparing model schemas to database.
class SchemaGenerator {
  final DatabaseAdapter adapter;

  SchemaGenerator(this.adapter);

  /// Generate operations to create a table from a model schema
  List<MigrationOperation> generateCreateTable(ModelSchema model) {
    final operations = <MigrationOperation>[];

    final tableBuilder = TableBuilder(model.tableName);

    for (final field in model.fields) {
      _addFieldToBuilder(tableBuilder, field);
    }

    // Add unique together constraints
    if (model.uniqueTogether != null) {
      for (var i = 0; i < model.uniqueTogether!.length; i++) {
        final columns = model.uniqueTogether![i].split(',').map((s) => s.trim()).toList();
        tableBuilder.uniqueIndex(columns, name: 'uq_${model.tableName}_$i');
      }
    }

    // Add index together
    if (model.indexTogether != null) {
      for (var i = 0; i < model.indexTogether!.length; i++) {
        final columns = model.indexTogether![i].split(',').map((s) => s.trim()).toList();
        tableBuilder.index(columns, name: 'idx_${model.tableName}_$i');
      }
    }

    operations.add(CreateTable(tableBuilder.build()));

    // Add individual indexes for fields with index=true
    for (final field in model.fields) {
      if (field.index && !field.primaryKey && !field.unique) {
        operations.add(
          CreateIndex(
            model.tableName,
            IndexDefinition(name: 'idx_${model.tableName}_${field.columnName}', columns: [field.columnName]),
          ),
        );
      }
    }

    return operations;
  }

  void _addFieldToBuilder(TableBuilder builder, ModelFieldSchema field) {
    if (field.primaryKey && field.autoIncrement) {
      if (field.dbType == FieldType.bigInt || field.dbType == FieldType.bigSerial) {
        builder.bigId(field.columnName);
      } else {
        builder.id(field.columnName);
      }
      return;
    }

    if (field.primaryKey && field.dbType == FieldType.uuid) {
      builder.uuid(field.columnName);
      return;
    }

    switch (field.dbType) {
      case FieldType.varchar:
        builder.string(
          field.columnName,
          length: field.maxLength ?? 255,
          nullable: field.nullable,
          defaultValue: field.defaultValue,
        );
        if (field.unique) builder.unique(field.columnName);

      case FieldType.text:
        builder.text(field.columnName, nullable: field.nullable, defaultValue: field.defaultValue);

      case FieldType.integer:
      case FieldType.smallInt:
      case FieldType.bigInt:
        if (field.foreignKey case final fk?) {
          builder.foreignKey(
            field.columnName,
            fk.referencedTable,
            referencedColumn: fk.referencedColumn,
            onDelete: fk.onDelete,
            nullable: field.nullable,
          );
        } else {
          builder.integer(
            field.columnName,
            nullable: field.nullable,
            defaultValue: switch (field.defaultValue) {
              final value? => int.tryParse(value),
              _ => null,
            },
          );
        }

      case FieldType.real:
        builder.float(
          field.columnName,
          nullable: field.nullable,
          defaultValue: switch (field.defaultValue) {
            final value? => double.tryParse(value),
            _ => null,
          },
        );
      case FieldType.doublePrecision:
        builder.doublePrecision(
          field.columnName,
          nullable: field.nullable,
          defaultValue: switch (field.defaultValue) {
            final value? => double.tryParse(value),
            _ => null,
          },
        );

      case FieldType.decimal:
        builder.decimal(
          field.columnName,
          precision: field.precision ?? 10,
          scale: field.scale ?? 2,
          nullable: field.nullable,
          defaultValue: field.defaultValue,
        );

      case FieldType.boolean:
        builder.boolean(
          field.columnName,
          nullable: field.nullable,
          defaultValue: switch (field.defaultValue) {
            final value? => value.toLowerCase() == 'true',
            _ => null,
          },
        );

      case FieldType.date:
        builder.date(field.columnName, nullable: field.nullable, defaultValue: field.defaultValue);

      case FieldType.timestamp:
      case FieldType.timestampTz:
        builder.timestampTz(
          field.columnName,
          nullable: field.nullable,
          useCurrent: field.defaultValue == 'CURRENT_TIMESTAMP',
        );

      case FieldType.uuid:
        builder.uuidColumn(field.columnName, nullable: field.nullable, defaultValue: field.defaultValue);

      case FieldType.json:
      case FieldType.jsonb:
        builder.jsonb(field.columnName, nullable: field.nullable, defaultValue: field.defaultValue);

      case FieldType.bytea:
      case FieldType.blob:
        builder.binary(field.columnName, nullable: field.nullable);

      default:
        builder.text(field.columnName, nullable: field.nullable);
    }
  }

  /// Generate operations to migrate from current DB schema to model schema
  Future<List<MigrationOperation>> generateDiff(DatabaseConnection conn, List<ModelSchema> models) async {
    final operations = <MigrationOperation>[];

    // Get existing tables
    final existingTables = await adapter.getTables(conn);

    for (final model in models) {
      if (!existingTables.contains(model.tableName)) {
        // Table doesn't exist - create it
        operations.addAll(generateCreateTable(model));
      } else {
        // Table exists - compare schemas
        final dbSchema = await adapter.getTableSchema(conn, model.tableName);
        operations.addAll(_generateTableDiff(model, dbSchema));
      }
    }

    // TODO(mastersam07): Will consider this later as dropping tables is destructive
    // Check for tables that no longer have models (optional - usually don't auto-drop)
    // for (final tableName in existingTables) {
    //   if (!models.any((m) => m.tableName == tableName)) {
    //     operations.add(DropTable(tableName));
    //   }
    // }

    return operations;
  }

  List<MigrationOperation> _generateTableDiff(ModelSchema model, TableSchema dbSchema) {
    final operations = <MigrationOperation>[];

    // Check for new columns
    for (final field in model.fields) {
      final dbColumn = dbSchema.getColumn(field.columnName);
      if (dbColumn == null) {
        // Column doesn't exist - add it
        operations.add(
          AddColumn(
            model.tableName,
            ColumnDefinition(
              name: field.columnName,
              type: field.dbType,
              nullable: field.nullable,
              defaultValue: field.defaultValue,
              length: field.maxLength,
              precision: field.precision,
              scale: field.scale,
            ),
          ),
        );

        // Add index if needed
        if (field.index) {
          operations.add(
            CreateIndex(
              model.tableName,
              IndexDefinition(name: 'idx_${model.tableName}_${field.columnName}', columns: [field.columnName]),
            ),
          );
        }

        // Add foreign key if needed
        if (field.foreignKey != null) {
          operations.add(
            AddForeignKey(
              model.tableName,
              ForeignKeyDefinition(
                column: field.columnName,
                referencedTable: field.foreignKey!.referencedTable,
                referencedColumn: field.foreignKey!.referencedColumn,
                onDelete: field.foreignKey!.onDelete,
              ),
            ),
          );
        }
      } else {
        // Column exists - check for nullability changes
        // Skip PK fields: SQLite's PRAGMA table_info reports notnull=0 for
        // INTEGER PRIMARY KEY even though PKs are implicitly NOT NULL.
        // PostgreSQL/MySQL report PKs correctly, but this check is harmless there.
        if (!field.primaryKey && !dbColumn.isPrimaryKey && field.nullable != dbColumn.nullable) {
          operations.add(
            AlterColumn(
              ColumnModification(
                table: model.tableName,
                column: field.columnName,
                nullable: field.nullable,
              ),
            ),
          );
        }
        // Check for type changes
        final normalizedDbType = _normalizeDbType(dbColumn.type);
        if (normalizedDbType case final normalizedDbType? when normalizedDbType != field.dbType) {
          // Skip if both are integer-like types for PKs (serial vs integer)
          final isIntegerLike = _isIntegerType(field.dbType) && _isIntegerType(normalizedDbType);
          // Skip if types are equivalent for SQLite (e.g., TEXT ↔ timestamp, varchar ↔ text)
          final isSqliteEquivalent =
              adapter is SqliteAdapter && _areTypesEquivalentForSqlite(field.dbType, normalizedDbType);
          if ((!field.primaryKey && !dbColumn.isPrimaryKey || !isIntegerLike) && !isSqliteEquivalent) {
            operations.add(
              AlterColumn(
                ColumnModification(
                  table: model.tableName,
                  column: field.columnName,
                  type: field.dbType,
                ),
              ),
            );
          }
        }

        // Check for default value changes
        if (_defaultValuesDiffer(field.defaultValue, dbColumn.defaultValue)) {
          if (field.defaultValue case final defaultValue?) {
            operations.add(
              AlterColumn(
                ColumnModification(
                  table: model.tableName,
                  column: field.columnName,
                  defaultValue: defaultValue,
                ),
              ),
            );
          } else {
            operations.add(
              AlterColumn(
                ColumnModification(
                  table: model.tableName,
                  column: field.columnName,
                  dropDefault: true,
                ),
              ),
            );
          }
        }

        // Check for maxLength changes (varchar/char columns)
        if (field.maxLength != null && dbColumn.maxLength != null && field.maxLength != dbColumn.maxLength) {
          operations.add(
            AlterColumn(
              ColumnModification(
                table: model.tableName,
                column: field.columnName,
                type: field.dbType,
              ),
            ),
          );
        }

        // Check for precision/scale changes (decimal columns)
        // Only compare when the DB reports values (SQLite doesn't track precision/scale)
        if (field.precision != null &&
            field.scale != null &&
            dbColumn.precision != null &&
            dbColumn.scale != null &&
            (field.precision != dbColumn.precision || field.scale != dbColumn.scale)) {
          operations.add(
            AlterColumn(
              ColumnModification(
                table: model.tableName,
                column: field.columnName,
                type: field.dbType,
              ),
            ),
          );
        }

        // Check for missing unique constraint
        if (field.unique && !_hasUniqueConstraint(dbSchema, field.columnName)) {
          operations.add(
            CreateIndex(
              model.tableName,
              IndexDefinition(
                name: 'idx_${model.tableName}_${field.columnName}_unique',
                columns: [field.columnName],
                unique: true,
              ),
            ),
          );
        }

        // Check for missing foreign key constraint
        if (field.foreignKey != null && !_hasForeignKeyConstraint(dbSchema, field.columnName)) {
          operations.add(
            AddForeignKey(
              model.tableName,
              ForeignKeyDefinition(
                column: field.columnName,
                referencedTable: field.foreignKey!.referencedTable,
                referencedColumn: field.foreignKey!.referencedColumn,
                onDelete: field.foreignKey!.onDelete,
              ),
            ),
          );
        }
      }
    }

    // TODO(mastersam07): Will consider this later as dropping columns is destructive
    // Check for removed columns (usually don't auto-drop)
    // for (final dbColumn in dbSchema.columns) {
    //   if (!model.fields.any((f) => f.columnName == dbColumn.name)) {
    //     operations.add(DropColumn(model.tableName, dbColumn.name));
    //   }
    // }

    return operations;
  }

  /// Generate a migration file content from operations
  String generateMigrationFile(String name, List<MigrationOperation> operations) {
    final buffer = StringBuffer();

    buffer.writeln("import 'package:jao/jao.dart';");
    buffer.writeln();
    buffer.writeln('class $name extends Migration {');
    buffer.writeln('  @override');
    buffer.writeln("  String get name => '${_toSnakeCase(name)}';");
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  void up(MigrationBuilder builder) {');

    for (final op in operations) {
      buffer.writeln(_operationToCode(op, '    '));
    }

    buffer.writeln('  }');
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  void down(MigrationBuilder builder) {');

    // Generate reverse operations
    for (final op in operations.reversed) {
      final reverseCode = _operationToReverseCode(op, '    ');
      if (reverseCode != null) {
        buffer.writeln(reverseCode);
      }
    }

    buffer.writeln('  }');
    buffer.writeln('}');

    return buffer.toString();
  }

  String _operationToCode(MigrationOperation op, String indent) {
    switch (op) {
      case CreateTable():
        return _createTableToCode(op, indent);
      case DropTable():
        return "${indent}builder.dropTable('${op.name}');";
      case RenameTable():
        return "${indent}builder.renameTable('${op.oldName}', '${op.newName}');";
      case AddColumn():
        return "${indent}builder.addColumn('${op.table}', '${op.column.name}', FieldType.${op.column.type.name});";
      case DropColumn():
        return "${indent}builder.dropColumn('${op.table}', '${op.column}');";
      case RenameColumn():
        return "${indent}builder.renameColumn('${op.table}', '${op.oldName}', '${op.newName}');";
      case AlterColumn():
        return _alterColumnToCode(op, indent);
      case CreateIndex():
        final cols = op.index.columns.map((c) => "'$c'").join(', ');
        return "${indent}builder.createIndex('${op.table}', [$cols], unique: ${op.index.unique});";
      case DropIndex():
        return "${indent}builder.dropIndex('${op.name}');";
      case AddForeignKey():
        return "${indent}builder.addForeignKey('${op.table}', '${op.foreignKey.column}', '${op.foreignKey.referencedTable}', referencedColumn: '${op.foreignKey.referencedColumn}');";
      case DropConstraint():
        return "${indent}builder.dropConstraint('${op.table}', '${op.constraintName}');";
      case RawSql():
        return "${indent}builder.raw('${op.sql.replaceAll("'", "\\'")}');";
      case RunDart():
        return '$indent// RunDart operation - implement manually';
    }
    return '$indent// Unsupported operation: ${op.runtimeType}';
  }

  String _createTableToCode(CreateTable op, String indent) {
    final buffer = StringBuffer();
    buffer.writeln("${indent}builder.createTable('${op.table.name}', (table) {");

    for (final col in op.table.columns) {
      buffer.writeln(_columnToCode(col, '$indent  '));
    }

    buffer.write('$indent});');
    return buffer.toString();
  }

  String _alterColumnToCode(AlterColumn op, String indent) {
    final mod = op.modification;
    final modifications = <String>[];

    if (mod.nullable case final nullable?) {
      modifications.add(nullable ? 'col.nullable()' : 'col.notNullable()');
    }
    if (mod.type case final type?) {
      modifications.add('col.type(FieldType.${type.name})');
    }
    if (mod.defaultValue case final defaultValue?) {
      modifications.add("col.defaultValue('${defaultValue}')");
    }
    if (mod.dropDefault) {
      modifications.add('col.dropDefault()');
    }
    if (mod.rename case final rename?) {
      modifications.add("col.renameTo('${rename}')");
    }

    final buffer = StringBuffer();
    buffer.writeln("${indent}builder.alterColumn('${mod.table}', '${mod.column}', (col) {");
    for (final m in modifications) {
      buffer.writeln('$indent  $m;');
    }
    buffer.write('$indent});');
    return buffer.toString();
  }

  String _columnToCode(ColumnDefinition col, String indent) {
    final nullable = col.nullable ? ', nullable: true' : '';
    final defaultVal = col.defaultValue != null ? ", defaultValue: '${col.defaultValue}'" : '';

    switch (col.type) {
      case FieldType.serial:
        return "${indent}table.id('${col.name}');";
      case FieldType.bigSerial:
        return "${indent}table.bigId('${col.name}');";
      case FieldType.varchar:
        return "${indent}table.string('${col.name}', length: ${col.length ?? 255}$nullable$defaultVal);";
      case FieldType.char:
        return "${indent}table.char('${col.name}', length: ${col.length ?? 1}$nullable$defaultVal);";
      case FieldType.text:
        return "${indent}table.text('${col.name}'$nullable$defaultVal);";
      case FieldType.smallInt:
        return "${indent}table.smallInteger('${col.name}'$nullable$defaultVal);";
      case FieldType.integer:
        return "${indent}table.integer('${col.name}'$nullable$defaultVal);";
      case FieldType.bigInt:
        return "${indent}table.bigInteger('${col.name}'$nullable$defaultVal);";
      case FieldType.real:
        return "${indent}table.float('${col.name}'$nullable$defaultVal);";
      case FieldType.doublePrecision:
        return "${indent}table.doublePrecision('${col.name}'$nullable$defaultVal);";
      case FieldType.decimal:
        final precision = col.precision ?? 10;
        final scale = col.scale ?? 2;
        return "${indent}table.decimal('${col.name}', precision: $precision, scale: $scale$nullable$defaultVal);";
      case FieldType.boolean:
        return "${indent}table.boolean('${col.name}'$nullable$defaultVal);";
      case FieldType.date:
        return "${indent}table.date('${col.name}'$nullable$defaultVal);";
      case FieldType.time:
        return "${indent}table.time('${col.name}'$nullable$defaultVal);";
      case FieldType.timestamp:
        final useCurrent = col.defaultValue == 'CURRENT_TIMESTAMP' ? ', useCurrent: true' : '';
        return "${indent}table.timestamp('${col.name}'$nullable$useCurrent);";
      case FieldType.timestampTz:
        final useCurrent = col.defaultValue == 'CURRENT_TIMESTAMP' ? ', useCurrent: true' : '';
        return "${indent}table.timestampTz('${col.name}'$nullable$useCurrent);";
      case FieldType.interval:
        return "${indent}table.text('${col.name}'$nullable$defaultVal);";
      case FieldType.uuid:
        if (col.primaryKey) {
          return "${indent}table.uuid('${col.name}');";
        }
        return "${indent}table.uuidColumn('${col.name}'$nullable$defaultVal);";
      case FieldType.json:
        return "${indent}table.json('${col.name}'$nullable$defaultVal);";
      case FieldType.jsonb:
        return "${indent}table.jsonb('${col.name}'$nullable$defaultVal);";
      case FieldType.bytea:
      case FieldType.blob:
        return "${indent}table.binary('${col.name}'$nullable);";
      case FieldType.array:
        return "${indent}table.text('${col.name}'$nullable$defaultVal);";
    }
  }

  String? _operationToReverseCode(MigrationOperation op, String indent) {
    switch (op) {
      case CreateTable():
        return "${indent}builder.dropTable('${op.table.name}');";
      case DropTable():
        return '$indent// TODO: Cannot reverse DropTable - table definition lost';
      case RenameTable():
        return "${indent}builder.renameTable('${op.newName}', '${op.oldName}');";
      case AddColumn():
        return "${indent}builder.dropColumn('${op.table}', '${op.column.name}');";
      case DropColumn():
        return '$indent// TODO: Cannot reverse DropColumn - column definition lost';
      case RenameColumn():
        return "${indent}builder.renameColumn('${op.table}', '${op.newName}', '${op.oldName}');";
      case AlterColumn():
        final mod = op.modification;
        if (mod.nullable case final nullable?) {
          final reverseNullable = !nullable;
          final reverseMethod = reverseNullable ? 'col.nullable()' : 'col.notNullable()';
          return "${indent}builder.alterColumn('${mod.table}', '${mod.column}', (col) {\n$indent  $reverseMethod;\n$indent});";
        }
        return '$indent// TODO: Manual reversal needed for AlterColumn';
      case CreateIndex():
        return "${indent}builder.dropIndex('${op.index.name}');";
      case DropIndex():
        return '$indent// TODO: Cannot reverse DropIndex - index definition lost';
      case AddForeignKey():
        return "${indent}builder.dropConstraint('${op.table}', 'fk_${op.table}_${op.foreignKey.column}');";
      case DropConstraint():
        return '$indent// TODO: Cannot reverse DropConstraint - constraint definition lost';
      case RawSql():
        if (op.reverseSql case final reverseSql?) {
          return "${indent}builder.raw('${reverseSql.replaceAll("'", "\\'")}');";
        }
        return '$indent// TODO: No reverse SQL provided for RawSql';
      case RunDart():
        return '$indent// TODO: Cannot reverse RunDart operation';
    }
    return null;
  }

  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}')
        .replaceFirst(RegExp(r'^_'), '');
  }

  /// Normalize a raw database type string to a FieldType.
  ///
  /// Each database reports types differently:
  /// - SQLite: "TEXT", "INTEGER", "REAL", "BLOB"
  /// - PostgreSQL: "character varying", "integer", "bigint", "text", "boolean", etc.
  /// - MySQL: "varchar", "int", "bigint", "text", "tinyint", etc.
  ///
  /// Returns null if the type cannot be normalized (unknown type).
  FieldType? _normalizeDbType(String rawType) {
    final type = rawType.toUpperCase().trim();

    // Handle types with parameters like VARCHAR(255), DECIMAL(10,2)
    final baseType = type.replaceAll(RegExp(r'\([^)]*\)'), '').trim();

    return switch (baseType) {
      // Integer types
      'INTEGER' || 'INT' || 'INT4' || 'MEDIUMINT' => FieldType.integer,
      'SMALLINT' || 'INT2' || 'TINYINT' => FieldType.smallInt,
      'BIGINT' || 'INT8' => FieldType.bigInt,
      'SERIAL' || 'SERIAL4' => FieldType.serial,
      'BIGSERIAL' || 'SERIAL8' => FieldType.bigSerial,

      // Floating point types
      'REAL' || 'FLOAT' || 'FLOAT4' => FieldType.real,
      'DOUBLE PRECISION' || 'FLOAT8' || 'DOUBLE' => FieldType.doublePrecision,
      'DECIMAL' || 'NUMERIC' || 'DEC' => FieldType.decimal,

      // String types
      'VARCHAR' || 'CHARACTER VARYING' || 'NVARCHAR' => FieldType.varchar,
      'TEXT' || 'LONGTEXT' || 'MEDIUMTEXT' || 'TINYTEXT' => FieldType.text,
      'CHAR' || 'CHARACTER' || 'NCHAR' => FieldType.char,

      // Binary types
      'BYTEA' || 'BLOB' || 'BINARY' || 'VARBINARY' || 'LONGBLOB' || 'MEDIUMBLOB' || 'TINYBLOB' => FieldType.bytea,

      // Date/Time types
      'DATE' => FieldType.date,
      'TIME' || 'TIME WITHOUT TIME ZONE' => FieldType.time,
      'TIMESTAMP' || 'DATETIME' || 'TIMESTAMP WITHOUT TIME ZONE' => FieldType.timestamp,
      'TIMESTAMPTZ' || 'TIMESTAMP WITH TIME ZONE' => FieldType.timestampTz,
      'INTERVAL' => FieldType.interval,

      // Boolean type
      'BOOLEAN' || 'BOOL' => FieldType.boolean,

      // UUID type
      'UUID' => FieldType.uuid,

      // JSON types
      'JSON' => FieldType.json,
      'JSONB' => FieldType.jsonb,

      // Unknown type
      _ => null,
    };
  }

  /// Check if a FieldType is an integer-like type.
  ///
  /// Used to avoid false positives when comparing serial vs integer for PKs.
  /// Compare default values, normalizing DB-reported values against model values.
  bool _defaultValuesDiffer(String? modelDefault, String? dbDefault) {
    if (modelDefault == null && dbDefault == null) return false;
    if (modelDefault == null || dbDefault == null) return true;

    // Normalize: DB may wrap strings in quotes, append type casts, etc.
    final normalizedModel = _normalizeDefaultValue(modelDefault);
    final normalizedDb = _normalizeDefaultValue(dbDefault);
    return normalizedModel != normalizedDb;
  }

  /// Normalize a default value for comparison.
  String _normalizeDefaultValue(String value) {
    var v = value.trim();
    // Remove Postgres type casts like ::text, ::integer, ::boolean
    v = v.replaceAll(RegExp(r'::\w+(\[\])?'), '');
    if (v.startsWith("'") && v.endsWith("'")) {
      v = v.substring(1, v.length - 1);
    }
    return v.toLowerCase();
  }

  bool _hasUniqueConstraint(TableSchema dbSchema, String columnName) {
    // Check constraints
    for (final constraint in dbSchema.constraints) {
      if (constraint.type == ConstraintType.unique && constraint.columns.contains(columnName)) {
        return true;
      }
    }
    for (final index in dbSchema.indexes) {
      if (index.unique && index.columns.contains(columnName)) {
        return true;
      }
    }
    return false;
  }

  bool _hasForeignKeyConstraint(TableSchema dbSchema, String columnName) {
    for (final constraint in dbSchema.constraints) {
      if (constraint.type == ConstraintType.foreignKey && constraint.columns.contains(columnName)) {
        return true;
      }
    }
    return false;
  }

  bool _isIntegerType(FieldType type) {
    return type == FieldType.integer ||
        type == FieldType.smallInt ||
        type == FieldType.bigInt ||
        type == FieldType.serial ||
        type == FieldType.bigSerial;
  }

  /// Check if two FieldTypes are equivalent for SQLite.
  ///
  /// SQLite has limited type affinity - it stores many types as TEXT or INTEGER.
  /// This method returns true if two types are effectively the same in SQLite,
  /// preventing false positive type change detection.
  ///
  /// Type affinities in SQLite:
  /// - TEXT: varchar, text, char, timestamp, timestampTz, date, time, uuid, json, jsonb
  /// - INTEGER: integer, smallInt, bigInt, serial, bigSerial, boolean
  /// - REAL: real, doublePrecision, decimal
  /// - BLOB: bytea, blob
  bool _areTypesEquivalentForSqlite(FieldType modelType, FieldType dbType) {
    // TEXT affinity types - SQLite stores all of these as TEXT
    const textTypes = {
      FieldType.text,
      FieldType.varchar,
      FieldType.char,
      FieldType.timestamp,
      FieldType.timestampTz,
      FieldType.date,
      FieldType.time,
      FieldType.uuid,
      FieldType.json,
      FieldType.jsonb,
      FieldType.interval,
    };

    // INTEGER affinity types
    const integerTypes = {
      FieldType.integer,
      FieldType.smallInt,
      FieldType.bigInt,
      FieldType.serial,
      FieldType.bigSerial,
      FieldType.boolean,
    };

    // REAL affinity types
    const realTypes = {
      FieldType.real,
      FieldType.doublePrecision,
      FieldType.decimal,
    };

    // BLOB affinity types
    const blobTypes = {
      FieldType.bytea,
      FieldType.blob,
    };

    // Check if both types belong to the same affinity group
    if (textTypes.contains(modelType) && textTypes.contains(dbType)) return true;
    if (integerTypes.contains(modelType) && integerTypes.contains(dbType)) return true;
    if (realTypes.contains(modelType) && realTypes.contains(dbType)) return true;
    if (blobTypes.contains(modelType) && blobTypes.contains(dbType)) return true;

    return false;
  }
}

/// Convert a jao field annotation to database FieldType
FieldType fieldDefToDbType(Field field) => switch (field) {
      AutoField() => FieldType.serial,
      BigAutoField() => FieldType.bigSerial,
      EmailField() => FieldType.varchar,
      UrlField() => FieldType.varchar,
      CharField() => FieldType.varchar,
      TextField() => FieldType.text,
      SmallIntegerField() => FieldType.smallInt,
      BigIntegerField() => FieldType.bigInt,
      PositiveIntegerField() => FieldType.integer,
      IntegerField() => FieldType.integer,
      FloatField() => FieldType.real,
      DecimalField() => FieldType.decimal,
      BooleanField() => FieldType.boolean,
      DateField() => FieldType.date,
      DateTimeField() => FieldType.timestampTz,
      TimeField() => FieldType.time,
      DurationField() => FieldType.interval,
      BinaryField() => FieldType.bytea,
      UuidField() => FieldType.uuid,
      JsonField() => FieldType.jsonb,
      EnumField(storeAsInt: true) => FieldType.integer,
      EnumField() => FieldType.varchar,
      OneToOneField() => FieldType.integer,
      ForeignKey() => FieldType.integer,
      _ => FieldType.text,
    };
