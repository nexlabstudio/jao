/// Migration system - Define and run database migrations.
///
/// Migrations allow you to evolve your database schema over time.
library;

import 'dart:async';
import 'package:meta/meta.dart';
import '../db/connection.dart';
import 'operations.dart';
import 'schema.dart';

/// Base class for database migrations.
///
/// Extend this class to create migrations:
///
/// ```dart
/// class Migration001CreateUsers extends Migration {
///   @override
///   String get name => '001_create_users';
///
///   @override
///   void up(MigrationBuilder builder) {
///     builder.createTable('users', (table) {
///       table.id();
///       table.string('name');
///       table.string('email').unique();
///       table.timestamps();
///     });
///   }
///
///   @override
///   void down(MigrationBuilder builder) {
///     builder.dropTable('users');
///   }
/// }
/// ```
abstract class Migration {
  /// Unique name for this migration (typically includes timestamp)
  String get name;

  /// Define the forward migration (apply changes)
  void up(MigrationBuilder builder);

  /// Define the backward migration (revert changes)
  void down(MigrationBuilder builder);

  /// Dependencies - migrations that must run before this one
  List<String> get dependencies => [];
}

/// Builder for defining migration operations.
class MigrationBuilder {
  final List<MigrationOperation> _operations = [];

  /// Get the list of operations
  List<MigrationOperation> get operations => List.unmodifiable(_operations);

  /// Create a new table
  void createTable(String name, void Function(TableBuilder) define) {
    final builder = TableBuilder(name);
    define(builder);
    _operations.add(CreateTable(builder.build()));
  }

  /// Create a new table if it doesn't exist
  void createTableIfNotExists(String name, void Function(TableBuilder) define) {
    final builder = TableBuilder(name)..ifNotExists();
    define(builder);
    _operations.add(CreateTable(builder.build()));
  }

  /// Drop a table
  void dropTable(String name, {bool ifExists = false, bool cascade = false}) {
    _operations.add(DropTable(name, ifExists: ifExists, cascade: cascade));
  }

  /// Rename a table
  void renameTable(String oldName, String newName) {
    _operations.add(RenameTable(oldName, newName));
  }

  /// Add a column to an existing table
  void addColumn(
    String table,
    String column,
    FieldType type, {
    bool nullable = false,
    String? defaultValue,
    int? length,
  }) {
    _operations.add(
      AddColumn(
        table,
        ColumnDefinition(name: column, type: type, nullable: nullable, defaultValue: defaultValue, length: length),
      ),
    );
  }

  /// Add a string column
  void addStringColumn(String table, String column, {int length = 255, bool nullable = false, String? defaultValue}) {
    addColumn(table, column, FieldType.varchar, nullable: nullable, defaultValue: defaultValue, length: length);
  }

  /// Add an integer column
  void addIntegerColumn(String table, String column, {bool nullable = false, int? defaultValue}) {
    _operations.add(
      AddColumn(
        table,
        ColumnDefinition(
          name: column,
          type: FieldType.integer,
          nullable: nullable,
          defaultValue: defaultValue?.toString(),
        ),
      ),
    );
  }

  /// Add a boolean column
  void addBooleanColumn(String table, String column, {bool nullable = false, bool? defaultValue}) {
    _operations.add(
      AddColumn(
        table,
        ColumnDefinition(
          name: column,
          type: FieldType.boolean,
          nullable: nullable,
          defaultValue: defaultValue?.toString(),
        ),
      ),
    );
  }

  /// Add a timestamp column
  void addTimestampColumn(String table, String column, {bool nullable = false, bool useCurrent = false}) {
    _operations.add(
      AddColumn(
        table,
        ColumnDefinition(
          name: column,
          type: FieldType.timestampTz,
          nullable: nullable,
          defaultValue: useCurrent ? 'CURRENT_TIMESTAMP' : null,
        ),
      ),
    );
  }

  /// Drop a column
  void dropColumn(String table, String column, {bool cascade = false}) {
    _operations.add(DropColumn(table, column, cascade: cascade));
  }

  /// Rename a column
  void renameColumn(String table, String oldName, String newName) {
    _operations.add(RenameColumn(table, oldName, newName));
  }

  /// Alter a column
  void alterColumn(String table, String column, void Function(ColumnModifier) modify) {
    final modifier = ColumnModifier(table, column);
    modify(modifier);
    _operations.add(AlterColumn(modifier.build()));
  }

  /// Create an index
  void createIndex(String table, List<String> columns, {String? name, bool unique = false}) {
    final indexName = name ?? 'idx_${table}_${columns.join('_')}';
    _operations.add(CreateIndex(table, IndexDefinition(name: indexName, columns: columns, unique: unique)));
  }

