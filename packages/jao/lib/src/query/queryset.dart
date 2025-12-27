library;

import 'dart:async';
import 'package:meta/meta.dart';
import 'expressions.dart';

@immutable
class QuerySet<T> {
  final QueryConfig config;
  final QueryExecutor<T>? _executor;

  const QuerySet({this.config = const QueryConfig(), QueryExecutor<T>? executor}) : _executor = executor;

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

  QuerySet<T> filter(Q condition) {
    return _copyWith(filters: [...config.filters, condition]);
  }

  QuerySet<T> exclude(Q condition) {
    return _copyWith(excludes: [...config.excludes, condition]);
  }

  QuerySet<T> orderBy(OrderBy order, [OrderBy? order2, OrderBy? order3]) {
    final newOrdering = [order];
    if (order2 != null) newOrdering.add(order2);
    if (order3 != null) newOrdering.add(order3);
    return _copyWith(ordering: [...config.ordering, ...newOrdering]);
  }

  QuerySet<T> unordered() => _copyWith(ordering: []);
  QuerySet<T> limit(int count) => _copyWith(limit: count);
  QuerySet<T> offset(int count) => _copyWith(offset: count);

  QuerySet<T> slice(int start, [int? end]) {
    final newOffset = (config.offset ?? 0) + start;
    final newLimit = end != null ? end - start : null;
    return _copyWith(offset: newOffset, limit: newLimit);
  }

  QuerySet<T> operator [](int index) => slice(index, index + 1);

  QuerySet<T> selectRelated(String relation, [String? r2, String? r3]) {
    final relations = [relation];
    if (r2 != null) relations.add(r2);
    if (r3 != null) relations.add(r3);
    return _copyWith(selectRelated: [...config.selectRelated, ...relations]);
  }

  QuerySet<T> prefetchRelated(String relation, [String? r2, String? r3]) {
    final relations = [relation];
    if (r2 != null) relations.add(r2);
    if (r3 != null) relations.add(r3);
    return _copyWith(prefetchRelated: [...config.prefetchRelated, ...relations]);
  }

  QuerySet<T> only(List<String> fields) => _copyWith(only: fields);
  QuerySet<T> defer(List<String> fields) => _copyWith(defer: fields);
  QuerySet<T> annotate(Map<String, Expression> annotations) =>
      _copyWith(annotations: {...config.annotations, ...annotations});
  QuerySet<T> distinct() => _copyWith(distinct: true);

  Future<List<T>> toList() async {
    return switch (_executor) {
      final executor? => executor.execute(config),
      null => throw StateError('QuerySet has no executor configured'),
    };
  }

  Future<T?> first() async {
    final results = await limit(1).toList();
    return results.isEmpty ? null : results.first;
  }

  Future<T> firstOrThrow() async {
    return switch (await first()) {
      final result? => result,
      null => throw StateError('QuerySet returned no results'),
    };
  }

  Future<T> single() async {
    return switch (await limit(2).toList()) {
      [] => throw StateError('QuerySet returned no results'),
      [final result] => result,
      _ => throw StateError('QuerySet returned more than one result'),
    };
  }

  Future<T?> last() async {
    final reversed = _copyWith(
      ordering: config.ordering.map((o) => OrderBy(o.expr, ascending: !o.ascending, nulls: o.nulls)).toList(),
    );
    return reversed.first();
  }

  Future<bool> exists() async {
    final results = await limit(1).toList();
    return results.isNotEmpty;
  }

  Future<int> count() async {
    return switch (_executor) {
      final executor? => executor.count(config),
      null => throw StateError('QuerySet has no executor configured'),
    };
  }

  Future<Map<String, dynamic>> aggregate(Map<String, Expression> aggregates) async {
    return switch (_executor) {
      final executor? => executor.aggregate(config, aggregates),
      null => throw StateError('QuerySet has no executor configured'),
    };
  }

  Stream<T> stream() {
    return switch (_executor) {
      final executor? => executor.stream(config),
      null => throw StateError('QuerySet has no executor configured'),
    };
  }

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

  Future<int> update(Map<String, Object?> values) async {
    return switch (_executor) {
      final executor? => executor.update(config, values),
      null => throw StateError('QuerySet has no executor configured'),
    };
  }

  Future<int> delete() async {
    return switch (_executor) {
      final executor? => executor.delete(config),
      null => throw StateError('QuerySet has no executor configured'),
    };
  }

  @override
  String toString() => 'QuerySet<$T>($config)';
}

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

abstract class QueryExecutor<T> {
  Future<List<T>> execute(QueryConfig config);
  Future<int> count(QueryConfig config);
  Future<Map<String, dynamic>> aggregate(QueryConfig config, Map<String, Expression> aggregates);
  Stream<T> stream(QueryConfig config);
  Future<int> update(QueryConfig config, Map<String, Object?> values);
  Future<int> delete(QueryConfig config);
}
