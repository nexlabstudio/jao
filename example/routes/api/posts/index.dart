import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dartonic_example/models/models.dart';

/// GET /api/posts - List posts with filtering and pagination
/// POST /api/posts - Create a new post
Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _getPosts(context),
    HttpMethod.post => _createPost(context),
    _ => Future.value(Response(statusCode: HttpStatus.methodNotAllowed)),
  };
}

/// GET /api/posts
///
/// Query parameters:
/// - page, limit: Pagination
/// - title: Filter by title (contains)
/// - author_id: Filter by author
/// - is_published: Filter by published status
/// - order_by: Field to order by
/// - order: asc/desc
Future<Response> _getPosts(RequestContext context) async {
  final params = context.request.uri.queryParameters;

  // Pagination
  final page = int.tryParse(params['page'] ?? '1') ?? 1;
  final limit = (int.tryParse(params['limit'] ?? '10') ?? 10).clamp(1, 100);
  final offset = (page - 1) * limit;

  var query = PostDartonic.objects.all();

  // Filters
  if (params['title'] case final title?) {
    query = query.filter(PostDartonic.$.title.iContains(title));
  }

  if (params['author_id'] case final authorId?) {
    if (int.tryParse(authorId) case final id?) {
      query = query.filter(PostDartonic.$.authorId.eq(id));
    }
  }

  if (params['is_published'] case final isPublished?) {
    query = query.filter(PostDartonic.$.isPublished.eq(isPublished == 'true'));
  }

  // Ordering
  final orderBy = params['order_by'] ?? 'id';
  final orderDesc = params['order'] == 'desc';

  query = switch (orderBy) {
    'title' => query.orderBy(orderDesc ? PostDartonic.$.title.desc() : PostDartonic.$.title.asc()),
    'created_at' => query.orderBy(orderDesc ? PostDartonic.$.createdAt.desc() : PostDartonic.$.createdAt.asc()),
    _ => query.orderBy(orderDesc ? PostDartonic.$.id.desc() : PostDartonic.$.id.asc()),
  };

  final total = await PostDartonic.objects.count();
  final posts = await query.offset(offset).limit(limit).toList();

  return Response.json(
    body: {
      'data': posts.map(_postToJson).toList(),
      'meta': {'page': page, 'limit': limit, 'total': total, 'total_pages': (total / limit).ceil()},
    },
  );
}

/// POST /api/posts
Future<Response> _createPost(RequestContext context) async {
  final body = await context.request.json() as Map<String, dynamic>;

  final errors = <String>[];
  if (body['title'] == null) errors.add('title is required');
  if (body['content'] == null) errors.add('content is required');
  if (body['author_id'] == null) errors.add('author_id is required');

  if (errors.isNotEmpty) {
    return Response.json(statusCode: HttpStatus.badRequest, body: {'errors': errors});
  }

  // autoNowAdd field (created_at) is automatically set by the ORM
  final post = await PostDartonic.objects.create({
    'title': body['title'],
    'content': body['content'],
    'author_id': body['author_id'],
    'is_published': body['is_published'] ?? false,
    'published_at': body['is_published'] == true ? DateTime.now().toIso8601String() : null,
  });

  return Response.json(statusCode: HttpStatus.created, body: _postToJson(post));
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
