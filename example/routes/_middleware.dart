import 'package:dart_frog/dart_frog.dart';
import 'package:dartonic/dartonic.dart';

/// Middleware that provides the database connection pool to all routes.
/// With dartonic, models are accessed via Model.objects directly after
/// Dartonic.configure() is called, so this is optional for legacy support.
Handler middleware(Handler handler) {
  return handler.use(provider<ConnectionPool>((_) => Dartonic.instance.pool));
}
