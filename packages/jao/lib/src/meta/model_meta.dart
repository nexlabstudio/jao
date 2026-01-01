/// Relationship types for model relations.
enum RelationType { foreignKey, oneToOne, manyToMany }

class FieldMeta {
  /// The Dart field name (e.g., 'createdAt').
  final String fieldName;

  /// The database column name (e.g., 'created_at').
  final String columnName;

  /// The Dart type (e.g., int, String, DateTime).
  final Type dartType;

  /// Whether this field is nullable.
  final bool nullable;

  /// Whether this field is the primary key.
  final bool isPrimaryKey;

  const FieldMeta({
    required this.fieldName,
    required this.columnName,
    required this.dartType,
    this.nullable = false,
    this.isPrimaryKey = false,
  });

  @override
  String toString() => 'FieldMeta($fieldName -> $columnName, $dartType)';
}

/// Describes a relationship (ForeignKey, OneToOneField) between models.
class RelationMeta {
  /// The Dart field name on the source model (e.g., 'pollId').
  final String fieldName;

  /// The database column name for the FK (e.g., 'poll_id').
  final String columnName;

  /// The related model's Type (e.g., Poll).
  final Type relatedModel;

  /// The column on the related table to join on (usually 'id').
  final String relatedColumn;

  /// The type of relationship.
  final RelationType type;

  /// The name for reverse lookups (e.g., 'choices' for Poll -> Choice).
  final String? relatedName;

  const RelationMeta({
    required this.fieldName,
    required this.columnName,
    required this.relatedModel,
    this.relatedColumn = 'id',
    this.type = RelationType.foreignKey,
    this.relatedName,
  });

  @override
  String toString() => 'RelationMeta($fieldName: $relatedModel via $columnName -> $relatedColumn)';
}

/// Metadata for a model, including its fields and relationships.
class ModelMetadata {
  /// The Dart model Type
  final Type modelType;

  /// The database table name
  final String tableName;

  /// The primary key field name
  final String primaryKey;

  /// All fields in this model, keyed by field name.
  final Map<String, FieldMeta> fields;

  /// All relationships in this model, keyed by field name.
  final Map<String, RelationMeta> relations;

  const ModelMetadata({
    required this.modelType,
    required this.tableName,
    this.primaryKey = 'id',
    required this.fields,
    this.relations = const {},
  });

  /// Get a field by its Dart name.
  FieldMeta? getField(String name) => fields[name];

  /// Get a relation by its field name.
  RelationMeta? getRelation(String fieldName) => relations[fieldName];

  /// Get a relation by the related model Type.
  RelationMeta? getRelationByType(Type type) {
    for (final relation in relations.values) {
      if (relation.relatedModel == type) return relation;
    }
    return null;
  }

  @override
  String toString() =>
      'ModelMetadata($modelType -> $tableName, ${fields.length} fields, ${relations.length} relations)';
}
