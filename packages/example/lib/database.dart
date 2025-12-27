library;

import 'package:jao/jao.dart';

Future<void> initializeDatabase() async {
  await Jao.configure(adapter: SqliteAdapter(), config: DatabaseConfig.sqlite('database.db'));
}

Future<void> closeDatabase() async {
  if (Jao.isInitialized) {
    await Jao.instance.pool.close();
  }
}
