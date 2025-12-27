/// Migration Runner - Core functionality for running migrations.
///
/// This module provides the actual implementation for migration commands.
library;

import 'dart:async';
import 'dart:io';
import 'package:dartonic/dartonic.dart';

/// Configuration for the migration runner.
class MigrationRunnerConfig {
  /// Database configuration
  final DatabaseConfig database;

  /// Database adapter to use
  final DatabaseAdapter adapter;

  /// List of migrations to manage
  final List<Migration> migrations;

  /// Model schemas for auto-detection (used by makemigrations)
  final List<ModelSchema> modelSchemas;

  /// Name of the migrations tracking table
  final String migrationsTable;

  /// Whether to run in verbose mode
  final bool verbose;

  const MigrationRunnerConfig({
    required this.database,
    required this.adapter,
    required this.migrations,
    this.modelSchemas = const [],
    this.migrationsTable = 'dartonic_migrations',
    this.verbose = false,
  });

  /// Create config from environment variables.
  factory MigrationRunnerConfig.fromEnvironment({
    required List<Migration> migrations,
    List<ModelSchema> modelSchemas = const [],
    DatabaseAdapter? adapter,
    String migrationsTable = 'dartonic_migrations',
    bool verbose = false,
  }) {
    final dbConfig = _loadDatabaseConfig();
    final dbAdapter = adapter ?? _detectAdapter(dbConfig);

    return MigrationRunnerConfig(
      database: dbConfig,
      adapter: dbAdapter,
      migrations: migrations,
      modelSchemas: modelSchemas,
      migrationsTable: migrationsTable,
      verbose: verbose,
    );
  }

  static DatabaseConfig _loadDatabaseConfig() {
    final url = Platform.environment['DATABASE_URL'];
    if (url != null && url.isNotEmpty) {
      return DatabaseConfig.fromUrl(url);
    }

    final host = Platform.environment['DATABASE_HOST'] ?? 'localhost';
    final port = int.tryParse(Platform.environment['DATABASE_PORT'] ?? '') ?? 5432;
    final database = Platform.environment['DATABASE_NAME'] ?? 'dartonic';
    final username = Platform.environment['DATABASE_USER'];
    final password = Platform.environment['DATABASE_PASSWORD'];
    final ssl = Platform.environment['DATABASE_SSL']?.toLowerCase() == 'true';

    return DatabaseConfig(
      host: host,
      port: port,
      database: database,
      username: username,
      password: password,
      useSsl: ssl,
    );
  }

  static DatabaseAdapter _detectAdapter(DatabaseConfig config) {
    final url = Platform.environment['DATABASE_URL'] ?? '';
    final type = Platform.environment['DATABASE_TYPE'] ?? '';

    if (url.startsWith('postgres') || type == 'postgres' || type == 'postgresql') {
      return const PostgresAdapter();
    } else if (url.startsWith('mysql') || type == 'mysql') {
      return const MySqlAdapter();
    } else if (url.startsWith('sqlite') || type == 'sqlite') {
      return const SqliteAdapter();
    }

    // Default based on port
    if (config.port == 3306) return const MySqlAdapter();
    if (config.database.endsWith('.db') || config.database.endsWith('.sqlite')) {
      return const SqliteAdapter();
    }

    return const PostgresAdapter();
  }
}

/// CLI runner for migrations.
class DartonicCli {
  final MigrationRunnerConfig config;
  final CliOutput output;

  DartonicCli(this.config) : output = CliOutput(verbose: config.verbose);

  /// Run the CLI with command-line arguments.
  Future<int> run(List<String> args) async {
    if (args.isEmpty) {
      _printUsage();
      return 0;
    }

    final command = args.first;
    final commandArgs = args.skip(1).toList();

    try {
      return await switch (command) {
        'migrate' => _migrate(commandArgs),
        'makemigrations' => _makeMigrations(commandArgs),
        'rollback' => _rollback(commandArgs),
        'status' => _status(commandArgs),
        'reset' => _reset(commandArgs),
        'refresh' => _refresh(commandArgs),
        'sql' => _sql(commandArgs),
        'make' => _make(commandArgs),
        'help' || '-h' || '--help' => _help(commandArgs),
        _ => _unknownCommand(command),
      };
    } catch (e, stack) {
      output.error('Error: $e');
      if (config.verbose) {
        print(stack);
      }
      return 1;
    }
  }

