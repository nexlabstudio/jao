import 'model_meta.dart';

/// Global registry for model metadata.
///
/// Models register their metadata at runtime (typically via generated code),
/// allowing the SQL compiler to look up relationship information for JOINs.
class ModelRegistry {
  ModelRegistry._();

  static final ModelRegistry instance = ModelRegistry._();

  final Map<Type, ModelMetadata> _byType = {};
  final Map<String, ModelMetadata> _byTableName = {};

  /// Register metadata for a model type.
  void register(ModelMetadata meta) {
    _byType[meta.modelType] = meta;
    _byTableName[meta.tableName] = meta;
  }

  /// Get metadata by Dart type.
  ModelMetadata? get<T>() => _byType[T];

  /// Get metadata by Dart type (runtime Type).
  ModelMetadata? getByType(Type type) => _byType[type];

  /// Get metadata by table name.
  ModelMetadata? getByTableName(String tableName) => _byTableName[tableName];

  /// Check if a model type is registered.
  bool isRegistered<T>() => _byType.containsKey(T);

  /// Check if a table name is registered.
  bool isTableRegistered(String tableName) => _byTableName.containsKey(tableName);

  /// Get all registered model metadata.
  Iterable<ModelMetadata> get all => _byType.values;

  /// Clear all registrations (useful for testing).
  void clear() {
    _byType.clear();
    _byTableName.clear();
  }

  /// Resolve a relation path like 'poll' or 'poll__author__profile'.
  ///
  /// Returns the list of JOINs needed to traverse the path,
  /// or null if the path cannot be resolved.
  List<ResolvedJoin>? resolveJoinPath(String baseTable, String path) {
    final baseMeta = getByTableName(baseTable);
    if (baseMeta == null) return null;

    final parts = path.split('__');
    final joins = <ResolvedJoin>[];
    var currentMeta = baseMeta;
    var currentTable = baseTable;

    for (final relationName in parts) {
      final relation = currentMeta.getRelation(relationName);
      if (relation == null) {
        // Not a relation, could be a field - stop here
        break;
      }

      final relatedMeta = getByType(relation.relatedModel);
      if (relatedMeta == null) return null;

      joins.add(ResolvedJoin(
        fromTable: currentTable,
        fromColumn: relation.columnName,
        toTable: relatedMeta.tableName,
        toColumn: relation.relatedColumn,
      ));

      currentTable = relatedMeta.tableName;
      currentMeta = relatedMeta;
    }

    return joins.isEmpty ? null : joins;
  }
}

/// A resolved JOIN between two tables.
class ResolvedJoin {
  final String fromTable;
  final String fromColumn;
  final String toTable;
  final String toColumn;

  const ResolvedJoin({
    required this.fromTable,
    required this.fromColumn,
    required this.toTable,
    required this.toColumn,
  });

  @override
  String toString() => 'JOIN $toTable ON $fromTable.$fromColumn = $toTable.$toColumn';
}
