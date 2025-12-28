import 'package:dart_frog/dart_frog.dart';

Response onRequest(RequestContext context) {
  return Response.json(
    body: {
      'name': 'Polls API',
      'version': '1.0.0',
      'description': 'A Django-style Polls API built with Dart Frog and JAO ORM',
      'endpoints': {
        'polls': {
          'list': 'GET /api/polls',
          'create': 'POST /api/polls',
          'detail': 'GET /api/polls/:id',
          'update': 'PUT /api/polls/:id',
          'delete': 'DELETE /api/polls/:id',
        },
        'choices': {
          'list': 'GET /api/polls/:id/choices',
          'create': 'POST /api/polls/:id/choices',
        },
        'vote': 'POST /api/polls/:id/vote',
      },
    },
  );
}
