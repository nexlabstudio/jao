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
import 'package:jao_example/models/models.dart';

// Import your migrations
import '../lib/migrations/migrations.dart';

void main(List<String> args) async {
  // Database configuration
  // Option 1: Read from environment
  // final config = MigrationRunnerConfig.fromEnvironment(migrations: allMigrations);

  // Option 2: Explicit configuration
  final config = MigrationRunnerConfig(
    database: DatabaseConfig.sqlite('database.db'),
    adapter: const SqliteAdapter(),
    migrations: allMigrations,
    verbose: args.contains('-v') || args.contains('--verbose'),
    modelSchemas: [Authors.schema, Posts.schema, Tags.schema, Comments.schema],
  );

  final cli = JaoCli(config);
  exit(await cli.run(args));
}
