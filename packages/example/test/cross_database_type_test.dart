import 'package:jao_example/models/models.dart';
import 'package:test/test.dart';

/// Tests for cross-database type compatibility.
///
/// The generated fromRow() code should handle values from ANY database:
/// - PostgreSQL returns DateTime objects, bool values
/// - SQLite returns String timestamps, int (0/1) for booleans
///
/// See: https://github.com/nexlabstudio/jao/issues/4
void main() {
  group('Poll.fromRow - @DateTimeField', () {
    test('should work with SQLite (String timestamp)', () {
      final row = {
        'id': 1,
        'question': 'What is your favorite color?',
        'pub_date': '2024-01-15T10:30:00.000',
      };

      final poll = Polls.fromRow(row);

      expect(poll.id, equals(1));
      expect(poll.question, equals('What is your favorite color?'));
      expect(poll.pubDate, equals(DateTime(2024, 1, 15, 10, 30, 0)));
    });

    test('should work with PostgreSQL (DateTime object)', () {
      final row = {
        'id': 1,
        'question': 'What is your favorite color?',
        'pub_date': DateTime(2024, 1, 15, 10, 30, 0),
      };

      final poll = Polls.fromRow(row);

      expect(poll.id, equals(1));
      expect(poll.question, equals('What is your favorite color?'));
      expect(poll.pubDate, equals(DateTime(2024, 1, 15, 10, 30, 0)));
    });
  });

  group('Choice.fromRow - @IntegerField', () {
    test('should work with int value', () {
      final row = {
        'id': 1,
        'poll_id': 1,
        'choice_text': 'Blue',
        'votes': 42,
      };

      final choice = Choices.fromRow(row);

      expect(choice.id, equals(1));
      expect(choice.votes, equals(42));
    });

    test('should work with double value (some drivers return double for numeric)', () {
      final row = {
        'id': 1,
        'poll_id': 1,
        'choice_text': 'Blue',
        'votes': 42.0,
      };

      final choice = Choices.fromRow(row);

      expect(choice.id, equals(1));
      expect(choice.votes, equals(42));
    });

    test('should work with String value (some drivers)', () {
      final row = {
        'id': 1,
        'poll_id': 1,
        'choice_text': 'Blue',
        'votes': '42',
      };

      final choice = Choices.fromRow(row);

      expect(choice.id, equals(1));
      expect(choice.votes, equals(42));
    });
  });
}
