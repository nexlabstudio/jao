import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:dartonic/dartonic.dart';

/// Generator for dartonic models.
///
/// For each class annotated with @Model(), generates:
/// - A `$ClassName` class with typed field accessors
/// - Extension with `$` getter and `objects` manager
class DartonicGenerator extends GeneratorForAnnotation<Model> {
  @override
  String generateForAnnotatedElement(Element element, ConstantReader annotation, BuildStep buildStep) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError('@Model() can only be applied to classes.', element: element);
    }

    final classElement = element;
    final className = classElement.name;
    final fields = _extractFields(classElement);

    // Generate the table name
    final tableName = annotation.peek('tableName')?.stringValue ?? _toSnakeCase(className);

    final buffer = StringBuffer();

    // Generate the fields class
    buffer.writeln(_generateFieldsClass(className, fields));
    buffer.writeln();

    // Generate the extension with $ and objects
    buffer.writeln(_generateExtension(className, tableName, fields));

    return buffer.toString();
  }

  /// Extract field information from the class
  List<_FieldInfo> _extractFields(ClassElement classElement) {
    final fields = <_FieldInfo>[];

    for (final field in classElement.fields) {
      if (field.isStatic || field.isSynthetic) continue;

      final fieldAnnotation = _getFieldAnnotation(field);
      if (fieldAnnotation != null) {
        final nullable = field.type.nullabilitySuffix != NullabilitySuffix.none;
        fields.add(
          _FieldInfo(
            name: field.name,
            dartType: field.type,
            fieldType: fieldAnnotation.fieldType,
            dbType: fieldAnnotation.dbType,
            annotation: fieldAnnotation.annotation,
            nullable: nullable,
            primaryKey: fieldAnnotation.primaryKey,
            autoIncrement: fieldAnnotation.autoIncrement,
            autoNowAdd: fieldAnnotation.autoNowAdd,
            autoNow: fieldAnnotation.autoNow,
          ),
        );
      } else {
        // Infer field type from Dart type
        final inferred = _inferFieldType(field);
        if (inferred != null) {
          fields.add(inferred);
        }
      }
    }

    return fields;
  }

  /// Get the field annotation if present
  _FieldAnnotationInfo? _getFieldAnnotation(FieldElement field) {
    for (final annotation in field.metadata) {
      final value = annotation.computeConstantValue();
      if (value == null) continue;

      final type = value.type;
      if (type == null) continue;

      final typeName = type.getDisplayString(withNullability: false);

      // Check for known field types
      switch (typeName) {
        case 'CharField':
          return _FieldAnnotationInfo('String', 'StringFieldRef', 'varchar', annotation.toSource());
        case 'TextField':
          return _FieldAnnotationInfo('String', 'StringFieldRef', 'text', annotation.toSource());
        case 'EmailField':
          return _FieldAnnotationInfo('String', 'StringFieldRef', 'varchar', annotation.toSource());
        case 'UrlField':
          return _FieldAnnotationInfo('String', 'StringFieldRef', 'varchar', annotation.toSource());
        case 'IntegerField':
          return _FieldAnnotationInfo('int', 'IntFieldRef', 'integer', annotation.toSource());
        case 'SmallIntegerField':
          return _FieldAnnotationInfo('int', 'IntFieldRef', 'smallInt', annotation.toSource());
        case 'BigIntegerField':
          return _FieldAnnotationInfo('int', 'IntFieldRef', 'bigInt', annotation.toSource());
        case 'PositiveIntegerField':
          return _FieldAnnotationInfo('int', 'IntFieldRef', 'integer', annotation.toSource());
        case 'AutoField':
          return _FieldAnnotationInfo('int', 'IntFieldRef', 'serial', annotation.toSource(), primaryKey: true, autoIncrement: true);
        case 'BigAutoField':
          return _FieldAnnotationInfo('int', 'IntFieldRef', 'bigSerial', annotation.toSource(), primaryKey: true, autoIncrement: true);
        case 'FloatField':
          return _FieldAnnotationInfo('double', 'DoubleFieldRef', 'real', annotation.toSource());
        case 'DecimalField':
          return _FieldAnnotationInfo('double', 'DoubleFieldRef', 'decimal', annotation.toSource());
        case 'BooleanField':
          return _FieldAnnotationInfo('bool', 'BoolFieldRef', 'boolean', annotation.toSource());
        case 'DateField':
          return _FieldAnnotationInfo('DateTime', 'DateTimeFieldRef', 'date', annotation.toSource());
        case 'DateTimeField':
          final autoNowAdd = value.getField('autoNowAdd')?.toBoolValue() ?? false;
          final autoNow = value.getField('autoNow')?.toBoolValue() ?? false;
          return _FieldAnnotationInfo(
            'DateTime',
            'DateTimeFieldRef',
            'timestampTz',
            annotation.toSource(),
            autoNowAdd: autoNowAdd,
            autoNow: autoNow,
          );
        case 'DurationField':
          return _FieldAnnotationInfo('Duration', 'DurationFieldRef', 'interval', annotation.toSource());
        case 'ForeignKey':
        case 'OneToOneField':
          return _FieldAnnotationInfo('int', 'IntFieldRef', 'integer', annotation.toSource());
        case 'UuidField':
          return _FieldAnnotationInfo('String', 'StringFieldRef', 'uuid', annotation.toSource());
        case 'JsonField':
          return _FieldAnnotationInfo('dynamic', 'FieldRef', 'jsonb', annotation.toSource());
        case 'BinaryField':
          return _FieldAnnotationInfo('List<int>', 'FieldRef', 'bytea', annotation.toSource());
        case 'TimeField':
          return _FieldAnnotationInfo('Duration', 'DurationFieldRef', 'time', annotation.toSource());
      }
    }
    return null;
  }

  /// Infer field type from Dart type when no annotation present
  _FieldInfo? _inferFieldType(FieldElement field) {
    final type = field.type;
    final typeName = type.getDisplayString(withNullability: false);
    final nullable = type.nullabilitySuffix != NullabilitySuffix.none;

    switch (typeName) {
      case 'String':
        return _FieldInfo(name: field.name, dartType: type, fieldType: 'StringFieldRef', dbType: 'varchar', nullable: nullable);
      case 'int':
        // Check if field is named 'id' - likely a primary key
        final isPk = field.name == 'id';
        return _FieldInfo(name: field.name, dartType: type, fieldType: 'IntFieldRef', dbType: isPk ? 'serial' : 'integer', nullable: nullable, primaryKey: isPk, autoIncrement: isPk);
      case 'double':
        return _FieldInfo(name: field.name, dartType: type, fieldType: 'DoubleFieldRef', dbType: 'doublePrecision', nullable: nullable);
      case 'bool':
        return _FieldInfo(name: field.name, dartType: type, fieldType: 'BoolFieldRef', dbType: 'boolean', nullable: nullable);
      case 'DateTime':
        return _FieldInfo(name: field.name, dartType: type, fieldType: 'DateTimeFieldRef', dbType: 'timestampTz', nullable: nullable);
      case 'Duration':
        return _FieldInfo(name: field.name, dartType: type, fieldType: 'DurationFieldRef', dbType: 'interval', nullable: nullable);
      default:
        // Skip unknown types
        return null;
    }
  }

  /// Generate the fields accessor class
  String _generateFieldsClass(String className, List<_FieldInfo> fields) {
    final buffer = StringBuffer();

    buffer.writeln('/// Typed field accessors for [$className].');
    buffer.writeln('///');
    buffer.writeln('/// Use these for type-safe queries:');
    buffer.writeln('/// ```dart');
    buffer.writeln('/// $className.objects.filter($className.\$.fieldName.eq(value));');
    buffer.writeln('/// ```');
    buffer.writeln('class ${className}\$ implements ModelFields<$className> {');
    buffer.writeln('  const ${className}\$();');
    buffer.writeln();

    for (final field in fields) {
      final columnName = _toSnakeCase(field.name);
      buffer.writeln('  /// Field accessor for [${field.name}]');
      buffer.writeln('  final ${field.name} = const ${field.fieldType}(\'$columnName\');');
      buffer.writeln();
    }

    buffer.writeln('}');

    return buffer.toString();
  }

  /// Generate the extension with static accessors
  String _generateExtension(String className, String tableName, List<_FieldInfo> fields) {
    final buffer = StringBuffer();

    // Find the primary key field
    final pkField = fields.firstWhere(
      (f) =>
          f.annotation?.contains('AutoField') == true ||
          f.annotation?.contains('BigAutoField') == true ||
          f.annotation?.contains('UuidPrimaryKey') == true ||
          f.primaryKey,
      orElse: () => fields.firstWhere((f) => f.name == 'id', orElse: () => fields.first),
    );

    // Collect autoNow fields
    final autoNowAddFields = fields.where((f) => f.autoNowAdd).map((f) => _toSnakeCase(f.name)).toList();
    final autoNowFields = fields.where((f) => f.autoNow).map((f) => _toSnakeCase(f.name)).toList();

    buffer.writeln('/// Extension providing static accessors for [$className].');
    buffer.writeln('extension ${className}Dartonic on $className {');
    buffer.writeln('  /// Typed field accessors for queries.');
    buffer.writeln('  static const \$ = ${className}\$();');
    buffer.writeln();
    buffer.writeln('  static bool _registered = false;');
    buffer.writeln('  static final Manager<$className> _objects = Manager<$className>();');
    buffer.writeln();
    buffer.writeln('  /// Default manager for database operations.');
    buffer.writeln('  static Manager<$className> get objects {');
    buffer.writeln('    if (!_registered) {');
    buffer.writeln('      _registered = true;');
    buffer.writeln('      Dartonic.registerModel<$className>(ModelRegistration(');
    buffer.writeln('        tableName: tableName,');
    buffer.writeln('        pkField: pkField,');
    buffer.writeln('        fromRow: fromRow,');
    buffer.writeln('        toRow: (m) => m.toRow(),');
    if (autoNowAddFields.isNotEmpty) {
      buffer.writeln("        autoNowAddFields: [${autoNowAddFields.map((f) => "'$f'").join(', ')}],");
    }
    if (autoNowFields.isNotEmpty) {
      buffer.writeln("        autoNowFields: [${autoNowFields.map((f) => "'$f'").join(', ')}],");
    }
    buffer.writeln('      ));');
    buffer.writeln('    }');
    buffer.writeln('    return _objects;');
    buffer.writeln('  }');
    buffer.writeln();
    buffer.writeln('  /// Database table name.');
    buffer.writeln('  static const tableName = \'$tableName\';');
    buffer.writeln();
    buffer.writeln('  /// Primary key field name.');
    buffer.writeln('  static const pkField = \'${pkField.name}\';');
    buffer.writeln();
    buffer.writeln('  /// List of all field names.');
    buffer.writeln('  static const fieldNames = [');
    for (final field in fields) {
      buffer.writeln('    \'${field.name}\',');
    }
    buffer.writeln('  ];');
    buffer.writeln();

    // Generate fromRow factory
    buffer.writeln('  /// Create instance from database row.');
    buffer.writeln('  static $className fromRow(Map<String, dynamic> row) {');
    buffer.writeln('    return $className()');
    for (var i = 0; i < fields.length; i++) {
      final field = fields[i];
      final columnName = _toSnakeCase(field.name);
      final suffix = i == fields.length - 1 ? ';' : '';
      buffer.writeln('      ..${field.name} = ${_generateFromRowField(field, columnName)}$suffix');
    }
    buffer.writeln('  }');
    buffer.writeln();

    // Generate toRow method
    buffer.writeln('  /// Convert instance to database row.');
    buffer.writeln('  Map<String, dynamic> toRow() {');
    buffer.writeln('    return {');
    for (final field in fields) {
      final columnName = _toSnakeCase(field.name);
      buffer.writeln('      \'$columnName\': ${_generateToRowField(field)},');
    }
    buffer.writeln('    };');
    buffer.writeln('  }');
    buffer.writeln();

    // Generate ModelSchema for migrations
    buffer.writeln('  /// Model schema for migrations.');
    buffer.writeln('  static final schema = ModelSchema(');
    buffer.writeln('    className: \'$className\',');
    buffer.writeln('    tableName: \'$tableName\',');
    buffer.writeln('    fields: [');
    for (final field in fields) {
      final columnName = _toSnakeCase(field.name);
      buffer.writeln('      ModelFieldSchema(');
      buffer.writeln('        name: \'${field.name}\',');
      buffer.writeln('        columnName: \'$columnName\',');
      buffer.writeln('        dbType: FieldType.${field.dbType},');
      buffer.writeln('        nullable: ${field.nullable},');
      buffer.writeln('        primaryKey: ${field.primaryKey},');
      buffer.writeln('        autoIncrement: ${field.autoIncrement},');
      buffer.writeln('        autoNowAdd: ${field.autoNowAdd},');
      buffer.writeln('        autoNow: ${field.autoNow},');
      buffer.writeln('      ),');
    }
    buffer.writeln('    ],');
    buffer.writeln('  );');
    buffer.writeln('}');

    return buffer.toString();
  }

  /// Convert PascalCase or camelCase to snake_case
  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}')
        .replaceFirst(RegExp(r'^_'), '');
  }

  /// Generate code to read a field from a database row
  String _generateFromRowField(_FieldInfo field, String columnName) {
    final dartTypeName = field.dartType.getDisplayString(withNullability: false);
    final isNullable = field.nullable;

    // Handle DateTime conversion
    if (dartTypeName == 'DateTime') {
      if (isNullable) {
        return "row['$columnName'] == null ? null : DateTime.parse(row['$columnName'] as String)";
      }
      return "DateTime.parse(row['$columnName'] as String)";
    }

    // Handle Duration conversion
    if (dartTypeName == 'Duration') {
      if (isNullable) {
        return "row['$columnName'] == null ? null : Duration(microseconds: row['$columnName'] as int)";
      }
      return "Duration(microseconds: row['$columnName'] as int)";
    }

    // Handle bool conversion (SQLite stores as int)
    if (dartTypeName == 'bool') {
      if (isNullable) {
        return "row['$columnName'] == null ? null : (row['$columnName'] == 1 || row['$columnName'] == true)";
      }
      return "row['$columnName'] == 1 || row['$columnName'] == true";
    }

    // Simple types - just cast
    if (isNullable) {
      return "row['$columnName'] as $dartTypeName?";
    }
    return "row['$columnName'] as $dartTypeName";
  }

  /// Generate code to write a field to a database row
  String _generateToRowField(_FieldInfo field) {
    final dartTypeName = field.dartType.getDisplayString(withNullability: false);

    // Handle DateTime - convert to ISO string
    if (dartTypeName == 'DateTime') {
      if (field.nullable) {
        return '${field.name}?.toIso8601String()';
      }
      return '${field.name}.toIso8601String()';
    }

    // Handle Duration - convert to microseconds
    if (dartTypeName == 'Duration') {
      if (field.nullable) {
        return '${field.name}?.inMicroseconds';
      }
      return '${field.name}.inMicroseconds';
    }

    // Simple types - just use as-is
    return field.name;
  }
}

class _FieldInfo {
  final String name;
  final DartType dartType;
  final String fieldType;
  final String dbType; // FieldType enum name (e.g., 'varchar', 'integer')
  final String? annotation;
  final bool nullable;
  final bool primaryKey;
  final bool autoIncrement;
  final bool autoNowAdd;
  final bool autoNow;

  _FieldInfo({
    required this.name,
    required this.dartType,
    required this.fieldType,
    required this.dbType,
    this.annotation,
    this.nullable = false,
    this.primaryKey = false,
    this.autoIncrement = false,
    this.autoNowAdd = false,
    this.autoNow = false,
  });
}

class _FieldAnnotationInfo {
  final String type;
  final String fieldType;
  final String dbType; // FieldType enum name
  final String annotation;
  final bool primaryKey;
  final bool autoIncrement;
  final bool autoNowAdd;
  final bool autoNow;

  _FieldAnnotationInfo(
    this.type,
    this.fieldType,
    this.dbType,
    this.annotation, {
    this.primaryKey = false,
    this.autoIncrement = false,
    this.autoNowAdd = false,
    this.autoNow = false,
  });
}
