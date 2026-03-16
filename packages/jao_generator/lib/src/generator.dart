import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:jao/jao.dart';
import 'package:source_gen/source_gen.dart';

class JaoGenerator extends GeneratorForAnnotation<Model> {
  @override
  String generateForAnnotatedElement(Element element, ConstantReader annotation, BuildStep buildStep) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError('@Model() can only be applied to classes.', element: element);
    }

    final classElement = element;
    final className = classElement.name ?? classElement.displayName;
    final fields = _extractFields(classElement);
    final tableName = annotation.peek('tableName')?.stringValue ?? _toSnakeCase(className);

    final buffer = StringBuffer();
    buffer.writeln(_generateFieldsClass(className, fields));
    buffer.writeln();
    buffer.writeln(_generateCompanionClass(className, tableName, fields));

    return buffer.toString();
  }

  List<_FieldInfo> _extractFields(ClassElement classElement) {
    final fields = <_FieldInfo>[];

    for (final field in classElement.fields) {
      if (field.isStatic || field.isSynthetic) continue;

      final fieldAnnotation = _getFieldAnnotation(field);
      if (fieldAnnotation != null) {
        final nullable = field.type.nullabilitySuffix != NullabilitySuffix.none;
        fields.add(
          _FieldInfo(
            name: field.name ?? field.displayName,
            dartType: field.type,
            fieldType: fieldAnnotation.fieldType,
            dbType: fieldAnnotation.dbType,
            annotation: fieldAnnotation.annotation,
            nullable: nullable,
            primaryKey: fieldAnnotation.primaryKey,
            autoIncrement: fieldAnnotation.autoIncrement,
            autoNowAdd: fieldAnnotation.autoNowAdd,
            autoNow: fieldAnnotation.autoNow,
            autoGenerateUuid: fieldAnnotation.autoGenerateUuid,
            defaultValue: fieldAnnotation.defaultValue,
            relation: fieldAnnotation.relation,
            isEnum: fieldAnnotation.isEnum,
            storeEnumAsInt: fieldAnnotation.storeEnumAsInt,
            maxLength: fieldAnnotation.maxLength,
            unique: fieldAnnotation.unique,
            precision: fieldAnnotation.precision,
            scale: fieldAnnotation.scale,
            onDelete: fieldAnnotation.onDelete,
          ),
        );
      } else {
        final inferred = _inferFieldType(field);
        if (inferred != null) {
          fields.add(inferred);
        }
      }
    }

    return fields;
  }

  /// Get a field value from a DartObject, traversing the superclass chain.
  /// `DartObject.getField()` only returns directly declared fields,
  /// so for inherited fields (e.g., `unique` on `EmailField` which inherits from `Field`)
  /// we need to walk up via the `(super)` synthetic field.
  DartObject? _getInheritedField(DartObject? obj, String fieldName) {
    if (obj == null || obj.isNull) return null;
    final direct = obj.getField(fieldName);
    if (direct case final direct? when !direct.isNull) return direct;
    final superObj = obj.getField('(super)');
    if (superObj case final superObj? when !superObj.isNull) {
      return _getInheritedField(superObj, fieldName);
    }
    return null;
  }

  Object? _extractDefaultValue(dynamic dartObject) {
    if (dartObject == null || dartObject.isNull) return null;

    if (dartObject.toIntValue() case final intVal?) return intVal;
    if (dartObject.toDoubleValue() case final doubleVal?) return doubleVal;
    if (dartObject.toBoolValue() case final boolVal?) return boolVal;
    if (dartObject.toStringValue() case final stringVal?) return stringVal;

    return null;
  }

  _FieldAnnotationInfo? _getFieldAnnotation(FieldElement field) {
    for (final annotation in field.metadata.annotations) {
      final value = annotation.computeConstantValue();
      if (value == null) continue;

      final type = value.type;
      if (type == null) continue;

      final typeName = type.getDisplayString();
      final baseTypeName = typeName.contains('<') ? typeName.substring(0, typeName.indexOf('<')) : typeName;
      final defaultValue = _extractDefaultValue(_getInheritedField(value, 'defaultValue'));
      final unique = _getInheritedField(value, 'unique')?.toBoolValue() ?? false;

      switch (baseTypeName) {
        case 'CharField':
          final maxLength = _getInheritedField(value, 'maxLength')?.toIntValue();
          return _FieldAnnotationInfo('String', 'StringFieldRef', 'varchar', annotation.toSource(),
              defaultValue: defaultValue, unique: unique, maxLength: maxLength);
        case 'TextField':
          return _FieldAnnotationInfo('String', 'StringFieldRef', 'text', annotation.toSource(),
              defaultValue: defaultValue, unique: unique);
        case 'EmailField':
          final maxLength = _getInheritedField(value, 'maxLength')?.toIntValue();
          return _FieldAnnotationInfo('String', 'StringFieldRef', 'varchar', annotation.toSource(),
              defaultValue: defaultValue, unique: unique, maxLength: maxLength);
        case 'UrlField':
          final maxLength = _getInheritedField(value, 'maxLength')?.toIntValue();
          return _FieldAnnotationInfo('String', 'StringFieldRef', 'varchar', annotation.toSource(),
              defaultValue: defaultValue, unique: unique, maxLength: maxLength);
        case 'IntegerField':
          return _FieldAnnotationInfo('int', 'IntFieldRef', 'integer', annotation.toSource(),
              defaultValue: defaultValue, unique: unique);
        case 'SmallIntegerField':
          return _FieldAnnotationInfo('int', 'IntFieldRef', 'smallInt', annotation.toSource(),
              defaultValue: defaultValue, unique: unique);
        case 'BigIntegerField':
          return _FieldAnnotationInfo('int', 'IntFieldRef', 'bigInt', annotation.toSource(),
              defaultValue: defaultValue, unique: unique);
        case 'PositiveIntegerField':
          return _FieldAnnotationInfo('int', 'IntFieldRef', 'integer', annotation.toSource(),
              defaultValue: defaultValue, unique: unique);
        case 'AutoField':
          return _FieldAnnotationInfo(
            'int',
            'IntFieldRef',
            'serial',
            annotation.toSource(),
            primaryKey: true,
            autoIncrement: true,
          );
        case 'BigAutoField':
          return _FieldAnnotationInfo(
            'int',
            'IntFieldRef',
            'bigSerial',
            annotation.toSource(),
            primaryKey: true,
            autoIncrement: true,
          );
        case 'FloatField':
          return _FieldAnnotationInfo('double', 'DoubleFieldRef', 'real', annotation.toSource(),
              defaultValue: defaultValue, unique: unique);
        case 'DecimalField':
          final maxDigits = _getInheritedField(value, 'maxDigits')?.toIntValue();
          final decimalPlaces = _getInheritedField(value, 'decimalPlaces')?.toIntValue();
          return _FieldAnnotationInfo('double', 'DoubleFieldRef', 'decimal', annotation.toSource(),
              defaultValue: defaultValue, unique: unique, precision: maxDigits, scale: decimalPlaces);
        case 'BooleanField':
          return _FieldAnnotationInfo('bool', 'BoolFieldRef', 'boolean', annotation.toSource(),
              defaultValue: defaultValue);
        case 'DateField':
          final dateAutoNowAdd = _getInheritedField(value, 'autoNowAdd')?.toBoolValue() ?? false;
          final dateAutoNow = _getInheritedField(value, 'autoNow')?.toBoolValue() ?? false;
          return _FieldAnnotationInfo(
            'DateTime',
            'DateTimeFieldRef',
            'date',
            annotation.toSource(),
            autoNowAdd: dateAutoNowAdd,
            autoNow: dateAutoNow,
            defaultValue: defaultValue,
          );
        case 'DateTimeField':
          final autoNowAdd = _getInheritedField(value, 'autoNowAdd')?.toBoolValue() ?? false;
          final autoNow = _getInheritedField(value, 'autoNow')?.toBoolValue() ?? false;
          return _FieldAnnotationInfo(
            'DateTime',
            'DateTimeFieldRef',
            'timestampTz',
            annotation.toSource(),
            autoNowAdd: autoNowAdd,
            autoNow: autoNow,
            defaultValue: defaultValue,
          );
        case 'DurationField':
          return _FieldAnnotationInfo('Duration', 'DurationFieldRef', 'interval', annotation.toSource(),
              defaultValue: defaultValue);
        case 'ForeignKey':
        case 'OneToOneField':
        case 'ManyToManyField':
          final toField = _getInheritedField(value, 'to');
          String? relatedModel;
          DartType? relatedDartType;
          if (toField != null) {
            relatedDartType = toField.toTypeValue();
            if (relatedDartType != null) {
              relatedModel = relatedDartType.getDisplayString();
            }
          }
          final toColumn = _getInheritedField(value, 'toColumn')?.toStringValue() ?? 'id';
          final relatedTable = relatedModel != null ? _toSnakeCase(relatedModel) : null;
          final relationType = switch (typeName) {
            'ForeignKey' => _RelationType.foreignKey,
            'OneToOneField' => _RelationType.oneToOne,
            'ManyToManyField' => _RelationType.manyToMany,
            _ => _RelationType.foreignKey,
          };
          final (pkType, pkFieldRef, pkDbType) = _resolvePkType(relatedDartType);
          final onDeleteField = _getInheritedField(value, 'onDelete');
          String? onDeleteValue;
          if (onDeleteField case final onDeleteField? when !onDeleteField.isNull) {
            final enumIndex = onDeleteField.getField('index')?.toIntValue();
            if (enumIndex case final enumIndex? when enumIndex >= 0) {
              onDeleteValue = const ['cascade', 'restrict', 'setNull', 'setDefault', 'noAction'][enumIndex];
            }
          }
          return _FieldAnnotationInfo(
            pkType,
            pkFieldRef,
            pkDbType,
            annotation.toSource(),
            onDelete: onDeleteValue,
            relation: relatedModel != null && relatedTable != null
                ? _RelationInfo(
                    relatedModel: relatedModel,
                    relatedTable: relatedTable,
                    relatedColumn: toColumn,
                    relationType: relationType,
                  )
                : null,
          );
        case 'UuidField':
          final autoGenerate = _getInheritedField(value, 'autoGenerate')?.toBoolValue() ?? false;
          return _FieldAnnotationInfo(
            'String',
            'StringFieldRef',
            'uuid',
            annotation.toSource(),
            autoGenerateUuid: autoGenerate,
            defaultValue: defaultValue,
            unique: unique,
          );
        case 'UuidPrimaryKey':
          return _FieldAnnotationInfo(
            'String',
            'StringFieldRef',
            'uuid',
            annotation.toSource(),
            primaryKey: true,
            autoGenerateUuid: true,
          );
        case 'JsonField':
          return _FieldAnnotationInfo('dynamic', 'FieldRef', 'jsonb', annotation.toSource(),
              defaultValue: defaultValue);
        case 'BinaryField':
          return _FieldAnnotationInfo('List<int>', 'FieldRef', 'bytea', annotation.toSource());
        case 'TimeField':
          return _FieldAnnotationInfo('Duration', 'DurationFieldRef', 'time', annotation.toSource(),
              defaultValue: defaultValue);
        case 'EnumField':
          final storeAsInt = _getInheritedField(value, 'storeAsInt')?.toBoolValue() ?? false;
          return _FieldAnnotationInfo(
            storeAsInt ? 'int' : 'String',
            storeAsInt ? 'IntFieldRef' : 'StringFieldRef',
            storeAsInt ? 'integer' : 'varchar',
            annotation.toSource(),
            defaultValue: defaultValue,
            unique: unique,
            isEnum: true,
            storeEnumAsInt: storeAsInt,
          );
      }
    }
    return null;
  }

  /// Resolves the primary key type of a related model by inspecting its fields.
  (String, String, String) _resolvePkType(DartType? relatedType) {
    const defaultPk = ('int', 'IntFieldRef', 'integer');

    if (relatedType == null || relatedType.element is! ClassElement) {
      return defaultPk;
    }

    final classElement = relatedType.element as ClassElement;
    for (final field in classElement.fields) {
      if (field.isStatic || field.isSynthetic) continue;
      for (final annotation in field.metadata.annotations) {
        final value = annotation.computeConstantValue();
        if (value == null) continue;
        final typeName = value.type?.getDisplayString();
        switch (typeName) {
          case 'AutoField':
            return ('int', 'IntFieldRef', 'integer');
          case 'BigAutoField':
            return ('int', 'IntFieldRef', 'bigInt');
          case 'UuidPrimaryKey':
            return ('String', 'StringFieldRef', 'uuid');
        }
      }
    }
    return defaultPk;
  }

  _FieldInfo? _inferFieldType(FieldElement field) {
    final type = field.type;
    final nullable = type.nullabilitySuffix != NullabilitySuffix.none;
    final rawTypeName = type.getDisplayString();
    final typeName = rawTypeName.endsWith('?') ? rawTypeName.substring(0, rawTypeName.length - 1) : rawTypeName;

    switch (typeName) {
      case 'String':
        return _FieldInfo(
          name: field.name ?? field.displayName,
          dartType: type,
          fieldType: 'StringFieldRef',
          dbType: 'varchar',
          nullable: nullable,
        );
      case 'int':
        final isPk = field.name == 'id';
        return _FieldInfo(
          name: field.name ?? field.displayName,
          dartType: type,
          fieldType: 'IntFieldRef',
          dbType: isPk ? 'serial' : 'integer',
          nullable: nullable,
          primaryKey: isPk,
          autoIncrement: isPk,
        );
      case 'double':
        return _FieldInfo(
          name: field.name ?? field.displayName,
          dartType: type,
          fieldType: 'DoubleFieldRef',
          dbType: 'doublePrecision',
          nullable: nullable,
        );
      case 'bool':
        return _FieldInfo(
          name: field.name ?? field.displayName,
          dartType: type,
          fieldType: 'BoolFieldRef',
          dbType: 'boolean',
          nullable: nullable,
        );
      case 'DateTime':
        return _FieldInfo(
          name: field.name ?? field.displayName,
          dartType: type,
          fieldType: 'DateTimeFieldRef',
          dbType: 'timestampTz',
          nullable: nullable,
        );
      case 'Duration':
        return _FieldInfo(
          name: field.name ?? field.displayName,
          dartType: type,
          fieldType: 'DurationFieldRef',
          dbType: 'interval',
          nullable: nullable,
        );
      default:
        return null;
    }
  }

  String _generateFieldsClass(String className, List<_FieldInfo> fields) {
    final buffer = StringBuffer();
    buffer.writeln('class ${className}\$ implements ModelFields<$className> {');
    buffer.writeln('  const ${className}\$();');
    buffer.writeln();

    for (final field in fields) {
      final columnName = _toSnakeCase(field.name);
      buffer.writeln('  final ${field.name} = const ${field.fieldType}(\'$columnName\');');
    }

    buffer.writeln('}');

    return buffer.toString();
  }

  String _generateCompanionClass(String className, String tableName, List<_FieldInfo> fields) {
    final buffer = StringBuffer();

    final pkField = fields.firstWhere(
      (f) =>
          f.annotation?.contains('AutoField') == true ||
          f.annotation?.contains('BigAutoField') == true ||
          f.annotation?.contains('UuidPrimaryKey') == true ||
          f.primaryKey,
      orElse: () => fields.firstWhere((f) => f.name == 'id', orElse: () => fields.first),
    );

    final autoNowAddFields = fields.where((f) => f.autoNowAdd).map((f) => _toSnakeCase(f.name)).toList();
    final autoNowFields = fields.where((f) => f.autoNow).map((f) => _toSnakeCase(f.name)).toList();
    final autoGenerateUuidFields = fields.where((f) => f.autoGenerateUuid).map((f) => _toSnakeCase(f.name)).toList();
    final fieldsWithDefaults = fields.where((f) => f.defaultValue != null).toList();

    buffer.writeln('class ${className}s {');
    buffer.writeln('  ${className}s._();');
    buffer.writeln();
    buffer.writeln('  static const \$ = ${className}\$();');
    buffer.writeln('  static bool _registered = false;');
    buffer.writeln('  static final Manager<$className> _objects = Manager<$className>();');
    buffer.writeln();
    buffer.writeln('  static Manager<$className> get objects {');
    buffer.writeln('    if (!_registered) {');
    buffer.writeln('      _registered = true;');
    buffer.writeln('      _registerMetadata();');
    buffer.writeln('      Jao.registerModel<$className>(ModelRegistration(');
    buffer.writeln('        tableName: tableName,');
    buffer.writeln('        pkField: pkField,');
    buffer.writeln('        fromRow: fromRow,');
    buffer.writeln('        toRow: toRow,');
    if (autoNowAddFields.isNotEmpty) {
      buffer.writeln("        autoNowAddFields: [${autoNowAddFields.map((f) => "'$f'").join(', ')}],");
    }
    if (autoNowFields.isNotEmpty) {
      buffer.writeln("        autoNowFields: [${autoNowFields.map((f) => "'$f'").join(', ')}],");
    }
    if (autoGenerateUuidFields.isNotEmpty) {
      buffer.writeln("        autoGenerateUuidFields: [${autoGenerateUuidFields.map((f) => "'$f'").join(', ')}],");
    }
    if (fieldsWithDefaults.isNotEmpty) {
      buffer.writeln('        defaultValues: {');
      for (final f in fieldsWithDefaults) {
        final columnName = _toSnakeCase(f.name);
        final emittedValue = switch (f.defaultValue) {
          final String v => "'$v'",
          final v => '$v',
        };
        buffer.writeln("          '$columnName': $emittedValue,");
      }
      buffer.writeln('        },');
    }
    buffer.writeln('      ));');
    buffer.writeln('    }');
    buffer.writeln('    return _objects;');
    buffer.writeln('  }');
    buffer.writeln();
    buffer.writeln('  static const tableName = \'$tableName\';');
    buffer.writeln('  static const pkField = \'${pkField.name}\';');
    buffer.writeln('  static const fieldNames = [');
    for (final field in fields) {
      buffer.writeln('    \'${field.name}\',');
    }
    buffer.writeln('  ];');
    buffer.writeln();
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
    buffer.writeln('  static Map<String, dynamic> toRow($className model) {');
    buffer.writeln('    return {');
    for (final field in fields) {
      final columnName = _toSnakeCase(field.name);
      buffer.writeln('      \'$columnName\': ${_generateToRowField(field, 'model')},');
    }
    buffer.writeln('    };');
    buffer.writeln('  }');
    buffer.writeln();
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
      if (field.unique) {
        buffer.writeln('        unique: true,');
      }
      if (field.maxLength case final maxLength?) {
        buffer.writeln('        maxLength: $maxLength,');
      }
      if (field.precision case final precision?) {
        buffer.writeln('        precision: $precision,');
      }
      if (field.scale case final scale?) {
        buffer.writeln('        scale: $scale,');
      }
      if (field.defaultValue case final defaultValue?) {
        final emittedValue = switch (defaultValue) {
          final String v => "'$v'",
          _ => '$defaultValue',
        };
        buffer.writeln("        defaultValue: $emittedValue,");
      }
      if (field.relation case final relation?) {
        final onDelete = field.onDelete ?? 'cascade';
        buffer.writeln('        foreignKey: ForeignKeyInfo(');
        buffer.writeln("          referencedTable: '${relation.relatedTable}',");
        buffer.writeln("          referencedColumn: '${relation.relatedColumn}',");
        buffer.writeln('          onDelete: OnDeleteAction.$onDelete,');
        buffer.writeln('        ),');
      }
      buffer.writeln('      ),');
    }
    buffer.writeln('    ],');
    buffer.writeln('  );');
    buffer.writeln();
    buffer.writeln('  static void _registerMetadata() {');
    buffer.writeln('    ModelRegistry.instance.register(ModelMetadata(');
    buffer.writeln('      modelType: $className,');
    buffer.writeln('      tableName: tableName,');
    buffer.writeln('      primaryKey: pkField,');
    buffer.writeln('      fields: {');
    for (final field in fields) {
      final columnName = _toSnakeCase(field.name);
      final rawTypeName = field.dartType.getDisplayString();
      final dartTypeName = rawTypeName.endsWith('?') ? rawTypeName.substring(0, rawTypeName.length - 1) : rawTypeName;
      buffer.writeln('        \'${field.name}\': FieldMeta(');
      buffer.writeln('          fieldName: \'${field.name}\',');
      buffer.writeln('          columnName: \'$columnName\',');
      buffer.writeln('          dartType: $dartTypeName,');
      buffer.writeln('          nullable: ${field.nullable},');
      buffer.writeln('          isPrimaryKey: ${field.primaryKey},');
      buffer.writeln('        ),');
    }
    buffer.writeln('      },');
    buffer.writeln('      relations: {');
    for (final field in fields) {
      if (field.relation case final relation?) {
        final columnName = _toSnakeCase(field.name);
        final relationType = switch (relation.relationType) {
          _RelationType.foreignKey => 'RelationType.foreignKey',
          _RelationType.oneToOne => 'RelationType.oneToOne',
          _RelationType.manyToMany => 'RelationType.manyToMany',
        };
        buffer.writeln('        \'${field.name}\': RelationMeta(');
        buffer.writeln('          fieldName: \'${field.name}\',');
        buffer.writeln('          columnName: \'${columnName}_id\',');
        buffer.writeln('          relatedModel: ${relation.relatedModel},');
        buffer.writeln('          relatedColumn: \'${relation.relatedColumn}\',');
        buffer.writeln('          type: $relationType,');
        buffer.writeln('        ),');
      }
    }
    buffer.writeln('      },');
    buffer.writeln('    ));');
    buffer.writeln('  }');
    buffer.writeln('}');

    return buffer.toString();
  }

  String _toSnakeCase(String input) {
    return input.replaceAllMapped(RegExp(r'[A-Z]'), (match) {
      if (match.group(0) case final g?) return '_${g.toLowerCase()}';
      return '';
    }).replaceFirst(RegExp(r'^_'), '');
  }

  String _generateFromRowField(_FieldInfo field, String columnName) {
    final rawTypeName = field.dartType.getDisplayString();
    final dartTypeName = rawTypeName.endsWith('?') ? rawTypeName.substring(0, rawTypeName.length - 1) : rawTypeName;
    final isNullable = field.nullable;
    final rowAccess = "row['$columnName']";

    if (field.isEnum) {
      if (field.storeEnumAsInt) {
        if (isNullable) {
          return '$rowAccess != null ? $dartTypeName.values[$rowAccess as int] : null';
        } else {
          return '$dartTypeName.values[$rowAccess as int]';
        }
      } else {
        if (isNullable) {
          return '$rowAccess != null ? $dartTypeName.values.byName($rowAccess as String) : null';
        } else {
          return '$dartTypeName.values.byName($rowAccess as String)';
        }
      }
    }

    switch (dartTypeName) {
      case 'DateTime':
        if (isNullable) {
          return 'dbDateTimeOrNull($rowAccess)';
        } else {
          return 'dbDateTime($rowAccess)';
        }

      case 'bool':
        if (isNullable) {
          return 'dbBoolOrNull($rowAccess)';
        } else {
          return 'dbBool($rowAccess)';
        }

      case 'int':
        if (isNullable) {
          return 'dbIntOrNull($rowAccess)';
        } else {
          return 'dbInt($rowAccess)';
        }

      case 'double':
        if (isNullable) {
          return 'dbDoubleOrNull($rowAccess)';
        } else {
          return 'dbDouble($rowAccess)';
        }

      case 'String':
        if (isNullable) {
          return '$rowAccess as String?';
        } else {
          return '$rowAccess as String';
        }

      case 'Duration':
        if (isNullable) {
          return 'dbDurationOrNull($rowAccess)';
        } else {
          return 'dbDuration($rowAccess)';
        }

      default:
        if (isNullable) {
          return '$rowAccess as $rawTypeName?';
        } else {
          return '$rowAccess as $rawTypeName';
        }
    }
  }

  String _generateToRowField(_FieldInfo field, String prefix) {
    final rawTypeName = field.dartType.getDisplayString();
    final dartTypeName = rawTypeName.endsWith('?') ? rawTypeName.substring(0, rawTypeName.length - 1) : rawTypeName;

    if (field.isEnum) {
      if (field.storeEnumAsInt) {
        if (field.nullable) {
          return '$prefix.${field.name}?.index';
        }
        return '$prefix.${field.name}.index';
      } else {
        if (field.nullable) {
          return '$prefix.${field.name}?.name';
        }
        return '$prefix.${field.name}.name';
      }
    }

    if (dartTypeName == 'DateTime') {
      if (field.nullable) {
        return '$prefix.${field.name}?.toIso8601String()';
      }
      return '$prefix.${field.name}.toIso8601String()';
    }

    if (dartTypeName == 'Duration') {
      if (field.nullable) {
        return '$prefix.${field.name}?.inMicroseconds';
      }
      return '$prefix.${field.name}.inMicroseconds';
    }

    return '$prefix.${field.name}';
  }
}

