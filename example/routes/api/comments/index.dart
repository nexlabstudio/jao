import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dartonic_example/models/models.dart';

/// GET /api/comments - List comments with filtering
/// POST /api/comments - Create a new comment
Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _getComments(context),
    HttpMethod.post => _createComment(context),
    _ => Future.value(Response(statusCode: HttpStatus.methodNotAllowed)),
  };
}

/// GET /api/comments
///
/// Query parameters:
/// - post_id: Filter by post (required for list)
/// - is_approved: Filter by approval status
/// - page, limit: Pagination
Future<Response> _getComments(RequestContext context) async {
  final params = context.request.uri.queryParameters;

  // Pagination
  final page = int.tryParse(params['page'] ?? '1') ?? 1;
  final limit = (int.tryParse(params['limit'] ?? '20') ?? 20).clamp(1, 100);
  final offset = (page - 1) * limit;

  var query = CommentDartonic.objects.all();

  // Filter by post
  if (params['post_id'] case final postId?) {
    if (int.tryParse(postId) case final id?) {
      query = query.filter(CommentDartonic.$.postId.eq(id));
    }
  }

  // Filter by approval status
  if (params['is_approved'] case final isApproved?) {
    query = query.filter(CommentDartonic.$.isApproved.eq(isApproved == 'true'));
  }

  // Filter by author email
  if (params['author_email'] case final email?) {
    query = query.filter(CommentDartonic.$.authorEmail.eq(email));
  }

  // Order by created_at descending (newest first)
  query = query.orderBy(CommentDartonic.$.createdAt.desc());

  final total = await CommentDartonic.objects.count();
  final comments = await query.offset(offset).limit(limit).toList();

  return Response.json(
    body: {
      'data': comments.map(_commentToJson).toList(),
      'meta': {'page': page, 'limit': limit, 'total': total, 'total_pages': (total / limit).ceil()},
    },
  );
}

/// POST /api/comments
Future<Response> _createComment(RequestContext context) async {
  final body = await context.request.json() as Map<String, dynamic>;

  final errors = <String>[];
  if (body['post_id'] == null) errors.add('post_id is required');
  if (body['author_name'] == null) errors.add('author_name is required');
  if (body['author_email'] == null) errors.add('author_email is required');
  if (body['content'] == null) errors.add('content is required');

  if (errors.isNotEmpty) {
    return Response.json(statusCode: HttpStatus.badRequest, body: {'errors': errors});
  }

  // Verify post exists
  try {
    await PostDartonic.objects.get(body['post_id'] as int);
  } on StateError {
    return Response.json(statusCode: HttpStatus.badRequest, body: {'error': 'Post not found'});
  }

  final comment = await CommentDartonic.objects.create({
    'post_id': body['post_id'],
    'author_name': body['author_name'],
    'author_email': body['author_email'],
    'content': body['content'],
    'is_approved': false, // Comments require approval
  });

  return Response.json(statusCode: HttpStatus.created, body: _commentToJson(comment));
}

Map<String, dynamic> _commentToJson(Comment comment) => {
  'id': comment.id,
  'post_id': comment.postId,
  'author_name': comment.authorName,
  'author_email': comment.authorEmail,
  'content': comment.content,
  'is_approved': comment.isApproved,
  'created_at': comment.createdAt.toIso8601String(),
};
