/// Global Dartonic configuration and model registry.
///
/// Configure once at application startup, then use Manager.objects
/// throughout your application.
///
/// Like Django, just configure your database once:
/// ```dart
/// await Dartonic.configure(
///   pool: connectionPool,
///   compiler: SqlCompiler(SqliteDialect()),
/// );
/// ```
///
/// Then use your models directly:
/// ```dart
/// final authors = await Author.objects.all().toList();
/// ```
library;

import 'db/connection.dart';
import 'db/compiler.dart';
import 'db/executor.dart';

/// Model registration info used by generated code.
class ModelRegistration<T> {
  final String tableName;
  final String pkField;
  final T Function(Map<String, dynamic>) fromRow;
  final Map<String, dynamic> Function(T) toRow;

  /// Column names that should be auto-set to current timestamp on create
  final List<String> autoNowAddFields;

  /// Column names that should be auto-set to current timestamp on every save
  final List<String> autoNowFields;

  const ModelRegistration({
    required this.tableName,
    required this.pkField,
    required this.fromRow,
    required this.toRow,
    this.autoNowAddFields = const [],
    this.autoNowFields = const [],
  });
}

/// Global Dartonic instance for database operations.
///
/// Configure at application startup:
/// ```dart
/// await Dartonic.configure(
///   pool: connectionPool,
///   compiler: SqlCompiler(SqliteDialect()),
/// );
/// ```
class Dartonic {
  static Dartonic? _instance;

  /// The global Dartonic instance.
  ///
  /// Throws if not initialized.
  static Dartonic get instance {
    if (_instance == null) {
      throw StateError(
        'Dartonic not initialized. Call Dartonic.configure() first.',
      );
    }
    return _instance!;
  }

  /// Check if Dartonic is initialized.
  static bool get isInitialized => _instance != null;

  /// The database connection pool.
  final ConnectionPool pool;

  /// The SQL compiler for query generation.
  final SqlCompiler compiler;

  /// Registered model executors (created lazily).
  final Map<Type, ModelExecutor> _executors = {};

  /// Model registrations (from generated code).
  static final Map<Type, ModelRegistration> _registrations = {};

  Dartonic._({required this.pool, required this.compiler});

  /// Configure the global Dartonic instance.
  ///
  /// Call this once at application startup before using any models.
  /// This is similar to Django's DATABASES setting.
  static Future<Dartonic> configure({
    required ConnectionPool pool,
    required SqlCompiler compiler,
  }) async {
    _instance = Dartonic._(pool: pool, compiler: compiler);
    return _instance!;
  }

  /// Reset the global instance. Useful for testing.
  static void reset() {
    _instance?._executors.clear();
    _instance = null;
  }

  /// Register a model type with its serialization functions.
  ///
  /// Called automatically by generated code when a model is first used.
  /// This can be called before Dartonic.configure() - the executor
  /// will be created lazily when first needed.
  static void registerModel<T>(ModelRegistration<T> registration) {
    _registrations[T] = registration;
  }

  /// Get the executor for a model type, creating it if needed.
  ModelExecutor<T>? executor<T>() {
    // Return cached executor if available
    if (_executors.containsKey(T)) {
      return _executors[T] as ModelExecutor<T>;
    }

    // Create executor from registration
    final registration = _registrations[T];
    if (registration == null) {
      return null;
    }

    final reg = registration as ModelRegistration<T>;
    final executor = ModelExecutor<T>(
      pool: pool,
      compiler: compiler,
      tableName: reg.tableName,
      pkField: reg.pkField,
      fromRow: reg.fromRow,
      toRow: reg.toRow,
      autoNowAddFields: reg.autoNowAddFields,
      autoNowFields: reg.autoNowFields,
    );

    _executors[T] = executor;
    return executor;
  }
}
