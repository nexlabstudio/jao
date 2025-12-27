#!/usr/bin/env dart
/// Project migration CLI.
/// 
/// Usage:
///   dart run bin/migrate.dart migrate
///   dart run bin/migrate.dart makemigrations
///   dart run bin/migrate.dart status
///   dart run bin/migrate.dart rollback
///
/// Or if dartonic is installed globally:
///   dartonic migrate
///   dartonic status
library;

import 'dart:io';
import 'package:dartonic/dartonic.dart';
import 'package:dartonic_cli/dartonic_cli.dart';
import 'package:dartonic_example/models/models.dart';

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
    modelSchemas: [
      AuthorDartonic.schema,
      PostDartonic.schema,
      TagDartonic.schema,
      CommentDartonic.schema,
    ],
    verbose: args.contains('-v') || args.contains('--verbose'),
  );

  final cli = DartonicCli(config);
  exit(await cli.run(args));
}
