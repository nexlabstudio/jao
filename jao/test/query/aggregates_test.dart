import 'package:jao/jao.dart';
import 'package:test/test.dart';

void main() {
  group('Count', () {
    test('Count.all creates COUNT(*)', () {
      final count = Count.all();
      expect(count.name, equals('COUNT'));
      expect(count.args.length, equals(1));
      expect(count.args.first, isA<Value>());
      expect((count.args.first as Value).value, equals('*'));
    });

    test('Count with column creates COUNT(column)', () {
      final count = Count(const ColumnRef('name'));
      expect(count.name, equals('COUNT'));
      expect(count.args.length, equals(1));
      expect(count.args.first, isA<ColumnRef>());
    });

    test('Count with distinct creates COUNT(DISTINCT column)', () {
      final count = Count(const ColumnRef('status'), distinct: true);
      expect(count.name, equals('COUNT'));
      expect(count.distinct, isTrue);
      expect(count.args.length, equals(1));
    });
  });

  group('Sum', () {
    test('Sum creates SUM(column)', () {
      final sum = Sum(const ColumnRef('amount'));
      expect(sum.name, equals('SUM'));
      expect(sum.args.length, equals(1));
      expect(sum.args.first, isA<ColumnRef>());
    });
  });

  group('Avg', () {
    test('Avg creates AVG(column)', () {
      final avg = Avg(const ColumnRef('price'));
      expect(avg.name, equals('AVG'));
      expect(avg.args.length, equals(1));
    });
  });

  group('Min', () {
    test('Min creates MIN(column)', () {
      final min = Min(const ColumnRef('created_at'));
      expect(min.name, equals('MIN'));
      expect(min.args.length, equals(1));
    });
  });

  group('Max', () {
    test('Max creates MAX(column)', () {
      final max = Max(const ColumnRef('score'));
      expect(max.name, equals('MAX'));
      expect(max.args.length, equals(1));
    });
  });

  group('StdDev', () {
    test('StdDev creates STDDEV(column)', () {
      final stddev = StdDev(const ColumnRef('value'));
      expect(stddev.name, equals('STDDEV'));
      expect(stddev.args.length, equals(1));
    });
  });

  group('Variance', () {
    test('Variance creates VARIANCE(column)', () {
      final variance = Variance(const ColumnRef('value'));
      expect(variance.name, equals('VARIANCE'));
      expect(variance.args.length, equals(1));
    });
  });

  group('StringAgg', () {
    test('StringAgg creates STRING_AGG with default separator', () {
      final agg = StringAgg(const ColumnRef('name'));
      expect(agg.name, equals('STRING_AGG'));
      expect(agg.args.length, equals(2));
      expect((agg.args.last as Value).value, equals(','));
    });

    test('StringAgg creates STRING_AGG with custom separator', () {
      final agg = StringAgg(const ColumnRef('tag'), separator: ', ');
      expect(agg.args.length, equals(2));
      expect((agg.args.last as Value).value, equals(', '));
    });
  });

  group('ArrayAgg', () {
    test('ArrayAgg creates ARRAY_AGG', () {
      final agg = ArrayAgg(const ColumnRef('id'));
      expect(agg.name, equals('ARRAY_AGG'));
      expect(agg.distinct, isFalse);
    });

    test('ArrayAgg with distinct creates ARRAY_AGG(DISTINCT)', () {
      final agg = ArrayAgg(const ColumnRef('category'), distinct: true);
      expect(agg.distinct, isTrue);
    });
  });

  group('JsonAgg', () {
    test('JsonAgg creates JSON_AGG', () {
      final agg = JsonAgg(const ColumnRef('data'));
      expect(agg.name, equals('JSON_AGG'));
      expect(agg.args.length, equals(1));
    });
  });

  group('Coalesce', () {
    test('Coalesce creates COALESCE with multiple expressions', () {
      final coalesce = Coalesce([const ColumnRef('nickname'), const ColumnRef('name')]);
      expect(coalesce.name, equals('COALESCE'));
      expect(coalesce.args.length, equals(2));
    });

    test('Coalesce.withDefault creates COALESCE with default value', () {
      final coalesce = Coalesce.withDefault(const ColumnRef('bio'), 'No bio');
      expect(coalesce.name, equals('COALESCE'));
      expect(coalesce.args.length, equals(2));
      expect((coalesce.args.last as Value).value, equals('No bio'));
    });
  });

  group('NullIf', () {
    test('NullIf creates NULLIF with two expressions', () {
      final nullif = NullIf(const ColumnRef('status'), const Value('unknown'));
      expect(nullif.name, equals('NULLIF'));
      expect(nullif.args.length, equals(2));
    });
  });

  group('Greatest', () {
    test('Greatest creates GREATEST with multiple expressions', () {
      final greatest = Greatest([const ColumnRef('a'), const ColumnRef('b'), const ColumnRef('c')]);
      expect(greatest.name, equals('GREATEST'));
      expect(greatest.args.length, equals(3));
    });
  });

  group('Least', () {
    test('Least creates LEAST with multiple expressions', () {
      final least = Least([const ColumnRef('x'), const ColumnRef('y')]);
      expect(least.name, equals('LEAST'));
      expect(least.args.length, equals(2));
    });
  });

  group('String Functions', () {
    test('Length creates LENGTH(expr)', () {
      final length = Length(const ColumnRef('name'));
      expect(length.name, equals('LENGTH'));
    });

    test('Lower creates LOWER(expr)', () {
      final lower = Lower(const ColumnRef('email'));
      expect(lower.name, equals('LOWER'));
    });

    test('Upper creates UPPER(expr)', () {
      final upper = Upper(const ColumnRef('title'));
      expect(upper.name, equals('UPPER'));
    });

    test('Trim creates TRIM(expr)', () {
      final trim = Trim(const ColumnRef('content'));
      expect(trim.name, equals('TRIM'));
    });

    test('Substr creates SUBSTR(expr, start)', () {
      final substr = Substr(const ColumnRef('text'), 1);
      expect(substr.name, equals('SUBSTR'));
      expect(substr.args.length, equals(2));
    });

    test('Substr creates SUBSTR(expr, start, length)', () {
      final substr = Substr(const ColumnRef('text'), 1, 10);
      expect(substr.name, equals('SUBSTR'));
      expect(substr.args.length, equals(3));
    });

    test('Concat creates CONCAT with multiple expressions', () {
      final concat = Concat([const ColumnRef('first'), const Value(' '), const ColumnRef('last')]);
      expect(concat.name, equals('CONCAT'));
      expect(concat.args.length, equals(3));
    });

    test('Replace creates REPLACE(expr, from, to)', () {
      final replace = Replace(const ColumnRef('content'), 'old', 'new');
      expect(replace.name, equals('REPLACE'));
      expect(replace.args.length, equals(3));
    });
  });

  group('Date/Time Functions', () {
    test('CurrentDate creates CURRENT_DATE', () {
      final date = CurrentDate();
      expect(date.name, equals('CURRENT_DATE'));
      expect(date.args, isEmpty);
    });

    test('Now creates NOW()', () {
      final now = Now();
      expect(now.name, equals('NOW'));
      expect(now.args, isEmpty);
    });

    test('Extract creates EXTRACT(part FROM expr)', () {
      final extract = Extract('YEAR', const ColumnRef('created_at'));
      expect(extract.name, equals('EXTRACT'));
      expect(extract.args.length, equals(2));
    });

    test('Extract.year creates year extraction', () {
      final extract = Extract.year(const ColumnRef('date'));
      expect(extract.name, equals('EXTRACT'));
    });

    test('Extract.month creates month extraction', () {
      final extract = Extract.month(const ColumnRef('date'));
      expect(extract.name, equals('EXTRACT'));
    });

    test('Extract.day creates day extraction', () {
      final extract = Extract.day(const ColumnRef('date'));
      expect(extract.name, equals('EXTRACT'));
    });

    test('Extract.hour creates hour extraction', () {
      final extract = Extract.hour(const ColumnRef('timestamp'));
      expect(extract.name, equals('EXTRACT'));
    });

    test('Extract.minute creates minute extraction', () {
      final extract = Extract.minute(const ColumnRef('timestamp'));
      expect(extract.name, equals('EXTRACT'));
    });

    test('Extract.second creates second extraction', () {
      final extract = Extract.second(const ColumnRef('timestamp'));
      expect(extract.name, equals('EXTRACT'));
    });

    test('DateTrunc creates DATE_TRUNC(precision, expr)', () {
      final trunc = DateTrunc('month', const ColumnRef('created_at'));
      expect(trunc.name, equals('DATE_TRUNC'));
      expect(trunc.args.length, equals(2));
    });
  });

  group('Math Functions', () {
    test('Abs creates ABS(expr)', () {
      final abs = Abs(const ColumnRef('value'));
      expect(abs.name, equals('ABS'));
    });

    test('Round creates ROUND(expr)', () {
      final round = Round(const ColumnRef('price'));
      expect(round.name, equals('ROUND'));
      expect(round.args.length, equals(2));
    });

    test('Round creates ROUND(expr, places)', () {
      final round = Round(const ColumnRef('price'), 2);
      expect(round.args.length, equals(2));
      expect((round.args.last as Value).value, equals(2));
    });

    test('Floor creates FLOOR(expr)', () {
      final floor = Floor(const ColumnRef('value'));
      expect(floor.name, equals('FLOOR'));
    });

    test('Ceil creates CEIL(expr)', () {
      final ceil = Ceil(const ColumnRef('value'));
      expect(ceil.name, equals('CEIL'));
    });

    test('Power creates POWER(base, exp)', () {
      final power = Power(const ColumnRef('x'), const Value(2));
      expect(power.name, equals('POWER'));
      expect(power.args.length, equals(2));
    });

    test('Sqrt creates SQRT(expr)', () {
      final sqrt = Sqrt(const ColumnRef('value'));
      expect(sqrt.name, equals('SQRT'));
    });

    test('Ln creates LN(expr)', () {
      final ln = Ln(const ColumnRef('value'));
      expect(ln.name, equals('LN'));
    });

    test('Log creates LOG(expr)', () {
      final log = Log(const ColumnRef('value'));
      expect(log.name, equals('LOG'));
    });
  });

  group('Aggregate with alias', () {
    test('Aggregate can be used in Map with alias', () {
      final aggregates = <String, FunctionCall>{
        'total_count': Count.all(),
        'avg_price': Avg(const ColumnRef('price')),
        'max_score': Max(const ColumnRef('score')),
      };

      expect(aggregates['total_count'], isA<Count>());
      expect(aggregates['avg_price'], isA<Avg>());
      expect(aggregates['max_score'], isA<Max>());
    });
  });

  group('Multiple aggregates', () {
    test('Multiple aggregates can be combined', () {
      final aggregates = [
        Count.all(),
        Sum(const ColumnRef('amount')),
        Avg(const ColumnRef('price')),
        Min(const ColumnRef('created_at')),
        Max(const ColumnRef('updated_at')),
      ];

      expect(aggregates.length, equals(5));
      expect(aggregates[0], isA<Count>());
      expect(aggregates[1], isA<Sum>());
      expect(aggregates[2], isA<Avg>());
      expect(aggregates[3], isA<Min>());
      expect(aggregates[4], isA<Max>());
    });
  });

  group('Aggregate expression nesting', () {
    test('Can use arithmetic in aggregate', () {
      final sum = Sum(const ArithmeticExpr(ColumnRef('price'), ArithmeticOp.multiply, ColumnRef('quantity')));
      expect(sum.name, equals('SUM'));
      expect(sum.args.first, isA<ArithmeticExpr>());
    });

    test('Can use Coalesce in aggregate', () {
      final sum = Sum(Coalesce.withDefault(const ColumnRef('discount'), 0));
      expect(sum.args.first, isA<Coalesce>());
    });
  });
}
