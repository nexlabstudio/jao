#!/usr/bin/env dart

/// Migration CLI for the dartonic example project.
///
/// Usage:
///   dart run bin/migrate.dart <command> [options]
///
/// Commands:
///   makemigrations  Auto-detect model changes and create migration
///   migrate         Run pending migrations
///   rollback        Rollback migrations
///   status          Show migration status
///   reset           Rollback all migrations
///   refresh         Reset and re-run all migrations
///   sql             Show SQL for migrations
///   make            Generate an empty migration file
///   help            Show help
///
/// Examples:
///   dart run bin/migrate.dart makemigrations         # Auto-detect changes
///   dart run bin/migrate.dart makemigrations --empty -n=initial
///   dart run bin/migrate.dart migrate
///   dart run bin/migrate.dart status
///   dart run bin/migrate.dart rollback --step=2
///
/// Environment Variables:
///   DATABASE_URL      - Full connection URL (postgres://user:pass@host:port/db)
///   DATABASE_TYPE     - Database type: postgres, mysql, sqlite
///   DATABASE_HOST     - Database host
///   DATABASE_PORT     - Database port
///   DATABASE_NAME     - Database name or path (for SQLite)
///   DATABASE_USER     - Database username
///   DATABASE_PASSWORD - Database password
library;

import 'dart:io';
import 'package:dartonic/dartonic.dart';
import 'package:dartonic_cli/dartonic_cli.dart';

// Import migrations and model schemas
import '../lib/migrations/migrations.dart';
import '../lib/model_schemas.dart';

Future<void> main(List<String> args) async {
  // Check for verbose flag
  final verbose = args.contains('-v') || args.contains('--verbose');

  // Determine database configuration
  final MigrationRunnerConfig config;

  // Check if DATABASE_URL or DATABASE_TYPE is set
  final dbUrl = Platform.environment['DATABASE_URL'];
  final dbType = Platform.environment['DATABASE_TYPE'];

  if (dbUrl != null || dbType != null) {
    // Use environment-based configuration
    config = MigrationRunnerConfig.fromEnvironment(
      migrations: allMigrations,
      modelSchemas: allModelSchemas,
      verbose: verbose,
    );
  } else {
    // Default to SQLite for easy testing
    print('ℹ No DATABASE_URL or DATABASE_TYPE set, using SQLite (example.db)');
    print('  Set DATABASE_URL or DATABASE_TYPE to use PostgreSQL/MySQL\n');

    config = MigrationRunnerConfig(
      database: DatabaseConfig.sqlite('example.db'),
      adapter: const SqliteAdapter(),
      migrations: allMigrations,
      modelSchemas: allModelSchemas,
      verbose: verbose,
    );
  }

  // Run the CLI
  final cli = DartonicCli(config);
  final exitCode = await cli.run(args);
  exit(exitCode);
}
