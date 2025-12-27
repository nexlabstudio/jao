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
///   jao makemigrations
///   jao migrate
///   jao status
///   jao rollback
///
/// Commands:
///   makemigrations  Auto-detect model changes and create migration
///   migrate         Run pending migrations
///   rollback        Rollback the last migration(s)
///   status          Show migration status
///   reset           Reset all migrations
///   refresh         Reset and re-run all migrations
///   sql             Show SQL for migrations
///   make            Generate an empty migration file
///   init            Initialize jao in current project
///   help            Show help
///
/// Configuration:
///   The CLI looks for bin/migrate.dart in the current directory and runs it,
///   or uses jao.yaml / environment variables for database configuration.
library;

import 'dart:io';
import 'package:jao/jao.dart';

Future<void> main(List<String> args) async {
  // Handle init command specially (doesn't need config)
  if (args.isNotEmpty && args.first == 'init') {
    await _initProject(args.skip(1).toList());
    return;
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

  // No project migrate.dart - check for config and provide limited functionality
  final verbose = args.contains('-v') || args.contains('--verbose');
  if (verbose) {
    print('\x1B[90m  No bin/migrate.dart found, using limited mode...\x1B[0m');
  }
  final projectConfig = await _loadProjectConfig();

  if (verbose && projectConfig != null) {
    print(
      '\x1B[90m  Loaded config: ${projectConfig.adapter.runtimeType}, database: ${projectConfig.database.database}\x1B[0m',
    );
  }

  if (projectConfig == null) {
    print('\x1B[31m✗\x1B[0m No jao project found.');
    print('');
    print('Run "jao init" to initialize a new project.');
    print('');
    print('This will create:');
    print('  - jao.yaml (database configuration)');
    print('  - lib/migrations/ (migrations directory)');
    print('  - bin/migrate.dart (project CLI)');
    exit(1);
  }

  // For projects without bin/migrate.dart, we can only do limited operations
  // that don't require compiled migrations
  if (args.isEmpty) {
    _printUsage();
    exit(0);
  }

  final command = args.first;

  // Handle commands that don't need migrations
  switch (command) {
    case 'init':
      await _initProject(args.skip(1).toList());
      return;
    case 'make':
      await _makeEmptyMigration(args.skip(1).toList());
      return;
    case 'help':
    case '-h':
    case '--help':
      _printUsage();
      return;
  }

  // Commands that need migrations require bin/migrate.dart
  print('\x1B[33m⚠\x1B[0m Command "$command" requires migrations to be compiled.');
  print('');
  print('Please ensure bin/migrate.dart exists with your migrations imported.');
  print('Run "jao init" to create the project structure.');
  exit(1);
}

void _printUsage() {
  print('''
JAO Migration CLI
Because you didn't have enough options already.

Usage: jao <command> [options]

Commands:
  init            Initialize jao in current project
  make            Generate an empty migration file
  makemigrations  Auto-detect model changes and create migration
  migrate         Run pending migrations
  rollback        Rollback migrations
  status          Show migration status
  reset           Rollback all migrations
  refresh         Reset and re-run all migrations
  sql             Show SQL for migrations
  help            Show help

Setup:
  1. Run "jao init" to initialize your project
  2. Create migrations in lib/migrations/
  3. Import migrations in bin/migrate.dart
  4. Run "jao migrate" to apply migrations

Examples:
  jao init                    # Initialize project
  jao init --db=postgres      # Initialize with PostgreSQL
  jao make -n=create_users    # Create empty migration
  jao migrate                 # Run pending migrations
  jao status                  # Show migration status
''');
}

/// Project configuration loaded from jao.yaml or environment.
class ProjectConfig {
  final DatabaseConfig database;
  final DatabaseAdapter adapter;
  final String migrationsPath;
  final String modelsPath;

  ProjectConfig({
    required this.database,
    required this.adapter,
    this.migrationsPath = 'lib/migrations',
    this.modelsPath = 'lib/models',
  });
}

/// Load project configuration from jao.yaml or environment.
Future<ProjectConfig?> _loadProjectConfig() async {
  // Try jao.yaml first
  final configFile = File('jao.yaml');
  if (configFile.existsSync()) {
    return _parseConfigFile(configFile);
  }

  // Try environment variables
  final dbUrl = Platform.environment['DATABASE_URL'];
  final dbType = Platform.environment['DATABASE_TYPE'];

  if (dbUrl != null || dbType != null) {
    final database = dbUrl != null
        ? DatabaseConfig.fromUrl(dbUrl)
        : DatabaseConfig(
            host: Platform.environment['DATABASE_HOST'] ?? 'localhost',
            port: int.tryParse(Platform.environment['DATABASE_PORT'] ?? '') ?? 5432,
            database: Platform.environment['DATABASE_NAME'] ?? 'jao',
            username: Platform.environment['DATABASE_USER'],
            password: Platform.environment['DATABASE_PASSWORD'],
            useSsl: Platform.environment['DATABASE_SSL']?.toLowerCase() == 'true',
          );

    final adapter = _detectAdapter(dbUrl ?? '', dbType ?? '', database);

    return ProjectConfig(database: database, adapter: adapter);
  }

  // Check if pubspec.yaml exists (we're in a Dart project)
  final pubspec = File('pubspec.yaml');
  if (pubspec.existsSync()) {
    // Default to SQLite for development
    return ProjectConfig(database: DatabaseConfig.sqlite('database.db'), adapter: const SqliteAdapter());
  }

  return null;
}

/// Parse jao.yaml configuration file.
Future<ProjectConfig> _parseConfigFile(File file) async {
  final content = await file.readAsString();
  final lines = content.split('\n');

  String? dbType;
  String? host;
  int port = 5432;
  String? database;
  String? username;
  String? password;
  bool useSsl = false;
  String migrationsPath = 'lib/migrations';
  String modelsPath = 'lib/models';

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.startsWith('#') || !trimmed.contains(':')) continue;

    final parts = trimmed.split(':');
    final key = parts[0].trim();
    final value = parts.skip(1).join(':').trim();

    switch (key) {
      case 'type':
        dbType = value;
      case 'host':
        host = value;
      case 'port':
        port = int.tryParse(value) ?? 5432;
      case 'database':
        database = value;
      case 'username':
        username = value;
      case 'password':
        password = value;
      case 'ssl':
        useSsl = value.toLowerCase() == 'true';
      case 'migrations_path':
        migrationsPath = value;
      case 'models_path':
        modelsPath = value;
    }
  }

  late DatabaseConfig dbConfig;
  late DatabaseAdapter adapter;

  if (dbType == 'sqlite') {
    dbConfig = DatabaseConfig.sqlite(database ?? 'database.db');
    adapter = const SqliteAdapter();
  } else if (dbType == 'mysql') {
    dbConfig = DatabaseConfig(
      host: host ?? 'localhost',
      port: port,
      database: database ?? 'jao',
      username: username,
      password: password,
      useSsl: useSsl,
    );
    adapter = const MySqlAdapter();
  } else {
    // Default to PostgreSQL
    dbConfig = DatabaseConfig(
      host: host ?? 'localhost',
      port: port,
      database: database ?? 'jao',
      username: username,
      password: password,
      useSsl: useSsl,
    );
    adapter = const PostgresAdapter();
  }

  return ProjectConfig(database: dbConfig, adapter: adapter, migrationsPath: migrationsPath, modelsPath: modelsPath);
}

