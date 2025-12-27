/// QuerySet - Lazy, chainable query builder.
///
/// QuerySets don't hit the database until evaluated. You can chain
/// filters, ordering, and other operations before execution.
library;

import 'dart:async';
import 'package:meta/meta.dart';
import 'expressions.dart';

/// Represents a database query that hasn't been executed yet.
///
/// QuerySets are lazy - they don't touch the database until you
/// iterate over them or call a method that evaluates them.
///
/// Each method that modifies the query returns a new QuerySet,
/// so the original is never mutated.
@immutable
class QuerySet<T> {
  /// The query configuration
  final QueryConfig config;

  /// Function to execute the query
  final QueryExecutor<T>? _executor;

  const QuerySet({this.config = const QueryConfig(), QueryExecutor<T>? executor}) : _executor = executor;

  /// Create a copy with modified config
  QuerySet<T> _copyWith({
    List<Q>? filters,
    List<Q>? excludes,
    List<OrderBy>? ordering,
    int? limit,
    int? offset,
    List<String>? selectRelated,
    List<String>? prefetchRelated,
    List<String>? only,
    List<String>? defer,
    bool? distinct,
    Map<String, Expression>? annotations,
  }) {
    return QuerySet<T>(
      config: config.copyWith(
        filters: filters,
        excludes: excludes,
        ordering: ordering,
        limit: limit,
        offset: offset,
        selectRelated: selectRelated,
        prefetchRelated: prefetchRelated,
        only: only,
        defer: defer,
        distinct: distinct,
        annotations: annotations,
      ),
      executor: _executor,
    );
  }

  // === Filtering ===

  /// Filter the queryset by conditions.
  ///
  /// Multiple conditions are ANDed together.
  ///
  /// ```dart
  /// // Single condition
  /// Author.objects.filter(Author.$.age.gte(18));
  ///
  /// // Multiple conditions (AND)
  /// Author.objects.filter(Author.$.age.gte(18) & Author.$.isActive.eq(true));
  ///
  /// // OR conditions
  /// Author.objects.filter(Author.$.age.lt(18) | Author.$.hasGuardian.eq(true));
  /// ```
  QuerySet<T> filter(Q condition) {
    return _copyWith(filters: [...config.filters, condition]);
  }

  /// Exclude objects matching the conditions.
  ///
  /// Opposite of filter - excludes matching objects.
  QuerySet<T> exclude(Q condition) {
    return _copyWith(excludes: [...config.excludes, condition]);
  }

  // === Ordering ===

  /// Order the results.
  ///
  /// ```dart
  /// Author.objects.orderBy(Author.$.name.asc());
  /// Author.objects.orderBy(Author.$.createdAt.desc());
  /// ```
  QuerySet<T> orderBy(OrderBy order, [OrderBy? order2, OrderBy? order3]) {
    final newOrdering = [order];
    if (order2 != null) newOrdering.add(order2);
    if (order3 != null) newOrdering.add(order3);
    return _copyWith(ordering: [...config.ordering, ...newOrdering]);
  }

  /// Clear all ordering
  QuerySet<T> unordered() {
    return _copyWith(ordering: []);
  }

  // === Limiting ===

  /// Limit the number of results
  QuerySet<T> limit(int count) {
    return _copyWith(limit: count);
  }

  /// Skip the first n results
  QuerySet<T> offset(int count) {
    return _copyWith(offset: count);
  }

  /// Slice the queryset (like Python's [start:end])
  QuerySet<T> slice(int start, [int? end]) {
    final newOffset = (config.offset ?? 0) + start;
    final newLimit = end != null ? end - start : null;
    return _copyWith(offset: newOffset, limit: newLimit);
  }

  /// Shorthand for limit(1).first()
  QuerySet<T> operator [](int index) {
    return slice(index, index + 1);
  }

  // === Related Objects ===

