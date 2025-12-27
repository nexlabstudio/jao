import 'package:jao/jao.dart';
import 'package:test/test.dart';

void main() {
  group('Q', () {
    // Helper to create simple comparisons
    Q ageGte18() => Q(Comparison(ColumnRef('age'), ComparisonOp.gte, Value(18)));
    Q isActive() => Q(Comparison(ColumnRef('is_active'), ComparisonOp.eq, Value(true)));
    Q nameEqJohn() => Q(Comparison(ColumnRef('name'), ComparisonOp.eq, Value('John')));
    Q statusPending() => Q(Comparison(ColumnRef('status'), ComparisonOp.eq, Value('pending')));

    test('wraps boolean expression', () {
      final q = ageGte18();
      expect(q.expression, isA<Comparison>());
    });

    test('factory constructor works', () {
      const comp = Comparison(ColumnRef('age'), ComparisonOp.gte, Value(18));
      final q = Q.condition(comp);
      expect(q.expression, equals(comp));
    });

    group('AND operator (&)', () {
      test('Q & Q creates AND expression', () {
        final q1 = ageGte18();
        final q2 = isActive();
        final result = q1 & q2;

        expect(result.expression, isA<BooleanExpr>());
        final boolExpr = result.expression as BooleanExpr;
        expect(boolExpr.op, equals(BooleanOp.and));
      });

      test('Triple AND: A & B & C', () {
        final a = ageGte18();
        final b = isActive();
        final c = nameEqJohn();
        final result = a & b & c;

        expect(result.expression, isA<BooleanExpr>());
        final outer = result.expression as BooleanExpr;
        expect(outer.op, equals(BooleanOp.and));
        expect(outer.left, isA<BooleanExpr>());
      });
    });

    group('OR operator (|)', () {
      test('Q | Q creates OR expression', () {
        final q1 = ageGte18();
        final q2 = isActive();
        final result = q1 | q2;

        expect(result.expression, isA<BooleanExpr>());
        final boolExpr = result.expression as BooleanExpr;
        expect(boolExpr.op, equals(BooleanOp.or));
      });

      test('Triple OR: A | B | C', () {
        final a = ageGte18();
        final b = isActive();
        final c = nameEqJohn();
        final result = a | b | c;

        expect(result.expression, isA<BooleanExpr>());
        final outer = result.expression as BooleanExpr;
        expect(outer.op, equals(BooleanOp.or));
      });
    });

    group('NOT operator (~)', () {
      test('~Q creates NOT expression', () {
        final q = ageGte18();
        final result = ~q;

        expect(result.expression, isA<NotExpr>());
        final notExpr = result.expression as NotExpr;
        expect(notExpr.expr, isA<Comparison>());
      });

      test('double negation ~~Q', () {
        final q = ageGte18();
        final result = ~~q;

        expect(result.expression, isA<NotExpr>());
        final outer = result.expression as NotExpr;
        expect(outer.expr, isA<NotExpr>());
      });
    });

    group('Complex nested conditions', () {
      test('(A & B) | C', () {
        final a = ageGte18();
        final b = isActive();
        final c = nameEqJohn();
        final result = (a & b) | c;

        expect(result.expression, isA<BooleanExpr>());
        final outer = result.expression as BooleanExpr;
        expect(outer.op, equals(BooleanOp.or));
        expect(outer.left, isA<BooleanExpr>());
        final inner = outer.left as BooleanExpr;
        expect(inner.op, equals(BooleanOp.and));
      });

      test('A & (B | C)', () {
        final a = ageGte18();
        final b = isActive();
        final c = nameEqJohn();
        final result = a & (b | c);

        expect(result.expression, isA<BooleanExpr>());
        final outer = result.expression as BooleanExpr;
        expect(outer.op, equals(BooleanOp.and));
        expect(outer.right, isA<BooleanExpr>());
        final inner = outer.right as BooleanExpr;
        expect(inner.op, equals(BooleanOp.or));
      });

      test('~(A & B)', () {
        final a = ageGte18();
        final b = isActive();
        final result = ~(a & b);

        expect(result.expression, isA<NotExpr>());
        final notExpr = result.expression as NotExpr;
        expect(notExpr.expr, isA<BooleanExpr>());
        final inner = notExpr.expr as BooleanExpr;
        expect(inner.op, equals(BooleanOp.and));
      });

      test('(A | B) & ~C', () {
        final a = ageGte18();
        final b = isActive();
        final c = nameEqJohn();
        final result = (a | b) & ~c;

        expect(result.expression, isA<BooleanExpr>());
        final outer = result.expression as BooleanExpr;
        expect(outer.op, equals(BooleanOp.and));
        expect(outer.left, isA<BooleanExpr>());
        expect(outer.right, isA<NotExpr>());
      });

      test('Mixed: (A & B) | (C & D)', () {
        final a = ageGte18();
        final b = isActive();
        final c = nameEqJohn();
        final d = statusPending();
        final result = (a & b) | (c & d);

        expect(result.expression, isA<BooleanExpr>());
        final outer = result.expression as BooleanExpr;
        expect(outer.op, equals(BooleanOp.or));
        expect(outer.left, isA<BooleanExpr>());
        expect(outer.right, isA<BooleanExpr>());

        final left = outer.left as BooleanExpr;
        final right = outer.right as BooleanExpr;
        expect(left.op, equals(BooleanOp.and));
        expect(right.op, equals(BooleanOp.and));
      });

      test('Deeply nested conditions (4+ levels)', () {
        final a = ageGte18();
        final b = isActive();
        final c = nameEqJohn();
        final d = statusPending();

        // ((A & B) | C) & ~D
        final level1 = a & b;
        final level2 = level1 | c;
        final level3 = level2 & ~d;

        expect(level3.expression, isA<BooleanExpr>());

        // Verify structure
        final outer = level3.expression as BooleanExpr;
        expect(outer.op, equals(BooleanOp.and));
        expect(outer.right, isA<NotExpr>());
        expect(outer.left, isA<BooleanExpr>());

        final orExpr = outer.left as BooleanExpr;
        expect(orExpr.op, equals(BooleanOp.or));
        expect(orExpr.left, isA<BooleanExpr>());

        final andExpr = orExpr.left as BooleanExpr;
        expect(andExpr.op, equals(BooleanOp.and));
      });

      test('~(A | B) & (C | ~D)', () {
        final a = ageGte18();
        final b = isActive();
        final c = nameEqJohn();
        final d = statusPending();

        final result = ~(a | b) & (c | ~d);

        expect(result.expression, isA<BooleanExpr>());
        final outer = result.expression as BooleanExpr;
        expect(outer.op, equals(BooleanOp.and));
        expect(outer.left, isA<NotExpr>());
        expect(outer.right, isA<BooleanExpr>());
      });
    });

    group('toString', () {
      test('shows Q wrapper', () {
        final q = ageGte18();
        expect(q.toString(), startsWith('Q('));
      });

      test('shows inner expression', () {
        final q = ageGte18();
        expect(q.toString(), contains('age'));
      });
    });
  });
}
