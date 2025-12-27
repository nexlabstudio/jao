/// Manager - Entry point for model queries.
///
/// Every model has a default manager accessible via `Model.objects`.
/// Custom managers can filter or modify the base QuerySet.
library;

import 'dart:async';
import '../query/queryset.dart';
import '../query/expressions.dart';
import '../dartonic.dart';

/// Manager provides the interface for making queries to the database.
///
/// Each model has at least one manager. The default manager is
/// available as `Model.objects`.
///
/// ```dart
/// // Get all authors
/// final authors = await Author.objects.all().toList();
///
/// // Filter authors
/// final adults = await Author.objects
///   .filter(Author.$.age.gte(18))
///   .toList();
///
/// // Get single author by primary key
/// final author = await Author.objects.get(1);
/// ```
class Manager<T> {
  /// The query executor for this manager
  final QueryExecutor<T>? _executor;

  /// Optional base filters applied to all queries
  final List<Q> _baseFilters;

  const Manager({QueryExecutor<T>? executor, List<Q> baseFilters = const []})
    : _executor = executor,
      _baseFilters = baseFilters;

  /// Get the base QuerySet for this manager
  QuerySet<T> _baseQuerySet() {
    // Use explicit executor if provided, otherwise try global Dartonic config
    final executor = _executor ?? (Dartonic.isInitialized ? Dartonic.instance.executor<T>() : null);
    var qs = QuerySet<T>(executor: executor);
    for (final filter in _baseFilters) {
      qs = qs.filter(filter);
    }
    return qs;
  }

  // === QuerySet Methods ===

  /// Get all objects
  QuerySet<T> all() => _baseQuerySet();

  /// Filter objects by conditions
  QuerySet<T> filter(Q condition) => _baseQuerySet().filter(condition);

  /// Exclude objects matching conditions
  QuerySet<T> exclude(Q condition) => _baseQuerySet().exclude(condition);

  /// Order results
  QuerySet<T> orderBy(OrderBy order, [OrderBy? order2, OrderBy? order3]) =>
      _baseQuerySet().orderBy(order, order2, order3);

  /// Limit results
  QuerySet<T> limit(int count) => _baseQuerySet().limit(count);

  /// Skip results
  QuerySet<T> offset(int count) => _baseQuerySet().offset(count);

  /// Distinct results
  QuerySet<T> distinct() => _baseQuerySet().distinct();

  /// Select related (JOIN)
  QuerySet<T> selectRelated(String relation, [String? r2, String? r3]) =>
      _baseQuerySet().selectRelated(relation, r2, r3);

  /// Prefetch related (separate query)
  QuerySet<T> prefetchRelated(String relation, [String? r2, String? r3]) =>
      _baseQuerySet().prefetchRelated(relation, r2, r3);

  /// Only load specified fields
  QuerySet<T> only(List<String> fields) => _baseQuerySet().only(fields);

  /// Defer loading of specified fields
  QuerySet<T> defer(List<String> fields) => _baseQuerySet().defer(fields);

  /// Add calculated fields
  QuerySet<T> annotate(Map<String, Expression> annotations) => _baseQuerySet().annotate(annotations);

  // === Shortcut Methods ===

  /// Get object by primary key.
  ///
  /// Throws if not found.
  Future<T> get(Object pk) async {
    // This will be customized by the code generator to use the actual PK field
    final qs = filter(Q(Comparison(ColumnRef('id'), ComparisonOp.eq, Value(pk))));
    return qs.single();
  }

  /// Get object by primary key, or null if not found.
  Future<T?> getOrNull(Object pk) async {
    try {
      return await get(pk);
    } catch (_) {
      return null;
    }
  }

  /// Get first object, or null if none exist.
  Future<T?> first() => _baseQuerySet().first();

  /// Get last object, or null if none exist.
  Future<T?> last() => _baseQuerySet().last();

  /// Check if any objects exist.
  Future<bool> exists() => _baseQuerySet().exists();

  /// Count all objects.
  Future<int> count() => _baseQuerySet().count();

  /// Get object matching conditions, or create if none exists.
  ///
  /// Returns a tuple of (object, wasCreated).
  Future<(T, bool)> getOrCreate({required Q condition, required Map<String, Object?> defaults}) async {
    final existing = await filter(condition).first();
    if (existing != null) {
      return (existing, false);
    }
    // Create new object with defaults
    final created = await create(defaults);
    return (created, true);
  }

  /// Update object matching conditions, or create if none exists.
  ///
  /// Returns a tuple of (object, wasCreated).
  Future<(T, bool)> updateOrCreate({required Q condition, required Map<String, Object?> defaults}) async {
    final existing = await filter(condition).first();
    if (existing != null) {
      await filter(condition).update(defaults);
      // Re-fetch to get updated values
      final updated = await filter(condition).single();
      return (updated, false);
    }
    final created = await create(defaults);
    return (created, true);
  }

  // === Create/Update/Delete ===

  /// Create a new object.
  Future<T> create(Map<String, Object?> values) async {
    final executor = _executor ?? (Dartonic.isInitialized ? Dartonic.instance.executor<T>() : null);
    if (executor == null) {
      throw StateError('Manager has no executor configured. Call Dartonic.initialize() and register your models first.');
    }
    // The executor handles the actual insertion
    return (executor as CreateCapable<T>).create(values);
  }

  /// Create multiple objects in bulk.
  Future<List<T>> bulkCreate(List<Map<String, Object?>> objects) async {
    final executor = _executor ?? (Dartonic.isInitialized ? Dartonic.instance.executor<T>() : null);
    if (executor == null) {
      throw StateError('Manager has no executor configured. Call Dartonic.initialize() and register your models first.');
    }
    return (executor as CreateCapable<T>).bulkCreate(objects);
  }

  /// Update all objects matching conditions.
  Future<int> update(Q condition, Map<String, Object?> values) async {
    return filter(condition).update(values);
  }

  /// Delete all objects matching conditions.
  Future<int> delete(Q condition) async {
    return filter(condition).delete();
  }

  // === Aggregation ===

  /// Aggregate across all objects.
  Future<Map<String, dynamic>> aggregate(Map<String, Expression> aggregates) => _baseQuerySet().aggregate(aggregates);

  // === Raw Queries ===

  /// Execute raw SQL query.
  ///
  /// Use with caution - not portable across databases.
  Future<List<Map<String, dynamic>>> raw(String sql, [List<Object?>? params]) async {
    final executor = _executor ?? (Dartonic.isInitialized ? Dartonic.instance.executor<T>() : null);
    if (executor == null) {
      throw StateError('Manager has no executor configured. Call Dartonic.initialize() and register your models first.');
    }
    return (executor as RawQueryCapable).rawQuery(sql, params);
  }
}

/// Interface for executors that can create objects
abstract class CreateCapable<T> {
  Future<T> create(Map<String, Object?> values);
  Future<List<T>> bulkCreate(List<Map<String, Object?>> objects);
}

/// Interface for executors that can run raw queries
abstract class RawQueryCapable {
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<Object?>? params]);
}

/// A manager that filters to only active/visible objects.
///
/// Useful for soft-delete patterns.
///
/// ```dart
/// class Author extends Model {
///   static final objects = Manager<Author>();
///   static final active = ActiveManager<Author>(
///     baseFilter: Author.$.isDeleted.eq(false),
///   );
/// }
/// ```
class FilteredManager<T> extends Manager<T> {
  FilteredManager({required Q baseFilter, super.executor}) : super(baseFilters: [baseFilter]);
}
