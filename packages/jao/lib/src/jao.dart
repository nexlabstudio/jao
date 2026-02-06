library;

import 'db/connection.dart';
import 'db/compiler.dart';
import 'db/executor.dart';

class ModelRegistration<T> {
  final String tableName;
  final String pkField;
  final T Function(Map<String, dynamic>) fromRow;
  final Map<String, dynamic> Function(T) toRow;
  final List<String> autoNowAddFields;
  final List<String> autoNowFields;
  final List<String> autoGenerateUuidFields;

  const ModelRegistration({
    required this.tableName,
    required this.pkField,
    required this.fromRow,
    required this.toRow,
    this.autoNowAddFields = const [],
    this.autoNowFields = const [],
    this.autoGenerateUuidFields = const [],
  });
}

class Jao {
  static Jao? _instance;

  static Jao get instance => switch (_instance) {
        final i? => i,
        null => throw StateError('Jao not initialized. Call Jao.configure() first.'),
      };

  static bool get isInitialized => _instance != null;

  final ConnectionPool pool;
  final SqlCompiler compiler;
  final Map<Type, ModelExecutor> _executors = {};
  static final Map<Type, ModelRegistration> _registrations = {};

  Jao._({required this.pool, required this.compiler});

  static Future<Jao> configure({required DatabaseAdapter adapter, required DatabaseConfig config}) async {
    if (_instance case final existing?) return existing;
    final pool = await adapter.createPool(config);
    final instance = Jao._(pool: pool, compiler: SqlCompiler(adapter.dialect));
    _instance = instance;
    return instance;
  }

  static void reset() {
    _instance?._executors.clear();
    _instance = null;
  }

  static void registerModel<T>(ModelRegistration<T> registration) {
    _registrations[T] = registration;
  }

  ModelExecutor<T>? executor<T>() {
    if (_executors[T] case final existing?) {
      return existing as ModelExecutor<T>;
    }

    if (_registrations[T] case final registration?) {
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
        autoGenerateUuidFields: reg.autoGenerateUuidFields,
      );

      _executors[T] = executor;
      return executor;
    }

    return null;
  }
}
