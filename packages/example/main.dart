import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:jao/jao.dart';
import 'package:jao_example/config/database.dart';

Future<HttpServer> run(Handler handler, InternetAddress ip, int port) async {
  await Jao.configure(adapter: databaseAdapter, config: databaseConfig);

  return serve(handler, ip, port);
}
