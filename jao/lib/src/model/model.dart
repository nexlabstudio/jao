/// Model annotation and base classes.
library;

import 'package:meta/meta.dart';

/// Annotation to mark a class as a database model.
///
/// The code generator will create:
/// - A `$` static field with typed field accessors
/// - A default `objects` manager
/// - Database schema metadata
///
/// ```dart
/// @Model()
/// class Author {
///   @AutoField()
///   late int id;
///
///   @CharField(maxLength: 100)
///   late String name;
///
///   @IntegerField()
///   late int age;
///
///   // Generated: static final $ = Author$();
///   // Generated: static final objects = Manager<Author>();
/// }
/// ```
@immutable
class Model {
  /// Database table name (defaults to snake_case of class name)
  final String? tableName;

  /// Whether this is an abstract model (no table created)
  final bool abstract;

  /// Custom ordering for queries without explicit orderBy
  final List<String>? ordering;

  /// Unique constraints across multiple fields
  final List<List<String>>? uniqueTogether;

  /// Index constraints across multiple fields
  final List<List<String>>? indexTogether;

  /// App label for namespacing
  final String? appLabel;

  const Model({
    this.tableName,
    this.abstract = false,
    this.ordering,
    this.uniqueTogether,
    this.indexTogether,
    this.appLabel,
  });
}

/// Mixin that provides model metadata.
///
/// Generated code will extend this to provide table info.
mixin ModelMeta {
  /// The database table name
  String get tableName;

  /// List of field names
  List<String> get fieldNames;

  /// The primary key field name
  String get pkField;
}

/// Marker interface for generated field accessor classes.
///
/// ```dart
/// // Generated
/// class Author$ implements ModelFields<Author> {
///   final name = StringFieldRef('name');
///   final age = IntFieldRef('age');
/// }
/// ```
abstract class ModelFields<T> {
  const ModelFields();
}

/// Mixin for soft-deletable models.
///
/// Adds `isDeleted` and `deletedAt` fields.
mixin SoftDelete {
  bool get isDeleted;
  set isDeleted(bool value);

  DateTime? get deletedAt;
  set deletedAt(DateTime? value);

  /// Mark as deleted without actually removing from database
  void softDelete() {
    isDeleted = true;
    deletedAt = DateTime.now();
  }

  /// Restore a soft-deleted object
  void restore() {
    isDeleted = false;
    deletedAt = null;
  }
}

/// Mixin for models with timestamps.
///
/// Adds `createdAt` and `updatedAt` fields.
mixin Timestamps {
  DateTime get createdAt;
  DateTime get updatedAt;
}

/// Mixin for models with a UUID primary key.
mixin UuidPk {
  String get id;
}

/// Exception thrown when an object is not found.
class ObjectDoesNotExist implements Exception {
  final Type modelType;
  final Object? lookupValue;

  const ObjectDoesNotExist(this.modelType, [this.lookupValue]);

  @override
  String toString() {
    if (lookupValue != null) {
      return '$modelType matching $lookupValue does not exist';
    }
    return '$modelType does not exist';
  }
}

/// Exception thrown when multiple objects are returned but one was expected.
class MultipleObjectsReturned implements Exception {
  final Type modelType;
  final int count;

  const MultipleObjectsReturned(this.modelType, this.count);

  @override
  String toString() => 'Expected one $modelType but got $count';
}

/// Exception thrown for validation errors.
class ValidationError implements Exception {
  final Map<String, List<String>> errors;

  const ValidationError(this.errors);

  /// Create a validation error for a single field
  factory ValidationError.forField(String field, String message) => ValidationError({
    field: [message],
  });

  @override
  String toString() {
    final messages = errors.entries.map((e) => '${e.key}: ${e.value.join(", ")}').join('; ');
    return 'ValidationError: $messages';
  }
}
