import 'package:dart_frog/dart_frog.dart';
import 'package:jao/jao.dart';

Handler middleware(Handler handler) {
  return (context) async {
    await Jao.configure(
      adapter: SqliteAdapter(),
      config: DatabaseConfig.sqlite('database.db'),
    );
    return handler(context);
  };
}
