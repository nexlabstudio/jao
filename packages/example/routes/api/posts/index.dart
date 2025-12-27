import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import '../../../lib/models/models.dart';

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _getPosts(context),
    HttpMethod.post => _createPost(context),
    _ => Future.value(Response(statusCode: HttpStatus.methodNotAllowed)),
  };
}

Future<Response> _getPosts(RequestContext context) async {
  final params = context.request.uri.queryParameters;

  final page = int.tryParse(params['page'] ?? '1') ?? 1;
  final limit = (int.tryParse(params['limit'] ?? '10') ?? 10).clamp(1, 100);
  final offset = (page - 1) * limit;

  var query = Posts.objects.all();
  if (params['title'] case final title?) {
    query = query.filter(Posts.$.title.iContains(title));
  }

  if (params['author_id'] case final authorId?) {
    if (int.tryParse(authorId) case final id?) {
      query = query.filter(Posts.$.authorId.eq(id));
    }
  }

  if (params['is_published'] case final isPublished?) {
    query = query.filter(Posts.$.isPublished.eq(isPublished == 'true'));
  }

  final orderBy = params['order_by'] ?? 'id';
  final orderDesc = params['order'] == 'desc';

  query = switch (orderBy) {
    'title' => query.orderBy(orderDesc ? Posts.$.title.desc() : Posts.$.title.asc()),
    'created_at' => query.orderBy(orderDesc ? Posts.$.createdAt.desc() : Posts.$.createdAt.asc()),
    _ => query.orderBy(orderDesc ? Posts.$.id.desc() : Posts.$.id.asc()),
  };

  final total = await Posts.objects.count();
  final posts = await query.offset(offset).limit(limit).toList();

  return Response.json(
    body: {
      'data': posts.map(Posts.toRow).toList(),
      'meta': {'page': page, 'limit': limit, 'total': total, 'total_pages': (total / limit).ceil()},
    },
  );
}

Future<Response> _createPost(RequestContext context) async {
  final body = await context.request.json() as Map<String, dynamic>;

  final errors = <String>[];
  if (body['title'] == null) errors.add('title is required');
  if (body['content'] == null) errors.add('content is required');
  if (body['author_id'] == null) errors.add('author_id is required');

  if (errors.isNotEmpty) {
    return Response.json(statusCode: HttpStatus.badRequest, body: {'errors': errors});
  }

  final post = await Posts.objects.create({
    'title': body['title'],
    'content': body['content'],
    'author_id': body['author_id'],
    'is_published': body['is_published'] ?? false,
    'published_at': body['is_published'] == true ? DateTime.now().toIso8601String() : null,
  });

  return Response.json(statusCode: HttpStatus.created, body: Posts.toRow(post));
}