  void _printUsage() {
    print('''
Dartonic Migration CLI

Usage: dartonic <command> [options]

Commands:
  makemigrations  Auto-detect model changes and create migration
  migrate         Run pending migrations
  rollback        Rollback migrations
  status          Show migration status
  reset           Rollback all migrations
  refresh         Reset and re-run all migrations
  sql             Show SQL for migrations
  make            Generate an empty migration file
  help            Show help for a command

Run 'dartonic help <command>' for more information.
''');
  }

  Future<int> _unknownCommand(String command) async {
    output.error("Unknown command: '$command'");
    print("Run 'dartonic help' for usage information.");
    return 1;
  }

  Future<int> _help(List<String> args) async {
    if (args.isEmpty) {
      _printUsage();
      return 0;
    }

    final command = args.first;
    switch (command) {
      case 'makemigrations':
        print('''
dartonic makemigrations - Auto-detect model changes and create migration

Usage: dartonic makemigrations [options]

Options:
  -n, --name=NAME     Name for the migration (auto-generated if not provided)
  -p, --path=PATH     Output directory (default: lib/migrations)
  --empty             Create empty migration (no auto-detection)
  --dry-run           Show what would be generated without creating file

This command compares your current model definitions against the database
schema (or previous migrations) and generates a new migration file with
the necessary changes.

Examples:
  dartonic makemigrations                    # Auto-detect and generate
  dartonic makemigrations -n add_users       # With custom name
  dartonic makemigrations --empty -n initial # Empty migration
''');
      case 'migrate':
        print('''
dartonic migrate - Run pending migrations

Usage: dartonic migrate [options]

Options:
  -n, --dry-run    Show SQL without executing
  -v, --verbose    Show detailed output
''');
      case 'rollback':
        print('''
dartonic rollback - Rollback migrations

Usage: dartonic rollback [options]

Options:
  -s, --step=N     Number of migrations to rollback (default: 1)
  -n, --dry-run    Show SQL without executing
  -v, --verbose    Show detailed output
''');
      case 'status':
        print('''
dartonic status - Show migration status

Usage: dartonic status
''');
      case 'sql':
        print('''
dartonic sql - Show SQL for migrations

Usage: dartonic sql [options]

Options:
  -m, --migration=NAME    Show SQL for specific migration
  -a, --all               Show SQL for all pending migrations
  --down                  Show rollback SQL instead of apply SQL
''');
      case 'make':
        print('''
dartonic make - Generate a new migration file

Usage: dartonic make -n <name>

Options:
  -n, --name=NAME    Name for the migration (required)
  -p, --path=PATH    Output directory (default: lib/migrations)
''');
      default:
        print("Unknown command: '$command'");
        return 1;
    }
    return 0;
  }

  /// Run pending migrations.
  Future<int> _migrate(List<String> args) async {
    final dryRun = args.contains('-n') || args.contains('--dry-run');
    final verbose = args.contains('-v') || args.contains('--verbose');

    output.header('Running Migrations');

    if (dryRun) {
      output.info('Dry run mode - showing SQL only\n');
      return _showPendingMigrationsSql();
    }

    // Connect to database
    output.debug('Connecting to ${config.adapter.name}...');
    final pool = await config.adapter.createPool(config.database);

    try {
      final runner = MigrationRunner(adapter: config.adapter, pool: pool, migrationsTable: config.migrationsTable);

      // Get current status
      final applied = await runner.getAppliedMigrations();
      final pending = config.migrations.where((m) => !applied.contains(m.name)).toList();

      if (pending.isEmpty) {
        output.info('No pending migrations.');
        return 0;
      }

      output.info('Found ${pending.length} pending migration(s)\n');

      // Run migrations
      final result = await runner.migrate(config.migrations);

      if (result.isSuccess) {
        for (final name in result.applied) {
          output.success('Applied: $name');
        }
        print('');
        output.info('Successfully applied ${result.applied.length} migration(s).');
        return 0;
      } else {
        for (final name in result.applied) {
          output.success('Applied: $name');
        }
        for (final error in result.errors) {
          output.error('Failed: ${error.migrationName}');
          output.error('  ${error.message}');
          if (verbose && error.stackTrace != null) {
            print(error.stackTrace);
          }
        }
        return 1;
      }
    } finally {
      await pool.close();
    }
  }

