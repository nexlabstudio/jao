#!/usr/bin/env dart

/// JAO CLI - Just Another ORM migration management.
/// We know there are many, but this is the one that works the way you expect.
///
/// Install globally:
///   dart pub global activate jao_cli
///
/// Or from local path:
///   dart pub global activate --source path ./jao_cli
///
/// Then run from any jao project:
///   jao init
///   jao makemigrations
///   jao migrate
///   jao status
///   jao rollback
///
/// Commands:
///   init            Initialize jao in current project
///   makemigrations  Auto-detect model changes and create migration
///   migrate         Run pending migrations
///   rollback        Rollback the last migration(s)
///   status          Show migration status
///   reset           Reset all migrations
///   refresh         Reset and re-run all migrations
///   sql             Show SQL for migrations
///   make            Generate an empty migration file
///   help            Show help
///
/// Configuration:
///   The CLI looks for bin/migrate.dart in the current directory and runs it,
///   or uses jao.yaml / environment variables for database configuration.
library;

import 'dart:io';
import 'package:jao_cli/jao_cli.dart';

Future<void> main(List<String> args) async {
  // Commands that don't need config can run directly through JaoCli
  if (args.isNotEmpty) {
    final command = args.first;
    if (command == 'init' || command == 'make' || command == 'help' || command == '-h' || command == '--help') {
      final cli = JaoCli();
      exit(await cli.run(args));
    }
  }

  // Check if there's a project-specific migrate.dart and use it
  final projectMigrate = File('bin/migrate.dart');
  if (projectMigrate.existsSync()) {
    // Run the project's migrate.dart with the provided arguments
    final result = await Process.run('dart', ['run', 'bin/migrate.dart', ...args], runInShell: true);
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    exit(result.exitCode);
  }

  // No project migrate.dart and command needs config
  if (args.isEmpty) {
    final cli = JaoCli();
    exit(await cli.run(args));
  }

  print('\x1B[33m⚠\x1B[0m Command "${args.first}" requires database configuration.');
  print('');
  print('Please ensure bin/migrate.dart exists with your migrations imported.');
  print('Run "jao init" to create the project structure.');
  exit(1);
}
