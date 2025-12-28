#!/usr/bin/env dart
/// Project migration CLI.
///
/// Usage:
///   dart run bin/migrate.dart migrate
///   dart run bin/migrate.dart makemigrations
///   dart run bin/migrate.dart status
///   dart run bin/migrate.dart rollback
///
/// Or if jao is installed globally:
///   jao migrate
///   jao status
library;

import 'dart:io';
import 'package:jao/jao.dart';
import 'package:jao_cli/jao_cli.dart';

// Import your migrations
import '../lib/migrations/migrations.dart';

// Import your models for schema detection
import '../lib/models/models.dart';

void main(List<String> args) async {
  // Database configuration
  final config = MigrationRunnerConfig(
    database: DatabaseConfig.sqlite('database.db'),
    adapter: const SqliteAdapter(),
    migrations: allMigrations,
    // Register model schemas for auto-detection
    modelSchemas: [
      Polls.schema,
      Choices.schema,
    ],
    verbose: args.contains('-v') || args.contains('--verbose'),
  );

  final cli = JaoCli(config);
  exit(await cli.run(args));
}