  /// Auto-detect model changes and create migration.
  Future<int> _makeMigrations(List<String> args) async {
    final dryRun = args.contains('--dry-run');
    final empty = args.contains('--empty');
    var path = 'lib/migrations';
    String? name;

    for (final arg in args) {
      if (arg.startsWith('-n=') || arg.startsWith('--name=')) {
        name = arg.split('=').last;
      } else if (arg.startsWith('-p=') || arg.startsWith('--path=')) {
        path = arg.split('=').last;
      }
    }

    output.header('Making Migrations');

    if (empty) {
      // Just create an empty migration
      return _createEmptyMigration(name, path, dryRun);
    }

    // Auto-detect changes by comparing models to database
    output.info('Detecting model changes...\n');

    // Connect to database to get current schema
    final pool = await config.adapter.createPool(config.database);

    try {
      final conn = await pool.acquire();
      try {
        final generator = SchemaGenerator(config.adapter);

        // Get models from config
        final models = config.modelSchemas;
        if (models.isEmpty) {
          output.warning('No model schemas registered.');
          output.info('Register models in MigrationRunnerConfig.modelSchemas');
          output.info('Or use --empty to create an empty migration.');
          return 1;
        }

        // Generate diff operations
        final operations = await generator.generateDiff(conn, models);

        if (operations.isEmpty) {
          output.info('No changes detected.');
          return 0;
        }

        output.info('Detected ${operations.length} change(s):');
        for (final op in operations) {
          output.success('  ${_describeOperation(op)}');
        }
        print('');

        if (dryRun) {
          output.info('Dry run - showing generated migration:\n');
          final migrationName = _generateMigrationName(name, operations);
          final content = generator.generateMigrationFile(migrationName, operations);
          print(content);
          return 0;
        }

        // Generate migration file
        final migrationName = _generateMigrationName(name, operations);
        final content = generator.generateMigrationFile(migrationName, operations);

        // Write file
        final timestamp = _generateTimestamp();
        final fileName = '${timestamp}_${_toSnakeCase(migrationName)}.dart';
        final fullPath = '$path/$fileName';

        final dir = Directory(path);
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }

        File(fullPath).writeAsStringSync(content);
        output.success('Created: $fullPath');

        print('');
        output.info('Remember to add this migration to your migrations list!');

        return 0;
      } finally {
        await pool.release(conn);
      }
    } finally {
      await pool.close();
    }
  }

  Future<int> _createEmptyMigration(String? name, String path, bool dryRun) async {
    if (name == null || name.isEmpty) {
      output.error('Migration name is required for empty migrations.');
      print('Usage: dartonic makemigrations --empty -n=<name>');
      return 1;
    }

    final timestamp = _generateTimestamp();
    final className = _toPascalCase(name);
    final migrationName = '${timestamp}_$name';
    final fileName = '$migrationName.dart';
    final fullPath = '$path/$fileName';

    final content =
        '''import 'package:dartonic/dartonic.dart';

/// Migration: $migrationName
class $className extends Migration {
  @override
  String get name => '$migrationName';

  @override
  void up(MigrationBuilder builder) {
    // TODO: Add your schema changes here
  }

  @override
  void down(MigrationBuilder builder) {
    // TODO: Add reverse operations here
  }
}
''';

    if (dryRun) {
      output.info('Would create: $fullPath\n');
      print(content);
      return 0;
    }

    final dir = Directory(path);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    File(fullPath).writeAsStringSync(content);
    output.success('Created: $fullPath');

    return 0;
  }

  String _generateMigrationName(String? customName, List<MigrationOperation> operations) {
    if (customName != null && customName.isNotEmpty) {
      return _toPascalCase(customName);
    }

    // Auto-generate name based on operations
    if (operations.isEmpty) return 'EmptyMigration';

    final firstOp = operations.first;
    if (firstOp is CreateTable) {
      if (operations.length == 1) {
        return 'Create${_toPascalCase(firstOp.table.name)}';
      } else {
        final tableCount = operations.whereType<CreateTable>().length;
        if (tableCount == operations.length) {
          return 'CreateTables';
        }
      }
    } else if (firstOp is AddColumn) {
      return 'Add${_toPascalCase(firstOp.column.name)}To${_toPascalCase(firstOp.table)}';
    } else if (firstOp is DropColumn) {
      return 'Drop${_toPascalCase(firstOp.column)}From${_toPascalCase(firstOp.table)}';
    }

    return 'AutoMigration';
  }

  String _describeOperation(MigrationOperation op) {
    if (op is CreateTable) {
      return 'Create table "${op.table.name}" with ${op.table.columns.length} columns';
    } else if (op is DropTable) {
      return 'Drop table "${op.name}"';
    } else if (op is AddColumn) {
      return 'Add column "${op.column.name}" to "${op.table}"';
    } else if (op is DropColumn) {
      return 'Drop column "$op.column" from "${op.table}"';
    } else if (op is CreateIndex) {
      return 'Create index "${op.index.name}" on "${op.table}"';
    } else if (op is AddForeignKey) {
      return 'Add foreign key "${op.foreignKey.column}" on "${op.table}"';
    }
    return op.runtimeType.toString();
  }

  String _generateTimestamp() {
    final now = DateTime.now();
    return '${now.year}${_pad(now.month)}${_pad(now.day)}${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}';
  }

  /// Rollback migrations.
  Future<int> _rollback(List<String> args) async {
    final dryRun = args.contains('-n') || args.contains('--dry-run');
    final verbose = args.contains('-v') || args.contains('--verbose');

    // Parse step count
    var steps = 1;
    for (final arg in args) {
      if (arg.startsWith('-s=') || arg.startsWith('--step=')) {
        steps = int.tryParse(arg.split('=').last) ?? 1;
      }
    }

    output.header('Rolling Back Migrations');

    if (dryRun) {
      output.info('Dry run mode - showing SQL only\n');
      return _showRollbackSql(steps);
    }

    // Connect to database
    output.debug('Connecting to ${config.adapter.name}...');
    final pool = await config.adapter.createPool(config.database);

    try {
      final runner = MigrationRunner(adapter: config.adapter, pool: pool, migrationsTable: config.migrationsTable);

      final applied = await runner.getAppliedMigrations();
      if (applied.isEmpty) {
        output.info('No migrations to rollback.');
        return 0;
      }

      output.info('Rolling back $steps migration(s)\n');

      final result = await runner.rollback(config.migrations, count: steps);

      if (result.isSuccess) {
        for (final name in result.rolledBack) {
          output.success('Rolled back: $name');
        }
        print('');
        output.info('Successfully rolled back ${result.rolledBack.length} migration(s).');
        return 0;
      } else {
        for (final name in result.rolledBack) {
          output.success('Rolled back: $name');
        }
        for (final error in result.errors) {
          output.error('Failed: ${error.migrationName}');
          output.error('  ${error.message}');
          if (verbose && error.stackTrace != null) {
            print(error.stackTrace);
          }
        }
        return 1;
      }
    } finally {
      await pool.close();
    }
  }

  /// Show migration status.
  Future<int> _status(List<String> args) async {
    output.header('Migration Status');

    // Connect to database
    output.debug('Connecting to ${config.adapter.name}...');
    final pool = await config.adapter.createPool(config.database);

    try {
      final runner = MigrationRunner(adapter: config.adapter, pool: pool, migrationsTable: config.migrationsTable);

      final status = await runner.status(config.migrations);

      final rows = <List<String>>[];
      var appliedCount = 0;
      var pendingCount = 0;

      for (final s in status) {
        final statusStr = s.isApplied
            ? (s.isMissing ? '\x1B[33mMissing\x1B[0m' : '\x1B[32mApplied\x1B[0m')
            : '\x1B[90mPending\x1B[0m';
        rows.add([s.name, statusStr]);

        if (s.isApplied) {
          appliedCount++;
        } else {
          pendingCount++;
        }
      }

      output.table(rows, headers: ['Migration', 'Status']);

      print('');
      output.info('$appliedCount applied, $pendingCount pending');

      return 0;
    } finally {
      await pool.close();
    }
  }

  /// Reset all migrations.
  Future<int> _reset(List<String> args) async {
    final dryRun = args.contains('-n') || args.contains('--dry-run');
    final force = args.contains('-f') || args.contains('--force');

    output.header('Reset Migrations');

    if (!force && !dryRun) {
      output.warning('This will rollback ALL migrations.');
      stdout.write('Are you sure? (y/N): ');
      final response = stdin.readLineSync()?.toLowerCase();
      if (response != 'y' && response != 'yes') {
        output.info('Cancelled.');
        return 0;
      }
    }

    if (dryRun) {
      output.info('Dry run mode - showing SQL only\n');
      return _showRollbackSql(config.migrations.length);
    }

    // Connect to database
    final pool = await config.adapter.createPool(config.database);

    try {
      final runner = MigrationRunner(adapter: config.adapter, pool: pool, migrationsTable: config.migrationsTable);

      final result = await runner.reset(config.migrations);

      for (final name in result.rolledBack) {
        output.success('Rolled back: $name');
      }

      if (result.errors.isNotEmpty) {
        for (final error in result.errors) {
          output.error('Failed: ${error.migrationName} - ${error.message}');
        }
        return 1;
      }

      print('');
      output.info('Reset complete. Rolled back ${result.rolledBack.length} migration(s).');
      return 0;
    } finally {
      await pool.close();
    }
  }

  /// Refresh migrations (reset + migrate).
  Future<int> _refresh(List<String> args) async {
    final dryRun = args.contains('-n') || args.contains('--dry-run');
    final force = args.contains('-f') || args.contains('--force');

    output.header('Refresh Migrations');

    if (!force && !dryRun) {
      output.warning('This will reset and re-run ALL migrations.');
      stdout.write('Are you sure? (y/N): ');
      final response = stdin.readLineSync()?.toLowerCase();
      if (response != 'y' && response != 'yes') {
        output.info('Cancelled.');
        return 0;
      }
    }

    if (dryRun) {
      output.info('Dry run mode - showing SQL only\n');
      await _showRollbackSql(config.migrations.length);
      print('');
      return _showPendingMigrationsSql();
    }

    // Connect to database
    final pool = await config.adapter.createPool(config.database);

    try {
      final runner = MigrationRunner(adapter: config.adapter, pool: pool, migrationsTable: config.migrationsTable);

      // Reset
      output.info('Rolling back all migrations...\n');
      final resetResult = await runner.reset(config.migrations);

      for (final name in resetResult.rolledBack) {
        output.success('Rolled back: $name');
      }

      if (resetResult.errors.isNotEmpty) {
        for (final error in resetResult.errors) {
          output.error('Failed: ${error.migrationName} - ${error.message}');
        }
        return 1;
      }

      // Migrate
      print('');
      output.info('Running all migrations...\n');
      final migrateResult = await runner.migrate(config.migrations);

      for (final name in migrateResult.applied) {
        output.success('Applied: $name');
      }

      if (migrateResult.errors.isNotEmpty) {
        for (final error in migrateResult.errors) {
          output.error('Failed: ${error.migrationName} - ${error.message}');
        }
        return 1;
      }

      print('');
      output.info('Refresh complete.');
      return 0;
    } finally {
      await pool.close();
    }
  }

  /// Show SQL for migrations.
  Future<int> _sql(List<String> args) async {
    final showDown = args.contains('--down');
    String? migrationName;

    for (final arg in args) {
      if (arg.startsWith('-m=') || arg.startsWith('--migration=')) {
        migrationName = arg.split('=').last;
      }
    }

    output.header(showDown ? 'Rollback SQL' : 'Migration SQL');

    final direction = showDown ? MigrationDirection.down : MigrationDirection.up;

    if (migrationName != null) {
      // Show SQL for specific migration
      final migration = config.migrations.where((m) => m.name == migrationName).firstOrNull;

      if (migration == null) {
        output.error("Migration not found: '$migrationName'");
        return 1;
      }

      _printMigrationSql(migration, direction);
    } else {
      // Show SQL for all pending (or all for down)
      for (final migration in config.migrations) {
        _printMigrationSql(migration, direction);
        print('');
      }
    }

    return 0;
  }

  void _printMigrationSql(Migration migration, MigrationDirection direction) {
    print('-- Migration: ${migration.name}');
    print('-- Direction: ${direction == MigrationDirection.up ? "UP" : "DOWN"}');
    print('');

    final builder = MigrationBuilder();
    if (direction == MigrationDirection.up) {
      migration.up(builder);
    } else {
      migration.down(builder);
    }

    for (final operation in builder.operations) {
      final sql = direction == MigrationDirection.up
          ? operation.toSql(config.adapter.dialect)
          : operation.toReverseSql(config.adapter.dialect);
      if (sql != null && sql.isNotEmpty) {
        print(sql);
        print(';');
        print('');
      }
    }
  }

  int _showPendingMigrationsSql() {
    for (final migration in config.migrations) {
      _printMigrationSql(migration, MigrationDirection.up);
      print('');
    }
    return 0;
  }

  int _showRollbackSql(int count) {
    final toShow = config.migrations.reversed.take(count);
    for (final migration in toShow) {
      _printMigrationSql(migration, MigrationDirection.down);
      print('');
    }
    return 0;
  }

  /// Generate a new migration file.
  Future<int> _make(List<String> args) async {
    String? name;
    var path = 'lib/migrations';

    for (final arg in args) {
      if (arg.startsWith('-n=') || arg.startsWith('--name=')) {
        name = arg.split('=').last;
      } else if (arg.startsWith('-p=') || arg.startsWith('--path=')) {
        path = arg.split('=').last;
      } else if (!arg.startsWith('-')) {
        name ??= arg;
      }
    }

    if (name == null || name.isEmpty) {
      output.error('Migration name is required.');
      print("Usage: dartonic make -n=<name> [-p=<path>]");
      return 1;
    }

    output.header('Creating Migration');

    // Generate timestamp
    final now = DateTime.now();
    final timestamp =
        '${now.year}${_pad(now.month)}${_pad(now.day)}${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}';

    final className = _toPascalCase(name);
    final migrationName = '${timestamp}_$name';
    final fileName = '$migrationName.dart';
    final fullPath = '$path/$fileName';

    // Ensure directory exists
    final dir = Directory(path);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
      output.info('Created directory: $path');
    }

    // Generate content
    final content =
        '''import 'package:dartonic/dartonic.dart';

/// Migration: $migrationName
class $className extends Migration {
  @override
  String get name => '$migrationName';

  @override
  void up(MigrationBuilder builder) {
    // TODO: Add your schema changes here
    // 
    // Example - Create a table:
    // builder.createTable('users', (table) {
    //   table.id();
    //   table.string('name');
    //   table.string('email').unique();
    //   table.timestamps();
    // });
    //
    // Example - Add a column:
    // builder.addColumn('users', 'phone', FieldType.varchar, length: 20);
    //
    // Example - Create an index:
    // builder.createIndex('users', ['email']);
  }

  @override
  void down(MigrationBuilder builder) {
    // TODO: Add reverse operations here
    //
    // Example - Drop a table:
    // builder.dropTable('users');
    //
    // Example - Drop a column:
    // builder.dropColumn('users', 'phone');
  }
}
''';

    // Write file
    File(fullPath).writeAsStringSync(content);
    output.success('Created: $fullPath');

    print('');
    output.info("Don't forget to add your migration to the migrations list!");
    print('''
Example in lib/migrations/migrations.dart:

  import '${fileName.replaceAll('.dart', '')}.dart';
  
  final allMigrations = <Migration>[
    // ... existing migrations ...
    $className(),
  ];
''');

    return 0;
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  String _toPascalCase(String input) {
    return input
        .split(RegExp(r'[_\-\s]+'))
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join('');
  }

  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}')
        .replaceFirst(RegExp(r'^_'), '');
  }
}

