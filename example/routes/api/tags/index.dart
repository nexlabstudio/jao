import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:jao_example/models/models.dart';

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _getTags(context),
    HttpMethod.post => _createTag(context),
    _ => Future.value(Response(statusCode: HttpStatus.methodNotAllowed)),
  };
}

Future<Response> _getTags(RequestContext context) async {
  final params = context.request.uri.queryParameters;

  var query = Tags.objects.all();

  if (params['name'] case final name?) {
    query = query.filter(Tags.$.name.iContains(name));
  }

  query = query.orderBy(Tags.$.name.asc());

  final tags = await query.toList();

  return Response.json(body: {'data': tags.map(_tagToJson).toList(), 'count': tags.length});
}

Future<Response> _createTag(RequestContext context) async {
  final body = await context.request.json() as Map<String, dynamic>;

  if (body['name'] == null) {
    return Response.json(statusCode: HttpStatus.badRequest, body: {'error': 'name is required'});
  }

  final existing = await Tags.objects.filter(Tags.$.name.eq(body['name'] as String)).first();

  if (existing != null) {
    return Response.json(statusCode: HttpStatus.conflict, body: {'error': 'Tag already exists'});
  }

  final tag = await Tags.objects.create({'name': body['name'], 'color': body['color'] ?? '#3B82F6'});

  return Response.json(statusCode: HttpStatus.created, body: _tagToJson(tag));
}

Map<String, dynamic> _tagToJson(Tag tag) => {'id': tag.id, 'name': tag.name, 'color': tag.color};
