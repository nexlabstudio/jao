import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:jao_example/models/models.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final tagId = int.tryParse(id);
  if (tagId == null) {
    return Response.json(statusCode: HttpStatus.badRequest, body: {'error': 'Invalid tag ID'});
  }

  return switch (context.request.method) {
    HttpMethod.get => _getTag(tagId),
    HttpMethod.put => _updateTag(context, tagId),
    HttpMethod.delete => _deleteTag(tagId),
    _ => Future.value(Response(statusCode: HttpStatus.methodNotAllowed)),
  };
}

Future<Response> _getTag(int id) async {
  try {
    final tag = await Tags.objects.get(id);
    return Response.json(body: Tags.toRow(tag));
  } on StateError {
    return Response.json(statusCode: HttpStatus.notFound, body: {'error': 'Tag not found'});
  }
}

Future<Response> _updateTag(RequestContext context, int id) async {
  final body = await context.request.json() as Map<String, dynamic>;

  final updateData = <String, dynamic>{};
  if (body.containsKey('name')) updateData['name'] = body['name'];
  if (body.containsKey('color')) updateData['color'] = body['color'];

  if (updateData.isEmpty) {
    return Response.json(statusCode: HttpStatus.badRequest, body: {'error': 'No fields to update'});
  }

  final updated = await Tags.objects.filter(Tags.$.id.eq(id)).update(updateData);

  if (updated == 0) {
    return Response.json(statusCode: HttpStatus.notFound, body: {'error': 'Tag not found'});
  }

  final tag = await Tags.objects.get(id);
  return Response.json(body: Tags.toRow(tag));
}

Future<Response> _deleteTag(int id) async {
  final deleted = await Tags.objects.filter(Tags.$.id.eq(id)).delete();

  if (deleted == 0) {
    return Response.json(statusCode: HttpStatus.notFound, body: {'error': 'Tag not found'});
  }

  return Response(statusCode: HttpStatus.noContent);
}