/// Output formatting utilities.
class CliOutput {
  final bool verbose;

  const CliOutput({this.verbose = false});

  void info(String message) {
    print('\x1B[34mℹ\x1B[0m $message');
  }

  void success(String message) {
    print('\x1B[32m✓\x1B[0m $message');
  }

  void warning(String message) {
    print('\x1B[33m⚠\x1B[0m $message');
  }

  void error(String message) {
    print('\x1B[31m✗\x1B[0m $message');
  }

  void debug(String message) {
    if (verbose) {
      print('\x1B[90m  $message\x1B[0m');
    }
  }

  void header(String message) {
    print('\n\x1B[1m$message\x1B[0m');
    print('${'─' * message.length}');
  }

  void table(List<List<String>> rows, {List<String>? headers}) {
    if (rows.isEmpty) return;

    final colCount = headers?.length ?? rows.first.length;
    final widths = List.filled(colCount, 0);

    // Strip ANSI codes for width calculation
    String stripAnsi(String s) => s.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '');

    if (headers != null) {
      for (var i = 0; i < headers.length; i++) {
        widths[i] = stripAnsi(headers[i]).length;
      }
    }

    for (final row in rows) {
      for (var i = 0; i < row.length && i < colCount; i++) {
        final len = stripAnsi(row[i]).length;
        if (len > widths[i]) widths[i] = len;
      }
    }

    String padWithAnsi(String s, int width) {
      final stripped = stripAnsi(s);
      final padding = width - stripped.length;
      return s + ' ' * (padding > 0 ? padding : 0);
    }

    if (headers != null) {
      final headerRow = headers.asMap().entries.map((e) => padWithAnsi(e.value, widths[e.key])).join(' │ ');
      print('  $headerRow');
      print('  ${widths.map((w) => '─' * w).join('─┼─')}');
    }

    for (final row in rows) {
      final formattedRow = row.asMap().entries.map((e) => padWithAnsi(e.value, widths[e.key])).join(' │ ');
      print('  $formattedRow');
    }
  }
}
