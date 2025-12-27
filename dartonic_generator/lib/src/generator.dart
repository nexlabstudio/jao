import 'package:analyzer/dart/element/element.dart';
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
        fields.add(
          _FieldInfo(
            name: field.name,
            dartType: field.type,
            fieldType: fieldAnnotation.type,
            annotation: fieldAnnotation.annotation,
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
          return _FieldAnnotationInfo('String', 'StringFieldRef', annotation.toSource());
        case 'TextField':
          return _FieldAnnotationInfo('String', 'StringFieldRef', annotation.toSource());
        case 'EmailField':
          return _FieldAnnotationInfo('String', 'StringFieldRef', annotation.toSource());
        case 'UrlField':
          return _FieldAnnotationInfo('String', 'StringFieldRef', annotation.toSource());
        case 'IntegerField':
        case 'SmallIntegerField':
        case 'BigIntegerField':
        case 'PositiveIntegerField':
        case 'AutoField':
        case 'BigAutoField':
          return _FieldAnnotationInfo('int', 'IntFieldRef', annotation.toSource());
        case 'FloatField':
        case 'DecimalField':
          return _FieldAnnotationInfo('double', 'DoubleFieldRef', annotation.toSource());
        case 'BooleanField':
          return _FieldAnnotationInfo('bool', 'BoolFieldRef', annotation.toSource());
        case 'DateField':
        case 'DateTimeField':
          return _FieldAnnotationInfo('DateTime', 'DateTimeFieldRef', annotation.toSource());
        case 'DurationField':
          return _FieldAnnotationInfo('Duration', 'DurationFieldRef', annotation.toSource());
        case 'ForeignKey':
        case 'OneToOneField':
          // ForeignKey fields are typically int references to another table
          return _FieldAnnotationInfo('int', 'IntFieldRef', annotation.toSource());
        case 'UuidField':
          return _FieldAnnotationInfo('String', 'StringFieldRef', annotation.toSource());
        case 'JsonField':
          return _FieldAnnotationInfo('dynamic', 'FieldRef', annotation.toSource());
        case 'BinaryField':
          return _FieldAnnotationInfo('List<int>', 'FieldRef', annotation.toSource());
        case 'TimeField':
          return _FieldAnnotationInfo('Duration', 'DurationFieldRef', annotation.toSource());
      }
    }
    return null;
  }

  /// Infer field type from Dart type when no annotation present
  _FieldInfo? _inferFieldType(FieldElement field) {
    final type = field.type;
    final typeName = type.getDisplayString(withNullability: false);

    switch (typeName) {
      case 'String':
        return _FieldInfo(name: field.name, dartType: type, fieldType: 'StringFieldRef', annotation: null);
      case 'int':
        return _FieldInfo(name: field.name, dartType: type, fieldType: 'IntFieldRef', annotation: null);
      case 'double':
        return _FieldInfo(name: field.name, dartType: type, fieldType: 'DoubleFieldRef', annotation: null);
      case 'bool':
        return _FieldInfo(name: field.name, dartType: type, fieldType: 'BoolFieldRef', annotation: null);
      case 'DateTime':
        return _FieldInfo(name: field.name, dartType: type, fieldType: 'DateTimeFieldRef', annotation: null);
      case 'Duration':
        return _FieldInfo(name: field.name, dartType: type, fieldType: 'DurationFieldRef', annotation: null);
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
          f.annotation?.contains('UuidPrimaryKey') == true,
      orElse: () => fields.firstWhere((f) => f.name == 'id', orElse: () => fields.first),
    );

    buffer.writeln('/// Extension providing static accessors for [$className].');
    buffer.writeln('extension ${className}Dartonic on $className {');
    buffer.writeln('  /// Typed field accessors for queries.');
    buffer.writeln('  static const \$ = ${className}\$();');
    buffer.writeln();
    buffer.writeln('  /// Default manager for database operations.');
    buffer.writeln('  static final objects = Manager<$className>();');
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
    buffer.writeln('}');

    return buffer.toString();
  }

  /// Convert PascalCase or camelCase to snake_case
  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}')
        .replaceFirst(RegExp(r'^_'), '');
  }
}

class _FieldInfo {
  final String name;
  final DartType dartType;
  final String fieldType;
  final String? annotation;

  _FieldInfo({required this.name, required this.dartType, required this.fieldType, this.annotation});
}

class _FieldAnnotationInfo {
  final String type;
  final String fieldType;
  final String annotation;

  _FieldAnnotationInfo(this.type, this.fieldType, this.annotation);
}
