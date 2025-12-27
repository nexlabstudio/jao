import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import '../../../lib/models/models.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final commentId = int.tryParse(id);
  if (commentId == null) {
    return Response.json(statusCode: HttpStatus.badRequest, body: {'error': 'Invalid comment ID'});
  }

  return switch (context.request.method) {
    HttpMethod.get => _getComment(commentId),
    HttpMethod.patch => _updateComment(context, commentId),
    HttpMethod.delete => _deleteComment(commentId),
    _ => Future.value(Response(statusCode: HttpStatus.methodNotAllowed)),
  };
}

Future<Response> _getComment(int id) async {
  try {
    final comment = await Comments.objects.get(id);
    return Response.json(body: Comments.toRow(comment));
  } on StateError {
    return Response.json(statusCode: HttpStatus.notFound, body: {'error': 'Comment not found'});
  }
}

Future<Response> _updateComment(RequestContext context, int id) async {
  final body = await context.request.json() as Map<String, dynamic>;

  final updateData = <String, dynamic>{};
  if (body.containsKey('is_approved')) updateData['is_approved'] = body['is_approved'];
  if (body.containsKey('content')) updateData['content'] = body['content'];

  if (updateData.isEmpty) {
    return Response.json(statusCode: HttpStatus.badRequest, body: {'error': 'No fields to update'});
  }

  final updated = await Comments.objects.filter(Comments.$.id.eq(id)).update(updateData);

  if (updated == 0) {
    return Response.json(statusCode: HttpStatus.notFound, body: {'error': 'Comment not found'});
  }

  final comment = await Comments.objects.get(id);
  return Response.json(body: Comments.toRow(comment));
}

Future<Response> _deleteComment(int id) async {
  final deleted = await Comments.objects.filter(Comments.$.id.eq(id)).delete();

  if (deleted == 0) {
    return Response.json(statusCode: HttpStatus.notFound, body: {'error': 'Comment not found'});
  }

  return Response(statusCode: HttpStatus.noContent);
}
