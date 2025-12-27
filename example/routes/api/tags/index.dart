import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dartonic_example/models/models.dart';

/// GET /api/tags - List all tags
/// POST /api/tags - Create a new tag
Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _getTags(context),
    HttpMethod.post => _createTag(context),
    _ => Future.value(Response(statusCode: HttpStatus.methodNotAllowed)),
  };
}

Future<Response> _getTags(RequestContext context) async {
  final params = context.request.uri.queryParameters;

  var query = TagDartonic.objects.all();

  // Filter by name
  if (params['name'] case final name?) {
    query = query.filter(TagDartonic.$.name.iContains(name));
  }

  // Order by name
  query = query.orderBy(TagDartonic.$.name.asc());

  final tags = await query.toList();

  return Response.json(body: {'data': tags.map(_tagToJson).toList(), 'count': tags.length});
}

Future<Response> _createTag(RequestContext context) async {
  final body = await context.request.json() as Map<String, dynamic>;

  if (body['name'] == null) {
    return Response.json(statusCode: HttpStatus.badRequest, body: {'error': 'name is required'});
  }

  // Check for duplicate
  final existing = await TagDartonic.objects.filter(TagDartonic.$.name.eq(body['name'] as String)).first();

  if (existing != null) {
    return Response.json(statusCode: HttpStatus.conflict, body: {'error': 'Tag already exists'});
  }

  final tag = await TagDartonic.objects.create({'name': body['name'], 'color': body['color'] ?? '#3B82F6'});

  return Response.json(statusCode: HttpStatus.created, body: _tagToJson(tag));
}

Map<String, dynamic> _tagToJson(Tag tag) => {'id': tag.id, 'name': tag.name, 'color': tag.color};
