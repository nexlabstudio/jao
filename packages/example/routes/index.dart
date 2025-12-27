import 'package:dart_frog/dart_frog.dart';

Response onRequest(RequestContext context) {
  return Response.json(
    body: {
      'name': 'JAO Example API',
      'version': '0.1.0',
      'description': 'A Dart Frog API demonstrating JAO ORM with SQLite',
      'endpoints': {'authors': '/api/authors', 'posts': '/api/posts', 'tags': '/api/tags', 'comments': '/api/comments'},
    },
  );
}
