import 'package:jao/jao.dart';
import 'package:test/test.dart';

void main() {
  group('ColumnRef', () {
    test('stores column name', () {
      const col = ColumnRef('name');
      expect(col.column, equals('name'));
      expect(col.table, equals(''));
    });

    test('stores table and column', () {
      const col = ColumnRef('name', table: 'users');
      expect(col.column, equals('name'));
      expect(col.table, equals('users'));
    });

    test('toString without table', () {
      const col = ColumnRef('name');
      expect(col.toString(), equals('name'));
    });

    test('toString with table', () {
      const col = ColumnRef('name', table: 'users');
      expect(col.toString(), equals('users.name'));
    });
  });

  group('Value', () {
    test('wraps int', () {
      const val = Value(42);
      expect(val.value, equals(42));
    });

    test('wraps String', () {
      const val = Value('hello');
      expect(val.value, equals('hello'));
    });

    test('wraps double', () {
      const val = Value(3.14);
      expect(val.value, equals(3.14));
    });

    test('wraps bool', () {
      const val = Value(true);
      expect(val.value, equals(true));
    });

    test('handles null', () {
      const val = Value(null);
      expect(val.value, isNull);
    });

    test('wraps DateTime', () {
      final now = DateTime.now();
      final val = Value(now);
      expect(val.value, equals(now));
    });

    test('wraps List', () {
      const val = Value([1, 2, 3]);
      expect(val.value, equals([1, 2, 3]));
    });

    test('toString shows value', () {
      const val = Value(42);
      expect(val.toString(), equals('Value(42)'));
    });
  });

  group('Comparison', () {
    const left = ColumnRef('age');
    const right = Value(18);

    test('creates eq expression', () {
      const comp = Comparison(left, ComparisonOp.eq, right);
      expect(comp.left, equals(left));
      expect(comp.op, equals(ComparisonOp.eq));
      expect(comp.right, equals(right));
    });

    test('creates ne expression', () {
      const comp = Comparison(left, ComparisonOp.ne, right);
      expect(comp.op, equals(ComparisonOp.ne));
    });

    test('creates gt expression', () {
      const comp = Comparison(left, ComparisonOp.gt, right);
      expect(comp.op, equals(ComparisonOp.gt));
    });

    test('creates gte expression', () {
      const comp = Comparison(left, ComparisonOp.gte, right);
      expect(comp.op, equals(ComparisonOp.gte));
    });

    test('creates lt expression', () {
      const comp = Comparison(left, ComparisonOp.lt, right);
      expect(comp.op, equals(ComparisonOp.lt));
    });

    test('creates lte expression', () {
      const comp = Comparison(left, ComparisonOp.lte, right);
      expect(comp.op, equals(ComparisonOp.lte));
    });

    test('creates like expression', () {
      const comp = Comparison(left, ComparisonOp.like, Value('%test%'));
      expect(comp.op, equals(ComparisonOp.like));
    });

    test('creates ilike expression', () {
      const comp = Comparison(left, ComparisonOp.ilike, Value('%test%'));
      expect(comp.op, equals(ComparisonOp.ilike));
    });

    test('creates inList expression', () {
      const comp = Comparison(left, ComparisonOp.inList, Value([1, 2, 3]));
      expect(comp.op, equals(ComparisonOp.inList));
    });

    test('creates isNull expression', () {
      const comp = Comparison(left, ComparisonOp.isNull, Value(null));
      expect(comp.op, equals(ComparisonOp.isNull));
    });

    test('creates isNotNull expression', () {
      const comp = Comparison(left, ComparisonOp.isNotNull, Value(null));
      expect(comp.op, equals(ComparisonOp.isNotNull));
    });

    test('creates between expression', () {
      const comp = Comparison(left, ComparisonOp.between, Value([10, 20]));
      expect(comp.op, equals(ComparisonOp.between));
    });

    test('toString shows comparison', () {
      const comp = Comparison(left, ComparisonOp.eq, right);
      expect(comp.toString(), contains('eq'));
    });
  });

  group('BooleanExpr', () {
    const left = Comparison(ColumnRef('age'), ComparisonOp.gte, Value(18));
    const right = Comparison(ColumnRef('active'), ComparisonOp.eq, Value(true));

    test('creates AND expression', () {
      const expr = BooleanExpr(left, BooleanOp.and, right);
      expect(expr.left, equals(left));
      expect(expr.op, equals(BooleanOp.and));
      expect(expr.right, equals(right));
    });

    test('creates OR expression', () {
      const expr = BooleanExpr(left, BooleanOp.or, right);
      expect(expr.op, equals(BooleanOp.or));
    });

    test('toString shows operation', () {
      const expr = BooleanExpr(left, BooleanOp.and, right);
      expect(expr.toString(), contains('and'));
    });
  });

  group('NotExpr', () {
    const inner = Comparison(ColumnRef('active'), ComparisonOp.eq, Value(true));

    test('wraps expression', () {
      const notExpr = NotExpr(inner);
      expect(notExpr.expr, equals(inner));
    });

    test('toString shows NOT', () {
      const notExpr = NotExpr(inner);
      expect(notExpr.toString(), startsWith('NOT('));
    });
  });

  group('ArithmeticExpr', () {
    const left = ColumnRef('price');
    const right = Value(10);

    test('creates add expression', () {
      const expr = ArithmeticExpr(left, ArithmeticOp.add, right);
      expect(expr.op, equals(ArithmeticOp.add));
      expect(expr.op.symbol, equals('+'));
    });

    test('creates subtract expression', () {
      const expr = ArithmeticExpr(left, ArithmeticOp.subtract, right);
      expect(expr.op, equals(ArithmeticOp.subtract));
      expect(expr.op.symbol, equals('-'));
    });

    test('creates multiply expression', () {
      const expr = ArithmeticExpr(left, ArithmeticOp.multiply, right);
      expect(expr.op, equals(ArithmeticOp.multiply));
      expect(expr.op.symbol, equals('*'));
    });

    test('creates divide expression', () {
      const expr = ArithmeticExpr(left, ArithmeticOp.divide, right);
      expect(expr.op, equals(ArithmeticOp.divide));
      expect(expr.op.symbol, equals('/'));
    });

    test('creates modulo expression', () {
      const expr = ArithmeticExpr(left, ArithmeticOp.modulo, right);
      expect(expr.op, equals(ArithmeticOp.modulo));
      expect(expr.op.symbol, equals('%'));
    });

    test('toString shows operation', () {
      const expr = ArithmeticExpr(left, ArithmeticOp.add, right);
      expect(expr.toString(), contains('+'));
    });
  });

  group('FunctionCall', () {
    test('creates function with args', () {
      const func = FunctionCall('COUNT', [ColumnRef('id')]);
      expect(func.name, equals('COUNT'));
      expect(func.args.length, equals(1));
      expect(func.distinct, isFalse);
    });

    test('creates function with distinct', () {
      const func = FunctionCall('COUNT', [ColumnRef('id')], distinct: true);
      expect(func.distinct, isTrue);
    });

    test('toString without distinct', () {
      const func = FunctionCall('SUM', [ColumnRef('amount')]);
      expect(func.toString(), equals('SUM(amount)'));
    });

    test('toString with distinct', () {
      const func = FunctionCall('COUNT', [ColumnRef('id')], distinct: true);
      expect(func.toString(), equals('COUNT(DISTINCT id)'));
    });

    test('handles multiple args', () {
      const func = FunctionCall('COALESCE', [ColumnRef('a'), ColumnRef('b'), Value(0)]);
      expect(func.args.length, equals(3));
    });
  });

  group('OrderBy', () {
    const col = ColumnRef('name');

    test('defaults to ascending', () {
      const order = OrderBy(col);
      expect(order.ascending, isTrue);
      expect(order.nulls, isNull);
    });

    test('can be descending', () {
      const order = OrderBy(col, ascending: false);
      expect(order.ascending, isFalse);
    });

    test('asc() returns ascending', () {
      const order = OrderBy(col, ascending: false);
      final asc = order.asc();
      expect(asc.ascending, isTrue);
    });

    test('desc() returns descending', () {
      const order = OrderBy(col);
      final desc = order.desc();
      expect(desc.ascending, isFalse);
    });

    test('nullsFirst() sets nulls position', () {
      const order = OrderBy(col);
      final nullsFirst = order.nullsFirst();
      expect(nullsFirst.nulls, equals(NullsPosition.first));
    });

    test('nullsLast() sets nulls position', () {
      const order = OrderBy(col);
      final nullsLast = order.nullsLast();
      expect(nullsLast.nulls, equals(NullsPosition.last));
    });

    test('chaining preserves direction', () {
      const order = OrderBy(col, ascending: false);
      final withNulls = order.nullsFirst();
      expect(withNulls.ascending, isFalse);
      expect(withNulls.nulls, equals(NullsPosition.first));
    });

    test('toString ascending', () {
      const order = OrderBy(col);
      expect(order.toString(), equals('name ASC'));
    });

    test('toString descending', () {
      const order = OrderBy(col, ascending: false);
      expect(order.toString(), equals('name DESC'));
    });

    test('toString with NULLS FIRST', () {
      final order = const OrderBy(col).nullsFirst();
      expect(order.toString(), equals('name ASC NULLS FIRST'));
    });

    test('toString with NULLS LAST', () {
      final order = const OrderBy(col, ascending: false).nullsLast();
      expect(order.toString(), equals('name DESC NULLS LAST'));
    });
  });

  group('F expression', () {
    test('stores field path', () {
      const f = F('author__name');
      expect(f.fieldPath, equals('author__name'));
    });

    test('arithmetic add', () {
      const f = F('price');
      final expr = f + 10;
      expect(expr, isA<ArithmeticExpr>());
      expect(expr.op, equals(ArithmeticOp.add));
    });

    test('arithmetic subtract', () {
      const f = F('price');
      final expr = f - 5;
      expect(expr, isA<ArithmeticExpr>());
      expect(expr.op, equals(ArithmeticOp.subtract));
    });

    test('arithmetic multiply', () {
      const f = F('quantity');
      final expr = f * 2;
      expect(expr, isA<ArithmeticExpr>());
      expect(expr.op, equals(ArithmeticOp.multiply));
    });

    test('arithmetic divide', () {
      const f = F('total');
      final expr = f / 100;
      expect(expr, isA<ArithmeticExpr>());
      expect(expr.op, equals(ArithmeticOp.divide));
    });

    test('arithmetic modulo', () {
      const f = F('count');
      final expr = f % 10;
      expect(expr, isA<ArithmeticExpr>());
      expect(expr.op, equals(ArithmeticOp.modulo));
    });

    test('toString shows field path', () {
      const f = F('author__name');
      expect(f.toString(), equals('F(author__name)'));
    });
  });

  group('Case expression', () {
    test('creates with single when', () {
      const when = When(Comparison(ColumnRef('status'), ComparisonOp.eq, Value('active')), Value(1));
      const caseExpr = Case([when]);
      expect(caseExpr.whens.length, equals(1));
      expect(caseExpr.elseResult, isNull);
    });

    test('creates with else', () {
      const when = When(Comparison(ColumnRef('status'), ComparisonOp.eq, Value('active')), Value(1));
      const caseExpr = Case([when], elseResult: Value(0));
      expect(caseExpr.elseResult, isNotNull);
    });

    test('creates with multiple whens', () {
      const when1 = When(Comparison(ColumnRef('status'), ComparisonOp.eq, Value('active')), Value(1));
      const when2 = When(Comparison(ColumnRef('status'), ComparisonOp.eq, Value('pending')), Value(2));
      const caseExpr = Case([when1, when2], elseResult: Value(0));
      expect(caseExpr.whens.length, equals(2));
    });

    test('toString without else', () {
      const when = When(Comparison(ColumnRef('status'), ComparisonOp.eq, Value('active')), Value(1));
      const caseExpr = Case([when]);
      expect(caseExpr.toString(), contains('CASE'));
      expect(caseExpr.toString(), contains('WHEN'));
      expect(caseExpr.toString(), contains('END'));
      expect(caseExpr.toString(), isNot(contains('ELSE')));
    });

    test('toString with else', () {
      const when = When(Comparison(ColumnRef('status'), ComparisonOp.eq, Value('active')), Value(1));
      const caseExpr = Case([when], elseResult: Value(0));
      expect(caseExpr.toString(), contains('ELSE'));
    });
  });

  group('When clause', () {
    test('stores condition and result', () {
      const condition = Comparison(ColumnRef('age'), ComparisonOp.gte, Value(18));
      const result = Value('adult');
      const when = When(condition, result);
      expect(when.condition, equals(condition));
      expect(when.then, equals(result));
    });

    test('toString shows WHEN THEN', () {
      const when = When(Comparison(ColumnRef('age'), ComparisonOp.gte, Value(18)), Value('adult'));
      expect(when.toString(), contains('WHEN'));
      expect(when.toString(), contains('THEN'));
    });
  });
}
