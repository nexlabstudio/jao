import 'package:jao/jao.dart';
import 'package:test/test.dart';

void main() {
  group('IntFieldRef', () {
    const field = IntFieldRef('age');

    test('eq returns Q with Comparison', () {
      final q = field.eq(18);
      expect(q, isA<Q>());
      expect(q.expression, isA<Comparison>());
      final comp = q.expression as Comparison;
      expect(comp.op, equals(ComparisonOp.eq));
    });

    test('ne returns Q with Comparison', () {
      final q = field.ne(0);
      final comp = q.expression as Comparison;
      expect(comp.op, equals(ComparisonOp.ne));
    });

    test('gt returns Q with Comparison', () {
      final q = field.gt(18);
      final comp = q.expression as Comparison;
      expect(comp.op, equals(ComparisonOp.gt));
    });

    test('gte returns Q with Comparison', () {
      final q = field.gte(18);
      final comp = q.expression as Comparison;
      expect(comp.op, equals(ComparisonOp.gte));
    });

    test('lt returns Q with Comparison', () {
      final q = field.lt(65);
      final comp = q.expression as Comparison;
      expect(comp.op, equals(ComparisonOp.lt));
    });

    test('lte returns Q with Comparison', () {
      final q = field.lte(65);
      final comp = q.expression as Comparison;
      expect(comp.op, equals(ComparisonOp.lte));
    });

    test('between returns Q with BooleanExpr (AND of gte and lte)', () {
      final q = field.between(18, 65);
      expect(q.expression, isA<BooleanExpr>());
      final boolExpr = q.expression as BooleanExpr;
      expect(boolExpr.op, equals(BooleanOp.and));
    });

    test('inList returns Q with Comparison', () {
      final q = field.inList([18, 21, 25, 30]);
      final comp = q.expression as Comparison;
      expect(comp.op, equals(ComparisonOp.inList));
    });

    test('isNull returns Q with Comparison', () {
      final q = field.isNull();
      final comp = q.expression as Comparison;
      expect(comp.op, equals(ComparisonOp.isNull));
    });

    test('isNotNull returns Q with Comparison', () {
      final q = field.isNotNull();
      final comp = q.expression as Comparison;
      expect(comp.op, equals(ComparisonOp.isNotNull));
    });

    test('asc returns OrderBy ascending', () {
      final order = field.asc();
      expect(order.ascending, isTrue);
    });

    test('desc returns OrderBy descending', () {
      final order = field.desc();
      expect(order.ascending, isFalse);
    });

    test('col returns ColumnRef', () {
      final col = field.col;
      expect(col, isA<ColumnRef>());
      expect(col.column, equals('age'));
    });

    test('arithmetic add', () {
      final expr = field + 10;
      expect(expr, isA<ArithmeticExpr>());
      expect(expr.op, equals(ArithmeticOp.add));
    });

    test('arithmetic subtract', () {
      final expr = field - 5;
      expect(expr, isA<ArithmeticExpr>());
      expect(expr.op, equals(ArithmeticOp.subtract));
    });

    test('arithmetic multiply', () {
      final expr = field * 2;
      expect(expr, isA<ArithmeticExpr>());
      expect(expr.op, equals(ArithmeticOp.multiply));
    });

    test('arithmetic divide', () {
      final expr = field / 10;
      expect(expr, isA<ArithmeticExpr>());
      expect(expr.op, equals(ArithmeticOp.divide));
    });

    test('arithmetic modulo', () {
      final expr = field % 7;
      expect(expr, isA<ArithmeticExpr>());
      expect(expr.op, equals(ArithmeticOp.modulo));
    });
  });

  group('DoubleFieldRef', () {
    const field = DoubleFieldRef('price');

    test('eq returns Q with Comparison', () {
      final q = field.eq(19.99);
      final comp = q.expression as Comparison;
      expect(comp.op, equals(ComparisonOp.eq));
    });

    test('between returns Q with BooleanExpr', () {
      final q = field.between(10.0, 100.0);
      expect(q.expression, isA<BooleanExpr>());
    });

    test('gt returns Q with Comparison', () {
      final q = field.gt(0.0);
      final comp = q.expression as Comparison;
      expect(comp.op, equals(ComparisonOp.gt));
    });

    test('arithmetic operations work', () {
      final add = field + 1.5;
      final sub = field - 0.5;
      final mul = field * 1.1;
      final div = field / 2;

      expect(add, isA<ArithmeticExpr>());
      expect(sub, isA<ArithmeticExpr>());
      expect(mul, isA<ArithmeticExpr>());
      expect(div, isA<ArithmeticExpr>());
    });
  });

  group('StringFieldRef', () {
    const field = StringFieldRef('name');

    test('eq returns Q with Comparison', () {
      final q = field.eq('John');
      final comp = q.expression as Comparison;
      expect(comp.op, equals(ComparisonOp.eq));
    });

    test('contains returns Q with LIKE %value%', () {
      final q = field.contains('John');
      final comp = q.expression as Comparison;
      expect(comp.op, equals(ComparisonOp.like));
      final value = comp.right as Value;
      expect(value.value, equals('%John%'));
    });

    test('iContains returns Q with ILIKE %value%', () {
      final q = field.iContains('john');
      final comp = q.expression as Comparison;
      expect(comp.op, equals(ComparisonOp.ilike));
      final value = comp.right as Value;
      expect(value.value, equals('%john%'));
    });

    test('startsWith returns Q with LIKE value%', () {
      final q = field.startsWith('Dr.');
      final comp = q.expression as Comparison;
      expect(comp.op, equals(ComparisonOp.like));
      final value = comp.right as Value;
      expect(value.value, equals('Dr.%'));
    });

    test('iStartsWith returns Q with ILIKE value%', () {
      final q = field.iStartsWith('dr.');
      final comp = q.expression as Comparison;
      expect(comp.op, equals(ComparisonOp.ilike));
      final value = comp.right as Value;
      expect(value.value, equals('dr.%'));
    });

    test('endsWith returns Q with LIKE %value', () {
      final q = field.endsWith('Jr.');
      final comp = q.expression as Comparison;
      expect(comp.op, equals(ComparisonOp.like));
      final value = comp.right as Value;
      expect(value.value, equals('%Jr.'));
    });

    test('iEndsWith returns Q with ILIKE %value', () {
      final q = field.iEndsWith('jr.');
      final comp = q.expression as Comparison;
      expect(comp.op, equals(ComparisonOp.ilike));
      final value = comp.right as Value;
      expect(value.value, equals('%jr.'));
    });

    test('iEq returns Q with ILIKE for case-insensitive exact match', () {
      final q = field.iEq('john');
      final comp = q.expression as Comparison;
      expect(comp.op, equals(ComparisonOp.ilike));
      final value = comp.right as Value;
      expect(value.value, equals('john'));
    });

    test('regex returns Q with REGEXP', () {
      final q = field.regex(r'^[A-Z].*');
      expect(q.expression, isA<Comparison>());
    });

    test('inList works with strings', () {
      final q = field.inList(['John', 'Jane', 'Bob']);
      final comp = q.expression as Comparison;
      expect(comp.op, equals(ComparisonOp.inList));
    });

    test('isNull works', () {
      final q = field.isNull();
      final comp = q.expression as Comparison;
      expect(comp.op, equals(ComparisonOp.isNull));
    });

    test('isNotNull works', () {
      final q = field.isNotNull();
      final comp = q.expression as Comparison;
      expect(comp.op, equals(ComparisonOp.isNotNull));
    });
  });

  group('BoolFieldRef', () {
    const field = BoolFieldRef('is_active');

    test('eq returns Q with Comparison', () {
      final q = field.eq(true);
      final comp = q.expression as Comparison;
      expect(comp.op, equals(ComparisonOp.eq));
    });

    test('isTrue returns eq(true)', () {
      final q = field.isTrue();
      final comp = q.expression as Comparison;
      expect(comp.op, equals(ComparisonOp.eq));
      final value = comp.right as Value;
      expect(value.value, equals(true));
    });

    test('isFalse returns eq(false)', () {
      final q = field.isFalse();
      final comp = q.expression as Comparison;
      expect(comp.op, equals(ComparisonOp.eq));
      final value = comp.right as Value;
      expect(value.value, equals(false));
    });

    test('isNull works', () {
      final q = field.isNull();
      final comp = q.expression as Comparison;
      expect(comp.op, equals(ComparisonOp.isNull));
    });
  });

  group('DateTimeFieldRef', () {
    const field = DateTimeFieldRef('created_at');
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    test('eq returns Q with Comparison', () {
      final q = field.eq(now);
      final comp = q.expression as Comparison;
      expect(comp.op, equals(ComparisonOp.eq));
    });

    test('gte returns Q with Comparison', () {
      final q = field.gte(yesterday);
      final comp = q.expression as Comparison;
      expect(comp.op, equals(ComparisonOp.gte));
    });

    test('lte returns Q with Comparison', () {
      final q = field.lte(now);
      final comp = q.expression as Comparison;
      expect(comp.op, equals(ComparisonOp.lte));
    });

    test('between returns Q with BooleanExpr', () {
      final q = field.between(yesterday, now);
      expect(q.expression, isA<BooleanExpr>());
    });

    test('year returns Q with EXTRACT', () {
      final q = field.year(2024);
      expect(q.expression, isA<Comparison>());
      final comp = q.expression as Comparison;
      expect(comp.left, isA<FunctionCall>());
    });

    test('month returns Q with EXTRACT', () {
      final q = field.month(12);
      expect(q.expression, isA<Comparison>());
      final comp = q.expression as Comparison;
      expect(comp.left, isA<FunctionCall>());
    });

    test('day returns Q with EXTRACT', () {
      final q = field.day(25);
      expect(q.expression, isA<Comparison>());
      final comp = q.expression as Comparison;
      expect(comp.left, isA<FunctionCall>());
    });

    test('date returns Q with DATE function', () {
      final q = field.date(now);
      expect(q.expression, isA<Comparison>());
      final comp = q.expression as Comparison;
      expect(comp.left, isA<FunctionCall>());
    });

    test('asc returns OrderBy ascending', () {
      final order = field.asc();
      expect(order.ascending, isTrue);
    });

    test('desc returns OrderBy descending', () {
      final order = field.desc();
      expect(order.ascending, isFalse);
    });
  });

  group('DurationFieldRef', () {
    const field = DurationFieldRef('duration');
    final oneHour = const Duration(hours: 1);
    final twoHours = const Duration(hours: 2);

    test('eq returns Q with Comparison', () {
      final q = field.eq(oneHour);
      final comp = q.expression as Comparison;
      expect(comp.op, equals(ComparisonOp.eq));
    });

    test('gte returns Q with Comparison', () {
      final q = field.gte(oneHour);
      final comp = q.expression as Comparison;
      expect(comp.op, equals(ComparisonOp.gte));
    });

    test('between returns Q with BooleanExpr', () {
      final q = field.between(oneHour, twoHours);
      expect(q.expression, isA<BooleanExpr>());
    });
  });

  group('FieldRef with table', () {
    const field = IntFieldRef('id', table: 'users');

    test('col includes table', () {
      final col = field.col;
      expect(col.table, equals('users'));
      expect(col.column, equals('id'));
    });

    test('toString includes table', () {
      final col = field.col;
      expect(col.toString(), equals('users.id'));
    });
  });

  group('F expression comparison', () {
    const ageField = IntFieldRef('age');
    const minAgeField = IntFieldRef('min_age');

    test('eqField compares two fields', () {
      final q = ageField.eqField(minAgeField);
      expect(q.expression, isA<Comparison>());
      final comp = q.expression as Comparison;
      expect(comp.op, equals(ComparisonOp.eq));
      expect(comp.left, isA<ColumnRef>());
      expect(comp.right, isA<ColumnRef>());
    });

    test('eqF compares with F expression', () {
      const f = F('min_age');
      final q = ageField.eqF(f);
      expect(q.expression, isA<Comparison>());
      final comp = q.expression as Comparison;
      expect(comp.op, equals(ComparisonOp.eq));
      expect(comp.right, isA<F>());
    });

    test('ltField compares less than another field', () {
      final q = ageField.ltField(minAgeField);
      final comp = q.expression as Comparison;
      expect(comp.op, equals(ComparisonOp.lt));
    });

    test('ltF compares with F expression', () {
      const f = F('max_age');
      final q = ageField.ltF(f);
      final comp = q.expression as Comparison;
      expect(comp.op, equals(ComparisonOp.lt));
    });

    test('lteF compares with F expression', () {
      const f = F('max_age');
      final q = ageField.lteF(f);
      final comp = q.expression as Comparison;
      expect(comp.op, equals(ComparisonOp.lte));
    });

    test('gtF compares with F expression', () {
      const f = F('min_age');
      final q = ageField.gtF(f);
      final comp = q.expression as Comparison;
      expect(comp.op, equals(ComparisonOp.gt));
    });

    test('gteF compares with F expression', () {
      const f = F('min_age');
      final q = ageField.gteF(f);
      final comp = q.expression as Comparison;
      expect(comp.op, equals(ComparisonOp.gte));
    });
  });

  group('FieldRef toString', () {
    test('shows type and name', () {
      const field = IntFieldRef('age');
      expect(field.toString(), contains('age'));
      expect(field.toString(), contains('int'));
    });
  });
}
