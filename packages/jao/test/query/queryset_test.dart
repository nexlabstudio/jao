import 'package:jao/jao.dart';
import 'package:test/test.dart';

void main() {
  group('QuerySet', () {
    group('initial state', () {
      test('starts with empty config', () {
        final qs = QuerySet<Map<String, dynamic>>();
        expect(qs.config.filters, isEmpty);
        expect(qs.config.excludes, isEmpty);
        expect(qs.config.ordering, isEmpty);
        expect(qs.config.limit, isNull);
        expect(qs.config.offset, isNull);
        expect(qs.config.distinct, isFalse);
      });

      test('toString includes type', () {
        final qs = QuerySet<String>();
        expect(qs.toString(), contains('QuerySet<String>'));
      });
    });

    group('filter()', () {
      test('adds to filters list', () {
        final q = Q(const Comparison(ColumnRef('name'), ComparisonOp.eq, Value('test')));
        final qs = QuerySet<Map<String, dynamic>>().filter(q);
        expect(qs.config.filters.length, equals(1));
        expect(qs.config.filters.first, equals(q));
      });

      test('returns new QuerySet (immutable)', () {
        final qs1 = QuerySet<Map<String, dynamic>>();
        final q = Q(const Comparison(ColumnRef('name'), ComparisonOp.eq, Value('test')));
        final qs2 = qs1.filter(q);

        expect(qs1.config.filters, isEmpty);
        expect(qs2.config.filters.length, equals(1));
        expect(identical(qs1, qs2), isFalse);
      });

      test('can be called multiple times (AND)', () {
        final q1 = Q(const Comparison(ColumnRef('name'), ComparisonOp.eq, Value('test')));
        final q2 = Q(const Comparison(ColumnRef('age'), ComparisonOp.gte, Value(18)));
        final qs = QuerySet<Map<String, dynamic>>().filter(q1).filter(q2);

        expect(qs.config.filters.length, equals(2));
      });
    });

    group('exclude()', () {
      test('adds to excludes list', () {
        final q = Q(const Comparison(ColumnRef('status'), ComparisonOp.eq, Value('deleted')));
        final qs = QuerySet<Map<String, dynamic>>().exclude(q);
        expect(qs.config.excludes.length, equals(1));
      });

      test('returns new QuerySet (immutable)', () {
        final qs1 = QuerySet<Map<String, dynamic>>();
        final q = Q(const Comparison(ColumnRef('status'), ComparisonOp.eq, Value('deleted')));
        final qs2 = qs1.exclude(q);

        expect(qs1.config.excludes, isEmpty);
        expect(qs2.config.excludes.length, equals(1));
      });
    });

    group('orderBy()', () {
      test('sets ordering with single column', () {
        final order = const OrderBy(ColumnRef('name'));
        final qs = QuerySet<Map<String, dynamic>>().orderBy(order);
        expect(qs.config.ordering.length, equals(1));
      });

      test('sets ordering with multiple columns', () {
        final order1 = const OrderBy(ColumnRef('name'));
        final order2 = const OrderBy(ColumnRef('age'), ascending: false);
        final qs = QuerySet<Map<String, dynamic>>().orderBy(order1, order2);
        expect(qs.config.ordering.length, equals(2));
      });

      test('appends to previous ordering', () {
        final order1 = const OrderBy(ColumnRef('name'));
        final order2 = const OrderBy(ColumnRef('age'));
        final qs = QuerySet<Map<String, dynamic>>().orderBy(order1).orderBy(order2);
        expect(qs.config.ordering.length, equals(2));
      });
    });

    group('unordered()', () {
      test('clears ordering', () {
        final order = const OrderBy(ColumnRef('name'));
        final qs = QuerySet<Map<String, dynamic>>().orderBy(order).unordered();
        expect(qs.config.ordering, isEmpty);
      });
    });

    group('limit()', () {
      test('sets limit', () {
        final qs = QuerySet<Map<String, dynamic>>().limit(10);
        expect(qs.config.limit, equals(10));
      });

      test('returns new QuerySet', () {
        final qs1 = QuerySet<Map<String, dynamic>>();
        final qs2 = qs1.limit(10);
        expect(qs1.config.limit, isNull);
        expect(qs2.config.limit, equals(10));
      });
    });

    group('offset()', () {
      test('sets offset', () {
        final qs = QuerySet<Map<String, dynamic>>().offset(20);
        expect(qs.config.offset, equals(20));
      });

      test('returns new QuerySet', () {
        final qs1 = QuerySet<Map<String, dynamic>>();
        final qs2 = qs1.offset(20);
        expect(qs1.config.offset, isNull);
        expect(qs2.config.offset, equals(20));
      });
    });

    group('slice()', () {
      test('sets both limit and offset', () {
        final qs = QuerySet<Map<String, dynamic>>().slice(20, 30);
        expect(qs.config.offset, equals(20));
        expect(qs.config.limit, equals(10));
      });

      test('with only start sets offset', () {
        final qs = QuerySet<Map<String, dynamic>>().slice(20);
        expect(qs.config.offset, equals(20));
        expect(qs.config.limit, isNull);
      });

      test('slice adds to existing offset', () {
        final qs = QuerySet<Map<String, dynamic>>().offset(10).slice(5, 15);
        expect(qs.config.offset, equals(15)); // 10 + 5
        expect(qs.config.limit, equals(10)); // 15 - 5
      });
    });

    group('operator []', () {
      test('returns slice with single item', () {
        final qs = QuerySet<Map<String, dynamic>>()[5];
        expect(qs.config.offset, equals(5));
        expect(qs.config.limit, equals(1));
      });
    });

    group('distinct()', () {
      test('sets distinct flag', () {
        final qs = QuerySet<Map<String, dynamic>>().distinct();
        expect(qs.config.distinct, isTrue);
      });
    });

    group('only()', () {
      test('sets field selection', () {
        final qs = QuerySet<Map<String, dynamic>>().only(['id', 'name']);
        expect(qs.config.only, equals(['id', 'name']));
      });
    });

    group('defer()', () {
      test('sets deferred fields', () {
        final qs = QuerySet<Map<String, dynamic>>().defer(['content', 'bio']);
        expect(qs.config.defer, equals(['content', 'bio']));
      });
    });

    group('annotate()', () {
      test('adds annotations', () {
        final qs = QuerySet<Map<String, dynamic>>().annotate({'total': Count.all()});
        expect(qs.config.annotations.containsKey('total'), isTrue);
        expect(qs.config.annotations['total'], isA<Count>());
      });

      test('merges with existing annotations', () {
        final qs = QuerySet<Map<String, dynamic>>().annotate({'count': Count.all()}).annotate({
          'sum': Sum(const ColumnRef('amount')),
        });
        expect(qs.config.annotations.length, equals(2));
      });
    });

    group('selectRelated()', () {
      test('adds to select list', () {
        final qs = QuerySet<Map<String, dynamic>>().selectRelated('author');
        expect(qs.config.selectRelated, contains('author'));
      });

      test('can add multiple relations', () {
        final qs = QuerySet<Map<String, dynamic>>().selectRelated('author', 'category', 'publisher');
        expect(qs.config.selectRelated.length, equals(3));
      });
    });

    group('prefetchRelated()', () {
      test('adds to prefetch list', () {
        final qs = QuerySet<Map<String, dynamic>>().prefetchRelated('comments');
        expect(qs.config.prefetchRelated, contains('comments'));
      });

      test('can add multiple relations', () {
        final qs = QuerySet<Map<String, dynamic>>().prefetchRelated('comments', 'tags', 'likes');
        expect(qs.config.prefetchRelated.length, equals(3));
      });
    });

    group('chaining', () {
      test('preserves all config in complex chain', () {
        final q = Q(const Comparison(ColumnRef('status'), ComparisonOp.eq, Value('active')));
        final order = const OrderBy(ColumnRef('created_at'), ascending: false);

        final qs = QuerySet<Map<String, dynamic>>().filter(q).orderBy(order).limit(10).offset(20).distinct().only([
          'id',
          'name',
          'email',
        ]);

        expect(qs.config.filters.length, equals(1));
        expect(qs.config.ordering.length, equals(1));
        expect(qs.config.limit, equals(10));
        expect(qs.config.offset, equals(20));
        expect(qs.config.distinct, isTrue);
        expect(qs.config.only.length, equals(3));
      });
    });

    group('lazy evaluation', () {
      test('QuerySet does not execute without terminal operation', () {
        // This test verifies that creating and chaining QuerySets
        // does not trigger any database operation
        final q = Q(const Comparison(ColumnRef('name'), ComparisonOp.eq, Value('test')));
        final order = const OrderBy(ColumnRef('name'));

        // These operations should not throw even without an executor
        final qs = QuerySet<Map<String, dynamic>>().filter(q).orderBy(order).limit(10);

        expect(qs.config.filters, isNotEmpty);
        expect(qs.config.ordering, isNotEmpty);
        expect(qs.config.limit, equals(10));
      });

      test('toList() throws without executor', () async {
        final qs = QuerySet<Map<String, dynamic>>();
        expect(() => qs.toList(), throwsStateError);
      });

      test('first() throws without executor', () async {
        final qs = QuerySet<Map<String, dynamic>>();
        expect(() => qs.first(), throwsStateError);
      });

      test('count() throws without executor', () async {
        final qs = QuerySet<Map<String, dynamic>>();
        expect(() => qs.count(), throwsStateError);
      });

      test('exists() throws without executor', () async {
        final qs = QuerySet<Map<String, dynamic>>();
        expect(() => qs.exists(), throwsStateError);
      });

      test('update() throws without executor', () async {
        final qs = QuerySet<Map<String, dynamic>>();
        expect(() => qs.update({'name': 'test'}), throwsStateError);
      });

      test('delete() throws without executor', () async {
        final qs = QuerySet<Map<String, dynamic>>();
        expect(() => qs.delete(), throwsStateError);
      });

      test('stream() throws without executor', () {
        final qs = QuerySet<Map<String, dynamic>>();
        expect(() => qs.stream(), throwsStateError);
      });

      test('aggregate() throws without executor', () async {
        final qs = QuerySet<Map<String, dynamic>>();
        expect(() => qs.aggregate({'total': Count.all()}), throwsStateError);
      });
    });

    group('values()', () {
      test('returns ValuesQuerySet with specified fields', () {
        final qs = QuerySet<Map<String, dynamic>>();
        final valuesQs = qs.values(['name', 'email']);

        expect(valuesQs, isA<ValuesQuerySet<Map<String, dynamic>>>());
        expect(valuesQs.fields, equals(['name', 'email']));
        expect(valuesQs.config.only, equals(['name', 'email']));
      });

      test('preserves existing filters', () {
        final q = Q(const Comparison(ColumnRef('status'), ComparisonOp.eq, Value('active')));
        final qs = QuerySet<Map<String, dynamic>>().filter(q);
        final valuesQs = qs.values(['name']);

        expect(valuesQs.config.filters.length, equals(1));
      });
    });

    group('valuesFlat()', () {
      test('returns ValuesListQuerySet with specified field', () {
        final qs = QuerySet<Map<String, dynamic>>();
        final valuesQs = qs.valuesFlat<String>('name');

        expect(valuesQs, isA<ValuesListQuerySet<Map<String, dynamic>, String>>());
        expect(valuesQs.field, equals('name'));
        expect(valuesQs.config.only, equals(['name']));
      });

      test('preserves existing filters', () {
        final q = Q(const Comparison(ColumnRef('status'), ComparisonOp.eq, Value('active')));
        final qs = QuerySet<Map<String, dynamic>>().filter(q);
        final valuesQs = qs.valuesFlat<String>('name');

        expect(valuesQs.config.filters.length, equals(1));
      });
    });
  });

  group('ValuesQuerySet', () {
    test('filter() adds to filters list', () {
      final valuesQs = ValuesQuerySet<Map<String, dynamic>>(
        config: const QueryConfig(),
        executor: null,
        fields: ['name'],
      );
      final q = Q(const Comparison(ColumnRef('status'), ComparisonOp.eq, Value('active')));
      final filtered = valuesQs.filter(q);

      expect(filtered.config.filters.length, equals(1));
      expect(filtered.fields, equals(['name']));
    });

    test('exclude() adds to excludes list', () {
      final valuesQs = ValuesQuerySet<Map<String, dynamic>>(
        config: const QueryConfig(),
        executor: null,
        fields: ['name'],
      );
      final q = Q(const Comparison(ColumnRef('status'), ComparisonOp.eq, Value('deleted')));
      final excluded = valuesQs.exclude(q);

      expect(excluded.config.excludes.length, equals(1));
    });

    test('orderBy() sets ordering', () {
      final valuesQs = ValuesQuerySet<Map<String, dynamic>>(
        config: const QueryConfig(),
        executor: null,
        fields: ['name'],
      );
      final ordered = valuesQs.orderBy(const OrderBy(ColumnRef('name')));

      expect(ordered.config.ordering.length, equals(1));
    });

    test('limit() sets limit', () {
      final valuesQs = ValuesQuerySet<Map<String, dynamic>>(
        config: const QueryConfig(),
        executor: null,
        fields: ['name'],
      );
      final limited = valuesQs.limit(10);

      expect(limited.config.limit, equals(10));
    });

    test('offset() sets offset', () {
      final valuesQs = ValuesQuerySet<Map<String, dynamic>>(
        config: const QueryConfig(),
        executor: null,
        fields: ['name'],
      );
      final offsetted = valuesQs.offset(5);

      expect(offsetted.config.offset, equals(5));
    });

    test('distinct() sets distinct flag', () {
      final valuesQs = ValuesQuerySet<Map<String, dynamic>>(
        config: const QueryConfig(),
        executor: null,
        fields: ['name'],
      );
      final distinctQs = valuesQs.distinct();

      expect(distinctQs.config.distinct, isTrue);
    });

    test('toList() throws without executor', () {
      final valuesQs = ValuesQuerySet<Map<String, dynamic>>(
        config: const QueryConfig(),
        executor: null,
        fields: ['name'],
      );
      expect(() => valuesQs.toList(), throwsStateError);
    });

    test('first() throws without executor', () {
      final valuesQs = ValuesQuerySet<Map<String, dynamic>>(
        config: const QueryConfig(),
        executor: null,
        fields: ['name'],
      );
      expect(() => valuesQs.first(), throwsStateError);
    });

    test('toString() includes type and fields', () {
      final valuesQs = ValuesQuerySet<Map<String, dynamic>>(
        config: const QueryConfig(),
        executor: null,
        fields: ['name', 'email'],
      );
      final str = valuesQs.toString();
      expect(str, contains('ValuesQuerySet'));
      expect(str, contains('name'));
      expect(str, contains('email'));
    });
  });

  group('ValuesListQuerySet', () {
    test('filter() adds to filters list', () {
      final valuesQs = ValuesListQuerySet<Map<String, dynamic>, String>(
        config: const QueryConfig(),
        executor: null,
        field: 'name',
      );
      final q = Q(const Comparison(ColumnRef('status'), ComparisonOp.eq, Value('active')));
      final filtered = valuesQs.filter(q);

      expect(filtered.config.filters.length, equals(1));
      expect(filtered.field, equals('name'));
    });

    test('exclude() adds to excludes list', () {
      final valuesQs = ValuesListQuerySet<Map<String, dynamic>, String>(
        config: const QueryConfig(),
        executor: null,
        field: 'name',
      );
      final q = Q(const Comparison(ColumnRef('status'), ComparisonOp.eq, Value('deleted')));
      final excluded = valuesQs.exclude(q);

      expect(excluded.config.excludes.length, equals(1));
    });

    test('orderBy() sets ordering', () {
      final valuesQs = ValuesListQuerySet<Map<String, dynamic>, String>(
        config: const QueryConfig(),
        executor: null,
        field: 'name',
      );
      final ordered = valuesQs.orderBy(const OrderBy(ColumnRef('name')));

      expect(ordered.config.ordering.length, equals(1));
    });

    test('limit() sets limit', () {
      final valuesQs = ValuesListQuerySet<Map<String, dynamic>, String>(
        config: const QueryConfig(),
        executor: null,
        field: 'name',
      );
      final limited = valuesQs.limit(10);

      expect(limited.config.limit, equals(10));
    });

    test('offset() sets offset', () {
      final valuesQs = ValuesListQuerySet<Map<String, dynamic>, String>(
        config: const QueryConfig(),
        executor: null,
        field: 'name',
      );
      final offsetted = valuesQs.offset(5);

      expect(offsetted.config.offset, equals(5));
    });

    test('distinct() sets distinct flag', () {
      final valuesQs = ValuesListQuerySet<Map<String, dynamic>, String>(
        config: const QueryConfig(),
        executor: null,
        field: 'name',
      );
      final distinctQs = valuesQs.distinct();

      expect(distinctQs.config.distinct, isTrue);
    });

    test('toList() throws without executor', () {
      final valuesQs = ValuesListQuerySet<Map<String, dynamic>, String>(
        config: const QueryConfig(),
        executor: null,
        field: 'name',
      );
      expect(() => valuesQs.toList(), throwsStateError);
    });

    test('first() throws without executor', () {
      final valuesQs = ValuesListQuerySet<Map<String, dynamic>, String>(
        config: const QueryConfig(),
        executor: null,
        field: 'name',
      );
      expect(() => valuesQs.first(), throwsStateError);
    });

    test('toString() includes type and field', () {
      final valuesQs = ValuesListQuerySet<Map<String, dynamic>, String>(
        config: const QueryConfig(),
        executor: null,
        field: 'name',
      );
      final str = valuesQs.toString();
      expect(str, contains('ValuesListQuerySet'));
      expect(str, contains('name'));
    });
  });

  group('QueryConfig', () {
    test('default constructor has empty defaults', () {
      const config = QueryConfig();
      expect(config.filters, isEmpty);
      expect(config.excludes, isEmpty);
      expect(config.ordering, isEmpty);
      expect(config.limit, isNull);
      expect(config.offset, isNull);
      expect(config.selectRelated, isEmpty);
      expect(config.prefetchRelated, isEmpty);
      expect(config.only, isEmpty);
      expect(config.defer, isEmpty);
      expect(config.distinct, isFalse);
      expect(config.annotations, isEmpty);
    });

    test('copyWith preserves unmodified values', () {
      final q = Q(const Comparison(ColumnRef('a'), ComparisonOp.eq, Value(1)));
      final config = QueryConfig(filters: [q], limit: 10, distinct: true);

      final copied = config.copyWith(offset: 5);

      expect(copied.filters, equals([q]));
      expect(copied.limit, equals(10));
      expect(copied.distinct, isTrue);
      expect(copied.offset, equals(5));
    });

    test('toString shows relevant parts', () {
      final q = Q(const Comparison(ColumnRef('a'), ComparisonOp.eq, Value(1)));
      final config = QueryConfig(filters: [q], limit: 10, distinct: true);

      final str = config.toString();
      expect(str, contains('filters'));
      expect(str, contains('limit: 10'));
      expect(str, contains('distinct: true'));
    });

    test('toString omits empty/null values', () {
      const config = QueryConfig();
      final str = config.toString();
      expect(str, equals('QueryConfig()'));
    });

    test('ctes defaults to empty list', () {
      const config = QueryConfig();
      expect(config.ctes, isEmpty);
    });

    test('fromCte defaults to null', () {
      const config = QueryConfig();
      expect(config.fromCte, isNull);
    });

    test('copyWith preserves ctes and fromCte', () {
      final cte = Cte('test_cte', _TestCteQuery());
      final config = QueryConfig(ctes: [cte], fromCte: 'test_cte');

      final copied = config.copyWith(limit: 10);

      expect(copied.ctes, equals([cte]));
      expect(copied.fromCte, equals('test_cte'));
    });

    test('toString shows ctes and fromCte', () {
      final cte = Cte('test_cte', _TestCteQuery());
      final config = QueryConfig(ctes: [cte], fromCte: 'test_cte');

      final str = config.toString();
      expect(str, contains('ctes'));
      expect(str, contains('fromCte: test_cte'));
    });
  });

  group('QuerySet CTE methods', () {
    test('with_() adds CTEs to config', () {
      final cte = Cte('test_cte', _TestCteQuery());
      final qs = QuerySet<Map<String, dynamic>>().with_([cte]);

      expect(qs.config.ctes.length, equals(1));
      expect(qs.config.ctes.first, equals(cte));
    });

    test('with_() can add multiple CTEs', () {
      final cte1 = Cte('cte1', _TestCteQuery());
      final cte2 = Cte('cte2', _TestCteQuery());
      final qs = QuerySet<Map<String, dynamic>>().with_([cte1, cte2]);

      expect(qs.config.ctes.length, equals(2));
    });

    test('with_() can be chained to add more CTEs', () {
      final cte1 = Cte('cte1', _TestCteQuery());
      final cte2 = Cte('cte2', _TestCteQuery());
      final qs = QuerySet<Map<String, dynamic>>().with_([cte1]).with_([cte2]);

      expect(qs.config.ctes.length, equals(2));
    });

    test('fromCte() sets fromCte in config using Cte', () {
      final cte = Cte('my_cte', _TestCteQuery());
      final qs = QuerySet<Map<String, dynamic>>().fromCte(cte);

      expect(qs.config.fromCte, equals('my_cte'));
    });

    test('fromCte() sets fromCte in config using RecursiveCte', () {
      final recursiveCte = RecursiveCte<Map<String, dynamic>>(
        'tree',
        base: _TestCteQuery(),
        recursive: (cte) => _TestCteQuery(),
      );
      final qs = QuerySet<Map<String, dynamic>>().fromCte(recursiveCte);

      expect(qs.config.fromCte, equals('tree'));
    });

    test('fromCte() throws for invalid type', () {
      final qs = QuerySet<Map<String, dynamic>>();
      expect(() => qs.fromCte('invalid'), throwsArgumentError);
    });

    test('with_() and fromCte() can be chained', () {
      final cte = Cte('active_users', _TestCteQuery());
      final qs = QuerySet<Map<String, dynamic>>()
          .with_([cte])
          .fromCte(cte)
          .filter(Q(const Comparison(ColumnRef('status'), ComparisonOp.eq, Value('active'))));

      expect(qs.config.ctes.length, equals(1));
      expect(qs.config.fromCte, equals('active_users'));
      expect(qs.config.filters.length, equals(1));
    });

    test('QuerySet implements CteQuery', () {
      final qs = QuerySet<Map<String, dynamic>>(tableName: 'users');
      expect(qs, isA<CteQuery<Map<String, dynamic>>>());
    });

    test('QuerySet.cteConfig returns correct config', () {
      final q = Q(const Comparison(ColumnRef('status'), ComparisonOp.eq, Value('active')));
      final qs = QuerySet<Map<String, dynamic>>(
        tableName: 'users',
        config: QueryConfig(filters: [q], distinct: true, limit: 10, only: ['id', 'name']),
      );

      final cteConfig = qs.cteConfig;
      expect(cteConfig.tableName, equals('users'));
      expect(cteConfig.filters.length, equals(1));
      expect(cteConfig.distinct, isTrue);
      expect(cteConfig.limit, equals(10));
      expect(cteConfig.only, equals(['id', 'name']));
    });
  });
}

class _TestCteQuery implements CteQuery<Map<String, dynamic>> {
  @override
  CteQueryConfig get cteConfig => const CteQueryConfig(tableName: 'test_table');
}
