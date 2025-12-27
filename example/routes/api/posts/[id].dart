import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dartonic_example/models/models.dart';

/// Single post operations
Future<Response> onRequest(RequestContext context, String id) async {
  final postId = int.tryParse(id);
  if (postId == null) {
    return Response.json(statusCode: HttpStatus.badRequest, body: {'error': 'Invalid post ID'});
  }

  return switch (context.request.method) {
    HttpMethod.get => _getPost(postId),
    HttpMethod.put => _replacePost(context, postId),
    HttpMethod.patch => _updatePost(context, postId),
    HttpMethod.delete => _deletePost(postId),
    _ => Future.value(Response(statusCode: HttpStatus.methodNotAllowed)),
  };
}

Future<Response> _getPost(int id) async {
  try {
    final post = await PostDartonic.objects.get(id);
    return Response.json(body: _postToJson(post));
  } on StateError {
    return Response.json(statusCode: HttpStatus.notFound, body: {'error': 'Post not found'});
  }
}

Future<Response> _replacePost(RequestContext context, int id) async {
  final body = await context.request.json() as Map<String, dynamic>;

  final errors = <String>[];
  if (body['title'] == null) errors.add('title is required');
  if (body['content'] == null) errors.add('content is required');
  if (body['author_id'] == null) errors.add('author_id is required');

  if (errors.isNotEmpty) {
    return Response.json(statusCode: HttpStatus.badRequest, body: {'errors': errors});
  }

  final updated = await PostDartonic.objects.filter(PostDartonic.$.id.eq(id)).update({
    'title': body['title'],
    'content': body['content'],
    'author_id': body['author_id'],
    'is_published': body['is_published'] ?? false,
  });

  if (updated == 0) {
    return Response.json(statusCode: HttpStatus.notFound, body: {'error': 'Post not found'});
  }

  final post = await PostDartonic.objects.get(id);
  return Response.json(body: _postToJson(post));
}

Future<Response> _updatePost(RequestContext context, int id) async {
  final body = await context.request.json() as Map<String, dynamic>;

  if (body.isEmpty) {
    return Response.json(statusCode: HttpStatus.badRequest, body: {'error': 'No fields to update'});
  }

  final updateData = <String, dynamic>{};
  if (body.containsKey('title')) updateData['title'] = body['title'];
  if (body.containsKey('content')) updateData['content'] = body['content'];
  if (body.containsKey('author_id')) updateData['author_id'] = body['author_id'];
  if (body.containsKey('is_published')) {
    updateData['is_published'] = body['is_published'];
    if (body['is_published'] == true) {
      updateData['published_at'] = DateTime.now().toIso8601String();
    }
  }

  final updated = await PostDartonic.objects.filter(PostDartonic.$.id.eq(id)).update(updateData);

  if (updated == 0) {
    return Response.json(statusCode: HttpStatus.notFound, body: {'error': 'Post not found'});
  }

  final post = await PostDartonic.objects.get(id);
  return Response.json(body: _postToJson(post));
}

Future<Response> _deletePost(int id) async {
  final deleted = await PostDartonic.objects.filter(PostDartonic.$.id.eq(id)).delete();

  if (deleted == 0) {
    return Response.json(statusCode: HttpStatus.notFound, body: {'error': 'Post not found'});
  }

  return Response(statusCode: HttpStatus.noContent);
}

Map<String, dynamic> _postToJson(Post post) => {
  'id': post.id,
  'title': post.title,
  'content': post.content,
  'author_id': post.authorId,
  'is_published': post.isPublished,
  'published_at': post.publishedAt?.toIso8601String(),
  'created_at': post.createdAt.toIso8601String(),
};
