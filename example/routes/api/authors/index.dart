import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:jao_example/models/models.dart';

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _getAuthors(context),
    HttpMethod.post => _createAuthor(context),
    _ => Future.value(Response(statusCode: HttpStatus.methodNotAllowed)),
  };
}

Future<Response> _getAuthors(RequestContext context) async {
  final params = context.request.uri.queryParameters;

  final page = int.tryParse(params['page'] ?? '1') ?? 1;
  final limit = (int.tryParse(params['limit'] ?? '10') ?? 10).clamp(1, 100);
  final offset = (page - 1) * limit;

  var query = AuthorJao.objects.all();
  if (params['name'] case final name?) {
    query = query.filter(AuthorJao.$.name.iContains(name));
  }

  if (params['email'] case final email?) {
    query = query.filter(AuthorJao.$.email.contains(email));
  }

  if (params['is_active'] case final isActive?) {
    query = query.filter(AuthorJao.$.isActive.eq(isActive == 'true'));
  }

  if (params['min_age'] case final minAge?) {
    if (int.tryParse(minAge) case final age?) {
      query = query.filter(AuthorJao.$.age.gte(age));
    }
  }

  if (params['max_age'] case final maxAge?) {
    if (int.tryParse(maxAge) case final age?) {
      query = query.filter(AuthorJao.$.age.lte(age));
    }
  }

  final orderBy = params['order_by'] ?? 'id';
  final orderDesc = params['order'] == 'desc';

  query = switch (orderBy) {
    'name' => query.orderBy(orderDesc ? AuthorJao.$.name.desc() : AuthorJao.$.name.asc()),
    'email' => query.orderBy(orderDesc ? AuthorJao.$.email.desc() : AuthorJao.$.email.asc()),
    'age' => query.orderBy(orderDesc ? AuthorJao.$.age.desc() : AuthorJao.$.age.asc()),
    'created_at' => query.orderBy(orderDesc ? AuthorJao.$.createdAt.desc() : AuthorJao.$.createdAt.asc()),
    _ => query.orderBy(orderDesc ? AuthorJao.$.id.desc() : AuthorJao.$.id.asc()),
  };

  final total = await AuthorJao.objects.count();
  final authors = await query.offset(offset).limit(limit).toList();

  return Response.json(
    body: {
      'data': authors.map(_authorToJson).toList(),
      'meta': {'page': page, 'limit': limit, 'total': total, 'total_pages': (total / limit).ceil()},
    },
  );
}

Future<Response> _createAuthor(RequestContext context) async {
  final body = await context.request.json() as Map<String, dynamic>;

  final errors = <String>[];
  if (body['name'] == null) errors.add('name is required');
  if (body['email'] == null) errors.add('email is required');
  if (body['age'] == null) errors.add('age is required');

  if (errors.isNotEmpty) {
    return Response.json(statusCode: HttpStatus.badRequest, body: {'errors': errors});
  }

  final author = await AuthorJao.objects.create({
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
