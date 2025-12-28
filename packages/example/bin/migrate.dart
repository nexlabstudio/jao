#!/usr/bin/env dart

/// Project migration CLI.
///
/// Usage:
///   dart run bin/migrate.dart migrate
///   dart run bin/migrate.dart makemigrations
///   dart run bin/migrate.dart status
///   dart run bin/migrate.dart rollback
///
/// Or if jao_cli is installed globally:
///   jao migrate
///   jao status
library;

import 'dart:io';
import 'package:jao_cli/jao_cli.dart';
import 'package:jao_example/models/models.dart';

import '../lib/config/database.dart';
import '../lib/migrations/migrations.dart';

void main(List<String> args) async {
  final config = MigrationRunnerConfig(
    database: databaseConfig,
    adapter: databaseAdapter,
    migrations: allMigrations,
    modelSchemas: [
      Polls.schema,
      Choices.schema,
    ],
    verbose: args.contains('-v') || args.contains('--verbose'),
  );

  final cli = JaoCli(config);
  exit(await cli.run(args));
}
