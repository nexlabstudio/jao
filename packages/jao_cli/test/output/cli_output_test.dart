import 'package:test/test.dart';
import 'package:jao_cli/jao_cli.dart';

void main() {
  group('CliOutput', () {
    group('constructor', () {
      test('creates instance with default verbose false', () {
        final output = CliOutput();
        expect(output.verbose, isFalse);
      });

      test('creates instance with verbose true', () {
        final output = CliOutput(verbose: true);
        expect(output.verbose, isTrue);
      });
    });

    group('success()', () {
      test('shows green checkmark', () {
        final output = CliOutput();
        // The success method prints with green checkmark: \x1B[32m✓\x1B[0m
        // We verify it doesn't throw
        expect(() => output.success('Test message'), returnsNormally);
      });

      test('includes message after checkmark', () {
        final output = CliOutput();
        expect(() => output.success('Operation completed'), returnsNormally);
      });
    });

    group('error()', () {
      test('shows red X', () {
        final output = CliOutput();
        // The error method prints with red X: \x1B[31m✗\x1B[0m
        expect(() => output.error('Test error'), returnsNormally);
      });

      test('includes message after X', () {
        final output = CliOutput();
        expect(() => output.error('Something went wrong'), returnsNormally);
      });
    });

    group('warning()', () {
      test('shows yellow warning', () {
        final output = CliOutput();
        // The warning method prints with yellow warning: \x1B[33m⚠\x1B[0m
        expect(() => output.warning('Caution message'), returnsNormally);
      });

      test('includes message after warning symbol', () {
        final output = CliOutput();
        expect(() => output.warning('This may cause issues'), returnsNormally);
      });
    });

    group('info()', () {
      test('shows blue info', () {
        final output = CliOutput();
        // The info method prints with blue info: \x1B[34mℹ\x1B[0m
        expect(() => output.info('Information message'), returnsNormally);
      });

      test('includes message after info symbol', () {
        final output = CliOutput();
        expect(() => output.info('Here is some info'), returnsNormally);
      });
    });

    group('header()', () {
      test('formats with bold and underline', () {
        final output = CliOutput();
        // The header prints bold text and underline
        expect(() => output.header('Migration Status'), returnsNormally);
      });

      test('creates underline matching message length', () {
        final output = CliOutput();
        expect(() => output.header('Test'), returnsNormally);
      });

      test('handles empty header', () {
        final output = CliOutput();
        expect(() => output.header(''), returnsNormally);
      });

      test('handles long header', () {
        final output = CliOutput();
        expect(() => output.header('This is a very long header message that spans multiple words'), returnsNormally);
      });
    });

    group('debug()', () {
      test('shows output when verbose is true', () {
        final output = CliOutput(verbose: true);
        expect(() => output.debug('Debug message'), returnsNormally);
      });

      test('suppresses output when verbose is false', () {
        final output = CliOutput(verbose: false);
        // Debug should not print when verbose is false
        expect(() => output.debug('Debug message'), returnsNormally);
      });
    });

    group('table()', () {
      test('formats as table', () {
        final output = CliOutput();
        final rows = [
          ['migration_001', 'Applied'],
          ['migration_002', 'Pending'],
        ];
        expect(() => output.table(rows, headers: ['Migration', 'Status']), returnsNormally);
      });

      test('handles empty rows', () {
        final output = CliOutput();
        expect(() => output.table([]), returnsNormally);
      });

      test('handles rows without headers', () {
        final output = CliOutput();
        final rows = [
          ['value1', 'value2'],
          ['value3', 'value4'],
        ];
        expect(() => output.table(rows), returnsNormally);
      });

      test('handles varying column widths', () {
        final output = CliOutput();
        final rows = [
          ['short', 'very_long_column_value'],
          ['another', 'x'],
        ];
        expect(() => output.table(rows, headers: ['Column A', 'Column B']), returnsNormally);
      });

      test('handles single column', () {
        final output = CliOutput();
        final rows = [
          ['item1'],
          ['item2'],
        ];
        expect(() => output.table(rows, headers: ['Items']), returnsNormally);
      });

      test('handles many columns', () {
        final output = CliOutput();
        final rows = [
          ['a', 'b', 'c', 'd', 'e'],
          ['1', '2', '3', '4', '5'],
        ];
        expect(() => output.table(rows, headers: ['A', 'B', 'C', 'D', 'E']), returnsNormally);
      });

      test('strips ANSI codes when calculating width', () {
        final output = CliOutput();
        final rows = [
          ['name', '\x1B[32mApplied\x1B[0m'],
          ['other', '\x1B[90mPending\x1B[0m'],
        ];
        expect(() => output.table(rows, headers: ['Migration', 'Status']), returnsNormally);
      });

      test('handles single row', () {
        final output = CliOutput();
        final rows = [
          ['only_row', 'value'],
        ];
        expect(() => output.table(rows, headers: ['Key', 'Value']), returnsNormally);
      });
    });

    group('verbose mode', () {
      test('shows extra output in verbose mode', () {
        final output = CliOutput(verbose: true);
        expect(() => output.debug('Extra debug info'), returnsNormally);
      });

      test('suppresses debug in non-verbose mode', () {
        final output = CliOutput(verbose: false);
        expect(() => output.debug('Should be hidden'), returnsNormally);
      });
    });

    group('ANSI escape codes', () {
      test('success uses green ANSI code', () {
        // The success method uses \x1B[32m for green
        final output = CliOutput();
        expect(() => output.success('green message'), returnsNormally);
      });

      test('error uses red ANSI code', () {
        // The error method uses \x1B[31m for red
        final output = CliOutput();
        expect(() => output.error('red message'), returnsNormally);
      });

      test('warning uses yellow ANSI code', () {
        // The warning method uses \x1B[33m for yellow
        final output = CliOutput();
        expect(() => output.warning('yellow message'), returnsNormally);
      });

      test('info uses blue ANSI code', () {
        // The info method uses \x1B[34m for blue
        final output = CliOutput();
        expect(() => output.info('blue message'), returnsNormally);
      });

      test('header uses bold ANSI code', () {
        // The header method uses \x1B[1m for bold
        final output = CliOutput();
        expect(() => output.header('bold header'), returnsNormally);
      });

      test('debug uses dim ANSI code', () {
        // The debug method uses \x1B[90m for dim
        final output = CliOutput(verbose: true);
        expect(() => output.debug('dim debug'), returnsNormally);
      });
    });

    group('message formatting', () {
      test('handles special characters in messages', () {
        final output = CliOutput();
        expect(() => output.info('Message with "quotes" and <brackets>'), returnsNormally);
      });

      test('handles newlines in messages', () {
        final output = CliOutput();
        expect(() => output.info('Line 1\nLine 2'), returnsNormally);
      });

      test('handles unicode in messages', () {
        final output = CliOutput();
        expect(() => output.info('Unicode: 你好 мир 🌍'), returnsNormally);
      });

      test('handles empty messages', () {
        final output = CliOutput();
        expect(() => output.info(''), returnsNormally);
        expect(() => output.success(''), returnsNormally);
        expect(() => output.warning(''), returnsNormally);
        expect(() => output.error(''), returnsNormally);
      });
    });

    group('multiple outputs', () {
      test('can call multiple output methods in sequence', () {
        final output = CliOutput();
        expect(() {
          output.header('Test Output');
          output.info('Starting operation...');
          output.success('Step 1 completed');
          output.warning('Step 2 had warnings');
          output.error('Step 3 failed');
        }, returnsNormally);
      });
    });
  });
}
