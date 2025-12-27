import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:jao_example/models/models.dart';

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _getComments(context),
    HttpMethod.post => _createComment(context),
    _ => Future.value(Response(statusCode: HttpStatus.methodNotAllowed)),
  };
}

Future<Response> _getComments(RequestContext context) async {
  final params = context.request.uri.queryParameters;

  final page = int.tryParse(params['page'] ?? '1') ?? 1;
  final limit = (int.tryParse(params['limit'] ?? '20') ?? 20).clamp(1, 100);
  final offset = (page - 1) * limit;

  var query = Comments.objects.all();

  if (params['post_id'] case final postId?) {
    if (int.tryParse(postId) case final id?) {
      query = query.filter(Comments.$.postId.eq(id));
    }
  }

  if (params['is_approved'] case final isApproved?) {
    query = query.filter(Comments.$.isApproved.eq(isApproved == 'true'));
  }

  if (params['author_email'] case final email?) {
    query = query.filter(Comments.$.authorEmail.eq(email));
  }

  query = query.orderBy(Comments.$.createdAt.desc());

  final total = await Comments.objects.count();
  final comments = await query.offset(offset).limit(limit).toList();

  return Response.json(
    body: {
      'data': comments.map(Comments.toRow).toList(),
      'meta': {'page': page, 'limit': limit, 'total': total, 'total_pages': (total / limit).ceil()},
    },
  );
}

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

  try {
    await Posts.objects.get(body['post_id'] as int);
  } on StateError {
    return Response.json(statusCode: HttpStatus.badRequest, body: {'error': 'Post not found'});
  }

  final comment = await Comments.objects.create({
    'post_id': body['post_id'],
    'author_name': body['author_name'],
    'author_email': body['author_email'],
    'content': body['content'],
    'is_approved': false,
  });

  return Response.json(statusCode: HttpStatus.created, body: Comments.toRow(comment));
}