  /// Create a unique index
  void createUniqueIndex(String table, List<String> columns, {String? name}) {
    createIndex(table, columns, name: name, unique: true);
  }

  /// Drop an index
  void dropIndex(String name, {bool ifExists = false}) {
    _operations.add(DropIndex(name, ifExists: ifExists));
  }

  /// Add a foreign key constraint
  void addForeignKey(
    String table,
    String column,
    String referencedTable, {
    String referencedColumn = 'id',
    OnDeleteAction onDelete = OnDeleteAction.cascade,
    OnUpdateAction onUpdate = OnUpdateAction.cascade,
    String? constraintName,
  }) {
    _operations.add(
      AddForeignKey(
        table,
        ForeignKeyDefinition(
          column: column,
          referencedTable: referencedTable,
          referencedColumn: referencedColumn,
          onDelete: onDelete,
          onUpdate: onUpdate,
        ),
        constraintName: constraintName,
      ),
    );
  }

  /// Drop a constraint
  void dropConstraint(String table, String constraintName, {bool cascade = false}) {
    _operations.add(DropConstraint(table, constraintName, cascade: cascade));
  }

  /// Execute raw SQL
  void rawSql(String sql, {String? reverseSql}) {
    _operations.add(RawSql(sql, reverseSql: reverseSql));
  }

  /// Run Dart code for data migration
  void runDart(
    Future<void> Function(DatabaseConnection conn) forward, {
    Future<void> Function(DatabaseConnection conn)? backward,
  }) {
    _operations.add(RunDart(forward, backward: backward));
  }
}

/// Runs migrations against a database.
class MigrationRunner {
  final DatabaseAdapter adapter;
  final ConnectionPool pool;
  final String migrationsTable;

  MigrationRunner({required this.adapter, required this.pool, this.migrationsTable = 'jao_migrations'});

  /// Ensure the migrations tracking table exists
  Future<void> _ensureMigrationsTable() async {
    await pool.withConnection((conn) async {
      final exists = await adapter.tableExists(conn, migrationsTable);
      if (!exists) {
        final sql =
            '''
          CREATE TABLE ${adapter.dialect.quoteIdentifier(migrationsTable)} (
            id SERIAL PRIMARY KEY,
            name VARCHAR(255) NOT NULL UNIQUE,
            applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            checksum VARCHAR(64)
          )
        ''';
        await conn.execute(sql);
      }
    });
  }

  /// Get list of applied migration names
  Future<List<String>> getAppliedMigrations() async {
    await _ensureMigrationsTable();

    return pool.withConnection((conn) async {
      final rows = await conn.query('SELECT name FROM ${adapter.dialect.quoteIdentifier(migrationsTable)} ORDER BY id');
      return rows.map((r) => r['name'] as String).toList();
    });
  }

  /// Check if a migration has been applied
  Future<bool> isApplied(String migrationName) async {
    final applied = await getAppliedMigrations();
    return applied.contains(migrationName);
  }

  /// Run pending migrations
  Future<MigrationResult> migrate(List<Migration> migrations) async {
    await _ensureMigrationsTable();

    final applied = await getAppliedMigrations();
    final pending = migrations.where((m) => !applied.contains(m.name)).toList();

    if (pending.isEmpty) {
      return MigrationResult(applied: [], skipped: migrations.map((m) => m.name).toList(), errors: []);
    }

    final appliedNow = <String>[];
    final errors = <MigrationError>[];

    for (final migration in pending) {
      try {
        await _runMigration(migration, MigrationDirection.up);
        appliedNow.add(migration.name);
      } catch (e, stack) {
        errors.add(MigrationError(migration.name, e.toString(), stack));
        break; // Stop on first error
      }
    }

    return MigrationResult(
      applied: appliedNow,
      skipped: migrations
          .where((m) => !appliedNow.contains(m.name) && !applied.contains(m.name))
          .map((m) => m.name)
          .toList(),
      errors: errors,
    );
  }

  /// Rollback the last n migrations
  Future<MigrationResult> rollback(List<Migration> migrations, {int count = 1}) async {
    await _ensureMigrationsTable();

    final applied = await getAppliedMigrations();
    final toRollback = applied.reversed.take(count).toList();

    final rolledBack = <String>[];
    final errors = <MigrationError>[];

    for (final name in toRollback) {
      final migration = migrations.where((m) => m.name == name).firstOrNull;
      if (migration == null) {
        errors.add(MigrationError(name, 'Migration not found in codebase', null));
        continue;
      }

      try {
        await _runMigration(migration, MigrationDirection.down);
        rolledBack.add(name);
      } catch (e, stack) {
        errors.add(MigrationError(name, e.toString(), stack));
        break;
      }
    }

    return MigrationResult(applied: [], skipped: [], rolledBack: rolledBack, errors: errors);
  }

