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

  const ModelRegistration({
    required this.tableName,
    required this.pkField,
    required this.fromRow,
    required this.toRow,
    this.autoNowAddFields = const [],
    this.autoNowFields = const [],
  });
}

class Jao {
  static Jao? _instance;

  static Jao get instance {
    if (_instance == null) {
      throw StateError('Jao not initialized. Call Jao.configure() first.');
    }
    return _instance!;
  }

  static bool get isInitialized => _instance != null;

  final ConnectionPool pool;
  final SqlCompiler compiler;
  final Map<Type, ModelExecutor> _executors = {};
  static final Map<Type, ModelRegistration> _registrations = {};

  Jao._({required this.pool, required this.compiler});

  static Future<Jao> configure({required ConnectionPool pool, required SqlCompiler compiler}) async {
    _instance = Jao._(pool: pool, compiler: compiler);
    return _instance!;
  }

  static void reset() {
    _instance?._executors.clear();
    _instance = null;
  }

  static void registerModel<T>(ModelRegistration<T> registration) {
    _registrations[T] = registration;
  }

  ModelExecutor<T>? executor<T>() {
    if (_executors.containsKey(T)) {
      return _executors[T] as ModelExecutor<T>;
    }

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
