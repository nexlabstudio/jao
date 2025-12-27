library;

import 'package:dartonic/dartonic.dart';

Future<void> initializeDatabase() async {
  const adapter = SqliteAdapter();
  final config = DatabaseConfig.sqlite('database.db');
  final pool = await adapter.createPool(config);

  await Dartonic.configure(pool: pool, compiler: SqlCompiler(adapter.dialect));
}

Future<void> closeDatabase() async {
  if (Dartonic.isInitialized) {
    await Dartonic.instance.pool.close();
  }
}