class _FieldInfo {
  final String name;
  final DartType dartType;
  final String fieldType;
  final String dbType;
  final String? annotation;
  final bool nullable;
  final bool primaryKey;
  final bool autoIncrement;
  final bool autoNowAdd;
  final bool autoNow;
  final bool autoGenerateUuid;
  final Object? defaultValue;
  final _RelationInfo? relation;
  final bool isEnum;
  final bool storeEnumAsInt;
  final int? maxLength;
  final bool unique;
  final int? precision;
  final int? scale;
  final String? onDelete;

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
    this.autoGenerateUuid = false,
    this.defaultValue,
    this.relation,
    this.isEnum = false,
    this.storeEnumAsInt = false,
    this.maxLength,
    this.unique = false,
    this.precision,
    this.scale,
    this.onDelete,
  });
}

enum _RelationType { foreignKey, oneToOne, manyToMany }

class _RelationInfo {
  final String relatedModel;
  final String relatedTable;
  final String relatedColumn;
  final _RelationType relationType;

  _RelationInfo({
    required this.relatedModel,
    required this.relatedTable,
    required this.relatedColumn,
    this.relationType = _RelationType.foreignKey,
  });
}

class _FieldAnnotationInfo {
  final String type;
  final String fieldType;
  final String dbType;
  final String annotation;
  final bool primaryKey;
  final bool autoIncrement;
  final bool autoNowAdd;
  final bool autoNow;
  final bool autoGenerateUuid;
  final Object? defaultValue;
  final _RelationInfo? relation;
  final bool isEnum;
  final bool storeEnumAsInt;
  final int? maxLength;
  final bool unique;
  final int? precision;
  final int? scale;
  final String? onDelete;

  _FieldAnnotationInfo(
    this.type,
    this.fieldType,
    this.dbType,
    this.annotation, {
    this.primaryKey = false,
    this.autoIncrement = false,
    this.autoNowAdd = false,
    this.autoNow = false,
    this.autoGenerateUuid = false,
    this.defaultValue,
    this.relation,
    this.isEnum = false,
    this.storeEnumAsInt = false,
    this.maxLength,
    this.unique = false,
    this.precision,
    this.scale,
    this.onDelete,
  });
}