/// Detect database adapter from URL or type.
DatabaseAdapter _detectAdapter(String url, String type, DatabaseConfig config) {
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

/// Create an empty migration file.
Future<void> _makeEmptyMigration(List<String> args) async {
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
    print('\x1B[31m✗\x1B[0m Migration name is required.');
    print('Usage: jao make -n=<name>');
    exit(1);
  }

  print('\n\x1B[1mCreating Migration\x1B[0m');
  print('─' * 18);

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
    print('\x1B[32m✓\x1B[0m Created directory: $path');
  }

  // Generate content
  final content =
      '''import 'package:jao/jao.dart';

/// Migration: $migrationName
class $className extends Migration {
  @override
  String get name => '$migrationName';

  @override
  void up(MigrationBuilder builder) {
    // Add your schema changes here
    //
    // Example - Create a table:
    // builder.createTable('users', (table) {
    //   table.id();
    //   table.string('name');
    //   table.string('email');
    //   table.unique('email');
    //   table.timestamps();
    // });
    //
    // Example - Add a column:
    // builder.addColumn('users', 'phone', FieldType.varchar, length: 20);
  }

  @override
  void down(MigrationBuilder builder) {
    // Add reverse operations here
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
  print('\x1B[32m✓\x1B[0m Created: $fullPath');

  print('');
  print('\x1B[34mℹ\x1B[0m Add this migration to lib/migrations/migrations.dart:');
  print('''
  import '$fileName';
  
  final allMigrations = <Migration>[
    // ... existing migrations ...
    $className(),
  ];
