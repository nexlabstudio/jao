/// Dartonic CLI library.
///
/// Provides the migration runner and CLI for managing dartonic migrations.
///
/// ## Usage
///
/// Create a `bin/migrate.dart` file in your project:
///
/// ```dart
/// import 'package:dartonic/dartonic.dart';
/// import 'package:dartonic_cli/dartonic_cli.dart';
/// import '../lib/migrations/migrations.dart';
///
/// void main(List<String> args) async {
///   final config = MigrationRunnerConfig.fromEnvironment(
///     migrations: allMigrations,
///   );
///
///   final cli = DartonicCli(config);
///   final exitCode = await cli.run(args);
///   exit(exitCode);
/// }
/// ```
///
/// Then run with:
/// ```bash
/// dart run bin/migrate.dart migrate
/// dart run bin/migrate.dart status
/// dart run bin/migrate.dart rollback
/// ```
library dartonic_cli;

export 'src/runner.dart';
