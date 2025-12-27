library;

import 'dart:async';
import '../query/queryset.dart';
import '../query/expressions.dart';
import '../dartonic.dart';

class Manager<T> {
  final QueryExecutor<T>? _executor;
  final List<Q> _baseFilters;

  const Manager({QueryExecutor<T>? executor, List<Q> baseFilters = const []})
    : _executor = executor,
      _baseFilters = baseFilters;

  QuerySet<T> _baseQuerySet() {
    final executor = _executor ?? (Dartonic.isInitialized ? Dartonic.instance.executor<T>() : null);
    var qs = QuerySet<T>(executor: executor);
    for (final filter in _baseFilters) {
      qs = qs.filter(filter);
    }
    return qs;
  }

  QuerySet<T> all() => _baseQuerySet();
  QuerySet<T> filter(Q condition) => _baseQuerySet().filter(condition);
  QuerySet<T> exclude(Q condition) => _baseQuerySet().exclude(condition);
  QuerySet<T> orderBy(OrderBy order, [OrderBy? order2, OrderBy? order3]) =>
      _baseQuerySet().orderBy(order, order2, order3);
  QuerySet<T> limit(int count) => _baseQuerySet().limit(count);
  QuerySet<T> offset(int count) => _baseQuerySet().offset(count);
  QuerySet<T> distinct() => _baseQuerySet().distinct();
  QuerySet<T> selectRelated(String relation, [String? r2, String? r3]) =>
      _baseQuerySet().selectRelated(relation, r2, r3);
  QuerySet<T> prefetchRelated(String relation, [String? r2, String? r3]) =>
      _baseQuerySet().prefetchRelated(relation, r2, r3);
  QuerySet<T> only(List<String> fields) => _baseQuerySet().only(fields);
  QuerySet<T> defer(List<String> fields) => _baseQuerySet().defer(fields);
  QuerySet<T> annotate(Map<String, Expression> annotations) => _baseQuerySet().annotate(annotations);

  Future<T> get(Object pk) async {
    final qs = filter(Q(Comparison(ColumnRef('id'), ComparisonOp.eq, Value(pk))));
    return qs.single();
  }

  Future<T?> getOrNull(Object pk) async {
    try {
      return await get(pk);
    } catch (_) {
      return null;
    }
  }

  Future<T?> first() => _baseQuerySet().first();
  Future<T?> last() => _baseQuerySet().last();
  Future<bool> exists() => _baseQuerySet().exists();
  Future<int> count() => _baseQuerySet().count();

  Future<(T, bool)> getOrCreate({required Q condition, required Map<String, Object?> defaults}) async {
    final existing = await filter(condition).first();
    if (existing != null) {
      return (existing, false);
    }
    final created = await create(defaults);
    return (created, true);
  }

  Future<(T, bool)> updateOrCreate({required Q condition, required Map<String, Object?> defaults}) async {
    final existing = await filter(condition).first();
    if (existing != null) {
      await filter(condition).update(defaults);
      final updated = await filter(condition).single();
      return (updated, false);
    }
    final created = await create(defaults);
    return (created, true);
  }

  Future<T> create(Map<String, Object?> values) async {
    final executor = _executor ?? (Dartonic.isInitialized ? Dartonic.instance.executor<T>() : null);
    if (executor == null) {
      throw StateError('Manager has no executor configured. Call Dartonic.initialize() and register your models first.');
    }
    return (executor as CreateCapable<T>).create(values);
  }

  Future<List<T>> bulkCreate(List<Map<String, Object?>> objects) async {
    final executor = _executor ?? (Dartonic.isInitialized ? Dartonic.instance.executor<T>() : null);
    if (executor == null) {
      throw StateError('Manager has no executor configured. Call Dartonic.initialize() and register your models first.');
    }
    return (executor as CreateCapable<T>).bulkCreate(objects);
  }

  Future<int> update(Q condition, Map<String, Object?> values) async {
    return filter(condition).update(values);
  }

  Future<int> delete(Q condition) async {
    return filter(condition).delete();
  }

  Future<Map<String, dynamic>> aggregate(Map<String, Expression> aggregates) => _baseQuerySet().aggregate(aggregates);

  Future<List<Map<String, dynamic>>> raw(String sql, [List<Object?>? params]) async {
    final executor = _executor ?? (Dartonic.isInitialized ? Dartonic.instance.executor<T>() : null);
    if (executor == null) {
      throw StateError('Manager has no executor configured. Call Dartonic.initialize() and register your models first.');
    }
    return (executor as RawQueryCapable).rawQuery(sql, params);
  }
}

abstract class CreateCapable<T> {
  Future<T> create(Map<String, Object?> values);
  Future<List<T>> bulkCreate(List<Map<String, Object?>> objects);
}

abstract class RawQueryCapable {
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<Object?>? params]);
}

class FilteredManager<T> extends Manager<T> {
  FilteredManager({required Q baseFilter, super.executor}) : super(baseFilters: [baseFilter]);
}
