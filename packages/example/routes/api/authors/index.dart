import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import '../../../lib/models/models.dart';

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

  var query = Authors.objects.all();
  if (params['name'] case final name?) {
    query = query.filter(Authors.$.name.iContains(name));
  }

  if (params['email'] case final email?) {
    query = query.filter(Authors.$.email.contains(email));
  }

  if (params['is_active'] case final isActive?) {
    query = query.filter(Authors.$.isActive.eq(isActive == 'true'));
  }

  if (params['min_age'] case final minAge?) {
    if (int.tryParse(minAge) case final age?) {
      query = query.filter(Authors.$.age.gte(age));
    }
  }

  if (params['max_age'] case final maxAge?) {
    if (int.tryParse(maxAge) case final age?) {
      query = query.filter(Authors.$.age.lte(age));
    }
  }

  final orderBy = params['order_by'] ?? 'id';
  final orderDesc = params['order'] == 'desc';

  query = switch (orderBy) {
    'name' => query.orderBy(orderDesc ? Authors.$.name.desc() : Authors.$.name.asc()),
    'email' => query.orderBy(orderDesc ? Authors.$.email.desc() : Authors.$.email.asc()),
    'age' => query.orderBy(orderDesc ? Authors.$.age.desc() : Authors.$.age.asc()),
    'created_at' => query.orderBy(orderDesc ? Authors.$.createdAt.desc() : Authors.$.createdAt.asc()),
    _ => query.orderBy(orderDesc ? Authors.$.id.desc() : Authors.$.id.asc()),
  };

  final total = await Authors.objects.count();
  final authors = await query.offset(offset).limit(limit).toList();

  return Response.json(
    body: {
      'data': authors.map(Authors.toRow).toList(),
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

  final author = await Authors.objects.create({
    'name': body['name'],
    'email': body['email'],
    'age': body['age'],
    'is_active': body['is_active'] ?? true,
    'bio': body['bio'],
  });

  return Response.json(statusCode: HttpStatus.created, body: Authors.toRow(author));
}