''');
}

String _pad(int n) => n.toString().padLeft(2, '0');

String _toPascalCase(String input) {
  return input
      .split(RegExp(r'[_\-\s]+'))
      .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
      .join('');
}

/// Initialize a new jao project.
Future<void> _initProject(List<String> args) async {
  print('\n\x1B[1mInitializing JAO Project\x1B[0m');
  print('─' * 24);

  // Determine database type
  String dbType = 'sqlite';
  for (final arg in args) {
    if (arg.startsWith('--db=') || arg.startsWith('--type=')) {
      dbType = arg.split('=').last;
    }
  }

  // Create jao.yaml
  final configContent =
      '''# JAO Configuration
# Database settings

type: $dbType
${dbType == 'sqlite' ? 'database: database.db' : '''host: localhost
port: ${dbType == 'mysql' ? '3306' : '5432'}
database: myapp
username: ${dbType == 'mysql' ? 'root' : 'postgres'}
password: password'''}

# Paths
migrations_path: lib/migrations
models_path: lib/models
''';

  File('jao.yaml').writeAsStringSync(configContent);
  print('\x1B[32m✓\x1B[0m Created jao.yaml');

  // Create migrations directory
  final migrationsDir = Directory('lib/migrations');
  if (!migrationsDir.existsSync()) {
    migrationsDir.createSync(recursive: true);
    print('\x1B[32m✓\x1B[0m Created lib/migrations/');
  }

  // Create initial migrations.dart
  final migrationsFile = File('lib/migrations/migrations.dart');
  if (!migrationsFile.existsSync()) {
    migrationsFile.writeAsStringSync('''/// Migrations registry.
///
/// Import and add your migrations here in order.
library;

import 'package:jao/jao.dart';

// Import your migrations:
// import '20241227_create_users.dart';

/// All migrations in order of execution.
final allMigrations = <Migration>[
  // Add migrations here in order, e.g.:
  // CreateUsers(),
];
''');
    print('\x1B[32m✓\x1B[0m Created lib/migrations/migrations.dart');
  }

  // Create bin/migrate.dart for project-specific CLI
  final binDir = Directory('bin');
  if (!binDir.existsSync()) {
    binDir.createSync();
  }

  final migrateFile = File('bin/migrate.dart');
  if (!migrateFile.existsSync()) {
    migrateFile.writeAsStringSync('''#!/usr/bin/env dart
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

void main(List<String> args) async {
  // Database configuration
  // Option 1: Read from environment
  // final config = MigrationRunnerConfig.fromEnvironment(migrations: allMigrations);

  // Option 2: Explicit configuration
  final config = MigrationRunnerConfig(
    database: DatabaseConfig.${dbType == 'sqlite' ? "sqlite('database.db')" : '''(
      host: 'localhost',
      port: ${dbType == 'mysql' ? '3306' : '5432'},
      database: 'myapp',
      username: '${dbType == 'mysql' ? 'root' : 'postgres'}',
      password: 'password',
    )'''},
    adapter: const ${dbType == 'sqlite'
        ? 'SqliteAdapter'
        : dbType == 'mysql'
        ? 'MySqlAdapter'
        : 'PostgresAdapter'}(),
    migrations: allMigrations,
    verbose: args.contains('-v') || args.contains('--verbose'),
  );

  final cli = JaoCli(config);
  exit(await cli.run(args));
}
''');
    print('\x1B[32m✓\x1B[0m Created bin/migrate.dart');
  }

  print('');
  print('\x1B[34mℹ\x1B[0m Project initialized! Next steps:');
  print('');
  print('  1. Add dependencies to pubspec.yaml:');
  print('     dependencies:');
  print('       jao: ^0.0.1');
  print('     dev_dependencies:');
  print('       jao_cli: ^0.0.1');
  print('');
  print('  2. Create your first migration:');
  print('     jao make -n=create_users');
  print('');
  print('  3. Edit the migration file and add to migrations.dart');
  print('');
  print('  4. Run migrations:');
  print('     jao migrate');
  print('');
}
