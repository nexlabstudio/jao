import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dartonic_example/models/models.dart';

/// GET /api/authors - List authors with filtering and pagination
/// POST /api/authors - Create a new author
Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _getAuthors(context),
    HttpMethod.post => _createAuthor(context),
    _ => Future.value(Response(statusCode: HttpStatus.methodNotAllowed)),
  };
}

/// GET /api/authors
///
/// Query parameters:
/// - page: Page number (default: 1)
/// - limit: Items per page (default: 10, max: 100)
/// - name: Filter by name (contains, case-insensitive)
/// - email: Filter by email (contains)
/// - is_active: Filter by active status (true/false)
/// - min_age: Minimum age filter
/// - max_age: Maximum age filter
/// - order_by: Field to order by (name, email, age, created_at)
/// - order: Sort order (asc/desc, default: asc)
Future<Response> _getAuthors(RequestContext context) async {
  final params = context.request.uri.queryParameters;

  // Pagination
  final page = int.tryParse(params['page'] ?? '1') ?? 1;
  final limit = (int.tryParse(params['limit'] ?? '10') ?? 10).clamp(1, 100);
  final offset = (page - 1) * limit;

  // Build query
  var query = AuthorDartonic.objects.all();

  // Apply filters
  if (params['name'] case final name?) {
    query = query.filter(AuthorDartonic.$.name.iContains(name));
  }

  if (params['email'] case final email?) {
    query = query.filter(AuthorDartonic.$.email.contains(email));
  }

  if (params['is_active'] case final isActive?) {
    query = query.filter(AuthorDartonic.$.isActive.eq(isActive == 'true'));
  }

  if (params['min_age'] case final minAge?) {
    if (int.tryParse(minAge) case final age?) {
      query = query.filter(AuthorDartonic.$.age.gte(age));
    }
  }

  if (params['max_age'] case final maxAge?) {
    if (int.tryParse(maxAge) case final age?) {
      query = query.filter(AuthorDartonic.$.age.lte(age));
    }
  }

  // Ordering
  final orderBy = params['order_by'] ?? 'id';
  final orderDesc = params['order'] == 'desc';

  query = switch (orderBy) {
    'name' => query.orderBy(orderDesc ? AuthorDartonic.$.name.desc() : AuthorDartonic.$.name.asc()),
    'email' => query.orderBy(orderDesc ? AuthorDartonic.$.email.desc() : AuthorDartonic.$.email.asc()),
    'age' => query.orderBy(orderDesc ? AuthorDartonic.$.age.desc() : AuthorDartonic.$.age.asc()),
    'created_at' => query.orderBy(orderDesc ? AuthorDartonic.$.createdAt.desc() : AuthorDartonic.$.createdAt.asc()),
    _ => query.orderBy(orderDesc ? AuthorDartonic.$.id.desc() : AuthorDartonic.$.id.asc()),
  };

  // Get total count for pagination metadata
  final total = await AuthorDartonic.objects.count();

  // Apply pagination
  final authors = await query.offset(offset).limit(limit).toList();

  return Response.json(
    body: {
      'data': authors.map(_authorToJson).toList(),
      'meta': {'page': page, 'limit': limit, 'total': total, 'total_pages': (total / limit).ceil()},
    },
  );
}

/// POST /api/authors
Future<Response> _createAuthor(RequestContext context) async {
  final body = await context.request.json() as Map<String, dynamic>;

  // Validate required fields
  final errors = <String>[];
  if (body['name'] == null) errors.add('name is required');
  if (body['email'] == null) errors.add('email is required');
  if (body['age'] == null) errors.add('age is required');

  if (errors.isNotEmpty) {
    return Response.json(statusCode: HttpStatus.badRequest, body: {'errors': errors});
  }

  // autoNowAdd and autoNow fields are automatically set by the ORM
  final author = await AuthorDartonic.objects.create({
    'name': body['name'],
    'email': body['email'],
    'age': body['age'],
    'is_active': body['is_active'] ?? true,
    'bio': body['bio'],
  });

  return Response.json(statusCode: HttpStatus.created, body: _authorToJson(author));
}

Map<String, dynamic> _authorToJson(Author author) => {
  'id': author.id,
  'name': author.name,
  'email': author.email,
  'age': author.age,
  'is_active': author.isActive,
  'bio': author.bio,
  'created_at': author.createdAt.toIso8601String(),
  'updated_at': author.updatedAt.toIso8601String(),
};
