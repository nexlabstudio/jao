import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:jao_example/database.dart';

Future<HttpServer> run(Handler handler, InternetAddress ip, int port) async {
  // Initialize database
  await initializeDatabase();

  return serve(handler, ip, port);
}