  /// Eagerly load related objects in a single query (JOIN).
  ///
  /// Use for ForeignKey and OneToOne relationships.
  ///
  /// ```dart
  /// Post.objects.selectRelated('author');
  /// Post.objects.selectRelated('author', 'category');
  /// Post.objects.selectRelated('author__company'); // nested
  /// ```
  QuerySet<T> selectRelated(String relation, [String? r2, String? r3]) {
    final relations = [relation];
    if (r2 != null) relations.add(r2);
    if (r3 != null) relations.add(r3);
    return _copyWith(selectRelated: [...config.selectRelated, ...relations]);
  }

  /// Eagerly load related objects in separate queries.
  ///
  /// Use for reverse ForeignKey and ManyToMany relationships.
  ///
  /// ```dart
  /// Author.objects.prefetchRelated('posts');
  /// Author.objects.prefetchRelated('posts', 'books');
  /// ```
  QuerySet<T> prefetchRelated(String relation, [String? r2, String? r3]) {
    final relations = [relation];
    if (r2 != null) relations.add(r2);
    if (r3 != null) relations.add(r3);
    return _copyWith(prefetchRelated: [...config.prefetchRelated, ...relations]);
  }

  // === Field Selection ===

  /// Only load specified fields.
  ///
  /// Other fields will be deferred (loaded on access).
  QuerySet<T> only(List<String> fields) {
    return _copyWith(only: fields);
  }

  /// Defer loading of specified fields.
  ///
  /// Deferred fields are loaded when accessed.
  QuerySet<T> defer(List<String> fields) {
    return _copyWith(defer: fields);
  }

  // === Annotations ===

  /// Add calculated fields to each result.
  ///
  /// ```dart
  /// Author.objects.annotate({
  ///   'post_count': Count(Post.$.id),
  /// });
  /// ```
  QuerySet<T> annotate(Map<String, Expression> annotations) =>
      _copyWith(annotations: {...config.annotations, ...annotations});

  // === Distinct ===

  /// Return only distinct results
  QuerySet<T> distinct() {
    return _copyWith(distinct: true);
  }

  // === Evaluation Methods ===

  /// Get all results as a list.
  Future<List<T>> toList() async {
    return switch (_executor) {
      final executor? => executor.execute(config),
      null => throw StateError('QuerySet has no executor configured'),
    };
  }

  /// Get the first result, or null if none.
  Future<T?> first() async {
    final results = await limit(1).toList();
    return results.isEmpty ? null : results.first;
  }

  /// Get the first result, or throw if none.
  Future<T> firstOrThrow() async {
    return switch (await first()) {
      final result? => result,
      null => throw StateError('QuerySet returned no results'),
    };
  }

  /// Get exactly one result.
  ///
  /// Throws if zero or more than one result.
  Future<T> single() async {
    return switch (await limit(2).toList()) {
      [] => throw StateError('QuerySet returned no results'),
      [final result] => result,
      _ => throw StateError('QuerySet returned more than one result'),
    };
  }

  /// Get the last result, or null if none.
  Future<T?> last() async {
    // Reverse ordering and get first
    final reversed = _copyWith(
      ordering: config.ordering.map((o) => OrderBy(o.expr, ascending: !o.ascending, nulls: o.nulls)).toList(),
    );
    return reversed.first();
  }

  /// Check if any results exist.
  Future<bool> exists() async {
    final results = await limit(1).toList();
    return results.isNotEmpty;
  }

  /// Count the number of results.
  Future<int> count() async {
    return switch (_executor) {
      final executor? => executor.count(config),
      null => throw StateError('QuerySet has no executor configured'),
    };
  }

  // === Aggregation ===

  /// Aggregate values across all results.
  ///
  /// ```dart
  /// final result = await Author.objects.aggregate({
  ///   'avg_age': Avg(Author.$.age),
  ///   'max_age': Max(Author.$.age),
  /// });
  /// print(result['avg_age']);
  /// ```
  Future<Map<String, dynamic>> aggregate(Map<String, Expression> aggregates) async {
    return switch (_executor) {
      final executor? => executor.aggregate(config, aggregates),
      null => throw StateError('QuerySet has no executor configured'),
    };
  }