  /// Reset all migrations (rollback everything)
  Future<MigrationResult> reset(List<Migration> migrations) async {
    final applied = await getAppliedMigrations();
    return rollback(migrations, count: applied.length);
  }

  /// Reset and re-run all migrations
  Future<MigrationResult> refresh(List<Migration> migrations) async {
    await reset(migrations);
    return migrate(migrations);
  }

  /// Run a single migration in the specified direction
  Future<void> _runMigration(Migration migration, MigrationDirection direction) async {
    final builder = MigrationBuilder();

    if (direction == MigrationDirection.up) {
      migration.up(builder);
    } else {
      migration.down(builder);
    }

    await pool.withTransaction((tx) async {
      for (final operation in builder.operations) {
        if (operation is RunDart) {
          // Handle Dart operations specially
          final conn = await pool.acquire();
          try {
            if (direction == MigrationDirection.up) {
              await operation.forward(conn);
            } else {
              await operation.backward?.call(conn);
            }
          } finally {
            await pool.release(conn);
          }
        } else {
          final sql = direction == MigrationDirection.up
              ? operation.toSql(adapter.dialect)
              : operation.toReverseSql(adapter.dialect);

          if (sql != null && sql.isNotEmpty) {
            // Handle multi-statement SQL
            for (final statement in sql.split(';\n')) {
              if (statement.trim().isNotEmpty) {
                await tx.execute(statement);
              }
            }
          }
        }
      }

      // Record/remove migration in tracking table
      if (direction == MigrationDirection.up) {
        await tx.execute(
          'INSERT INTO ${adapter.dialect.quoteIdentifier(migrationsTable)} (name) VALUES (${adapter.dialect.parameterPlaceholder(1)})',
          [migration.name],
        );
      } else {
        await tx.execute(
          'DELETE FROM ${adapter.dialect.quoteIdentifier(migrationsTable)} WHERE name = ${adapter.dialect.parameterPlaceholder(1)}',
          [migration.name],
        );
      }
    });
  }

  /// Generate SQL for a migration without running it
  String generateSql(Migration migration, MigrationDirection direction) {
    final builder = MigrationBuilder();

    if (direction == MigrationDirection.up) {
      migration.up(builder);
    } else {
      migration.down(builder);
    }

    final statements = <String>[];
    for (final operation in builder.operations) {
      final sql = direction == MigrationDirection.up
          ? operation.toSql(adapter.dialect)
          : operation.toReverseSql(adapter.dialect);
      if (sql != null && sql.isNotEmpty) {
        statements.add(sql);
      }
    }

    return statements.join(';\n\n');
  }

  /// Show migration status
  Future<List<MigrationStatus>> status(List<Migration> migrations) async {
    final applied = await getAppliedMigrations();
    final result = <MigrationStatus>[];

    for (final migration in migrations) {
      result.add(MigrationStatus(name: migration.name, isApplied: applied.contains(migration.name)));
    }

    // Add any applied migrations not in the codebase
    for (final name in applied) {
      if (!migrations.any((m) => m.name == name)) {
        result.add(MigrationStatus(name: name, isApplied: true, isMissing: true));
      }
    }

    return result;
  }
}

/// Direction of migration execution.
enum MigrationDirection { up, down }

/// Result of a migration run.
@immutable
class MigrationResult {
  final List<String> applied;
  final List<String> skipped;
  final List<String> rolledBack;
  final List<MigrationError> errors;

  const MigrationResult({
    this.applied = const [],
    this.skipped = const [],
    this.rolledBack = const [],
    this.errors = const [],
  });

  bool get isSuccess => errors.isEmpty;
  bool get hasChanges => applied.isNotEmpty || rolledBack.isNotEmpty;
}

/// Migration error information.
@immutable
class MigrationError {
  final String migrationName;
  final String message;
  final StackTrace? stackTrace;

  const MigrationError(this.migrationName, this.message, this.stackTrace);

  @override
  String toString() => 'MigrationError($migrationName): $message';
}

/// Status of a single migration.
@immutable
class MigrationStatus {
  final String name;
  final bool isApplied;
  final bool isMissing; // Applied but not in codebase

  const MigrationStatus({required this.name, required this.isApplied, this.isMissing = false});
}
