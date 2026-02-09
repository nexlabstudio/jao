/// Schema Generator - Auto-generate migrations from model definitions.
///
/// Compares current model definitions to the database schema and
/// generates the necessary migration operations.
library;

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
        if (field.foreignKey != null) {
          builder.foreignKey(
            field.columnName,
            field.foreignKey!.referencedTable,
            referencedColumn: field.foreignKey!.referencedColumn,
            onDelete: field.foreignKey!.onDelete,
            nullable: field.nullable,
          );
        } else {
          builder.integer(
            field.columnName,
            nullable: field.nullable,
            defaultValue: field.defaultValue != null ? int.tryParse(field.defaultValue!) : null,
          );
        }

      case FieldType.real:
        builder.float(
          field.columnName,
          nullable: field.nullable,
          defaultValue: field.defaultValue != null ? double.tryParse(field.defaultValue!) : null,
        );
      case FieldType.doublePrecision:
        builder.doublePrecision(
          field.columnName,
          nullable: field.nullable,
          defaultValue: field.defaultValue != null ? double.tryParse(field.defaultValue!) : null,
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
          defaultValue: field.defaultValue != null ? field.defaultValue!.toLowerCase() == 'true' : null,
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
        // Fallback to text
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
        // Column exists - check for type/nullability changes
        // This is more complex and usually requires careful handling
        // For now, we'll skip auto-detecting type changes
      }
    }

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
    if (op is CreateTable) {
      return _createTableToCode(op, indent);
    } else if (op is DropTable) {
      return "${indent}builder.dropTable('${op.name}');";
    } else if (op is AddColumn) {
      return "${indent}builder.addColumn('${op.table}', '${op.column.name}', FieldType.${op.column.type.name});";
    } else if (op is CreateIndex) {
      final cols = op.index.columns.map((c) => "'$c'").join(', ');
      return "${indent}builder.createIndex('${op.table}', [$cols], unique: ${op.index.unique});";
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
      case FieldType.text:
        return "${indent}table.text('${col.name}'$nullable$defaultVal);";
      case FieldType.integer:
        return "${indent}table.integer('${col.name}'$nullable$defaultVal);";
      case FieldType.boolean:
        return "${indent}table.boolean('${col.name}'$nullable$defaultVal);";
      case FieldType.timestampTz:
        final useCurrent = col.defaultValue == 'CURRENT_TIMESTAMP' ? ', useCurrent: true' : '';
        return "${indent}table.timestampTz('${col.name}'$nullable$useCurrent);";
      default:
        return "$indent// ${col.name}: ${col.type}";
    }
  }

  String? _operationToReverseCode(MigrationOperation op, String indent) {
    if (op is CreateTable) {
      return "${indent}builder.dropTable('${op.table.name}');";
    } else if (op is AddColumn) {
      return "${indent}builder.dropColumn('${op.table}', '${op.column.name}');";
    } else if (op is CreateIndex) {
      return "${indent}builder.dropIndex('${op.index.name}');";
    }
    return null;
  }

  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}')
        .replaceFirst(RegExp(r'^_'), '');
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