  // === Iteration ===

  /// Stream results for memory-efficient processing.
  Stream<T> stream() {
    return switch (_executor) {
      final executor? => executor.stream(config),
      null => throw StateError('QuerySet has no executor configured'),
    };
  }

  /// Iterate in chunks for batch processing.
  Stream<List<T>> chunked(int chunkSize) async* {
    int currentOffset = config.offset ?? 0;
    while (true) {
      final chunk = await _copyWith(offset: currentOffset, limit: chunkSize).toList();

      if (chunk.isEmpty) break;
      yield chunk;

      if (chunk.length < chunkSize) break;
      currentOffset += chunkSize;
    }
  }

  // === Mutation Operations ===

  /// Update all matching objects.
  ///
  /// Returns the number of updated rows.
  ///
  /// ```dart
  /// await Author.objects
  ///   .filter(Author.$.isActive.eq(false))
  ///   .update({'isActive': true});
  /// ```
  Future<int> update(Map<String, Object?> values) async {
    return switch (_executor) {
      final executor? => executor.update(config, values),
      null => throw StateError('QuerySet has no executor configured'),
    };
  }

  /// Delete all matching objects.
  ///
  /// Returns the number of deleted rows.
  Future<int> delete() async {
    return switch (_executor) {
      final executor? => executor.delete(config),
      null => throw StateError('QuerySet has no executor configured'),
    };
  }

  @override
  String toString() => 'QuerySet<$T>($config)';
}

/// Configuration for a query
@immutable
class QueryConfig {
  final List<Q> filters;
  final List<Q> excludes;
  final List<OrderBy> ordering;
  final int? limit;
  final int? offset;
  final List<String> selectRelated;
  final List<String> prefetchRelated;
  final List<String> only;
  final List<String> defer;
  final bool distinct;
  final Map<String, Expression> annotations;

  const QueryConfig({
    this.filters = const [],
    this.excludes = const [],
    this.ordering = const [],
    this.limit,
    this.offset,
    this.selectRelated = const [],
    this.prefetchRelated = const [],
    this.only = const [],
    this.defer = const [],
    this.distinct = false,
    this.annotations = const {},
  });

  QueryConfig copyWith({
    List<Q>? filters,
    List<Q>? excludes,
    List<OrderBy>? ordering,
    int? limit,
    int? offset,
    List<String>? selectRelated,
    List<String>? prefetchRelated,
    List<String>? only,
    List<String>? defer,
    bool? distinct,
    Map<String, Expression>? annotations,
  }) {
    return QueryConfig(
      filters: filters ?? this.filters,
      excludes: excludes ?? this.excludes,
      ordering: ordering ?? this.ordering,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      selectRelated: selectRelated ?? this.selectRelated,
      prefetchRelated: prefetchRelated ?? this.prefetchRelated,
      only: only ?? this.only,
      defer: defer ?? this.defer,
      distinct: distinct ?? this.distinct,
      annotations: annotations ?? this.annotations,
    );
  }

  @override
  String toString() {
    final parts = <String>[];
    if (filters.isNotEmpty) parts.add('filters: $filters');
    if (excludes.isNotEmpty) parts.add('excludes: $excludes');
    if (ordering.isNotEmpty) parts.add('ordering: $ordering');
    if (limit != null) parts.add('limit: $limit');
    if (offset != null) parts.add('offset: $offset');
    if (distinct) parts.add('distinct: true');
    return 'QueryConfig(${parts.join(', ')})';
  }
}

/// Interface for executing queries
abstract class QueryExecutor<T> {
  Future<List<T>> execute(QueryConfig config);
  Future<int> count(QueryConfig config);
  Future<Map<String, dynamic>> aggregate(QueryConfig config, Map<String, Expression> aggregates);
  Stream<T> stream(QueryConfig config);
  Future<int> update(QueryConfig config, Map<String, Object?> values);
  Future<int> delete(QueryConfig config);
}
