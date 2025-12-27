library;

import 'package:jao/jao.dart';

Future<void> initializeDatabase() async {
  const adapter = SqliteAdapter();
  final config = DatabaseConfig.sqlite('database.db');
  final pool = await adapter.createPool(config);

  await Jao.configure(pool: pool, compiler: SqlCompiler(adapter.dialect));
}

Future<void> closeDatabase() async {
  if (Jao.isInitialized) {
    await Jao.instance.pool.close();
  }
}
