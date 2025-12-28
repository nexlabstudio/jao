import 'package:dart_frog/dart_frog.dart';
import 'package:jao/jao.dart';

import '../lib/config/database.dart';

Handler middleware(Handler handler) {
  return (context) async {
    await Jao.configure(
      adapter: databaseAdapter,
      config: databaseConfig,
    );
    return handler(context);
  };
}
