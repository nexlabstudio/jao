import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dartonic_example/models/models.dart';

/// GET /api/authors/:id - Get author by ID
/// PUT /api/authors/:id - Replace author
/// PATCH /api/authors/:id - Update author fields
/// DELETE /api/authors/:id - Delete author
Future<Response> onRequest(RequestContext context, String id) async {
  final authorId = int.tryParse(id);
  if (authorId == null) {
    return Response.json(statusCode: HttpStatus.badRequest, body: {'error': 'Invalid author ID'});
  }

  return switch (context.request.method) {
    HttpMethod.get => _getAuthor(authorId),
    HttpMethod.put => _replaceAuthor(context, authorId),
    HttpMethod.patch => _updateAuthor(context, authorId),
    HttpMethod.delete => _deleteAuthor(authorId),
    _ => Future.value(Response(statusCode: HttpStatus.methodNotAllowed)),
  };
}

/// GET /api/authors/:id
Future<Response> _getAuthor(int id) async {
  try {
    final author = await AuthorDartonic.objects.get(id);
    return Response.json(body: _authorToJson(author));
  } on StateError {
    return Response.json(statusCode: HttpStatus.notFound, body: {'error': 'Author not found'});
  }
}

/// PUT /api/authors/:id - Full replacement
Future<Response> _replaceAuthor(RequestContext context, int id) async {
  final body = await context.request.json() as Map<String, dynamic>;

  // Validate required fields for full replacement
  final errors = <String>[];
  if (body['name'] == null) errors.add('name is required');
  if (body['email'] == null) errors.add('email is required');
  if (body['age'] == null) errors.add('age is required');

  if (errors.isNotEmpty) {
    return Response.json(statusCode: HttpStatus.badRequest, body: {'errors': errors});
  }

  final updated = await AuthorDartonic.objects.filter(AuthorDartonic.$.id.eq(id)).update({
    'name': body['name'],
    'email': body['email'],
    'age': body['age'],
    'is_active': body['is_active'] ?? true,
    'bio': body['bio'],
  });

  if (updated == 0) {
    return Response.json(statusCode: HttpStatus.notFound, body: {'error': 'Author not found'});
  }

  final author = await AuthorDartonic.objects.get(id);
  return Response.json(body: _authorToJson(author));
}

/// PATCH /api/authors/:id - Partial update
Future<Response> _updateAuthor(RequestContext context, int id) async {
  final body = await context.request.json() as Map<String, dynamic>;

  if (body.isEmpty) {
    return Response.json(statusCode: HttpStatus.badRequest, body: {'error': 'No fields to update'});
  }

  // Build update map with only provided fields
  final updateData = <String, dynamic>{};
  if (body.containsKey('name')) updateData['name'] = body['name'];
  if (body.containsKey('email')) updateData['email'] = body['email'];
  if (body.containsKey('age')) updateData['age'] = body['age'];
  if (body.containsKey('is_active')) updateData['is_active'] = body['is_active'];
  if (body.containsKey('bio')) updateData['bio'] = body['bio'];

  final updated = await AuthorDartonic.objects.filter(AuthorDartonic.$.id.eq(id)).update(updateData);

  if (updated == 0) {
    return Response.json(statusCode: HttpStatus.notFound, body: {'error': 'Author not found'});
  }

  final author = await AuthorDartonic.objects.get(id);
  return Response.json(body: _authorToJson(author));
}

/// DELETE /api/authors/:id
Future<Response> _deleteAuthor(int id) async {
  final deleted = await AuthorDartonic.objects.filter(AuthorDartonic.$.id.eq(id)).delete();

  if (deleted == 0) {
    return Response.json(statusCode: HttpStatus.notFound, body: {'error': 'Author not found'});
  }

  return Response(statusCode: HttpStatus.noContent);
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
