// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// DartonicGenerator
// **************************************************************************

/// Typed field accessors for [Author].
///
/// Use these for type-safe queries:
/// ```dart
/// Author.objects.filter(Author.$.fieldName.eq(value));
/// ```
class Author$ implements ModelFields<Author> {
  const Author$();

  /// Field accessor for [id]
  final id = const IntFieldRef('id');

  /// Field accessor for [name]
  final name = const StringFieldRef('name');

  /// Field accessor for [email]
  final email = const StringFieldRef('email');

  /// Field accessor for [age]
  final age = const IntFieldRef('age');

  /// Field accessor for [isActive]
  final isActive = const BoolFieldRef('is_active');

  /// Field accessor for [bio]
  final bio = const StringFieldRef('bio');

  /// Field accessor for [createdAt]
  final createdAt = const DateTimeFieldRef('created_at');

  /// Field accessor for [updatedAt]
  final updatedAt = const DateTimeFieldRef('updated_at');
}

/// Extension providing static accessors for [Author].
extension AuthorDartonic on Author {
  /// Typed field accessors for queries.
  static const $ = Author$();

  /// Default manager for database operations.
  static final objects = Manager<Author>();

  /// Database table name.
  static const tableName = 'author';

  /// Primary key field name.
  static const pkField = 'id';

  /// List of all field names.
  static const fieldNames = ['id', 'name', 'email', 'age', 'isActive', 'bio', 'createdAt', 'updatedAt'];
}

/// Typed field accessors for [Post].
class Post$ implements ModelFields<Post> {
  const Post$();

  final id = const IntFieldRef('id');
  final title = const StringFieldRef('title');
  final content = const StringFieldRef('content');
  final authorId = const IntFieldRef('author_id');
  final isPublished = const BoolFieldRef('is_published');
  final publishedAt = const DateTimeFieldRef('published_at');
  final createdAt = const DateTimeFieldRef('created_at');
}

extension PostDartonic on Post {
  static const $ = Post$();
  static final objects = Manager<Post>();
  static const tableName = 'post';
  static const pkField = 'id';
  static const fieldNames = ['id', 'title', 'content', 'authorId', 'isPublished', 'publishedAt', 'createdAt'];
}

/// Typed field accessors for [Tag].
class Tag$ implements ModelFields<Tag> {
  const Tag$();

  final id = const IntFieldRef('id');
  final name = const StringFieldRef('name');
  final color = const StringFieldRef('color');
}

extension TagDartonic on Tag {
  static const $ = Tag$();
  static final objects = Manager<Tag>();
  static const tableName = 'tag';
  static const pkField = 'id';
  static const fieldNames = ['id', 'name', 'color'];
}

/// Typed field accessors for [Comment].
class Comment$ implements ModelFields<Comment> {
  const Comment$();

  final id = const IntFieldRef('id');
  final postId = const IntFieldRef('post_id');
  final authorName = const StringFieldRef('author_name');
  final authorEmail = const StringFieldRef('author_email');
  final content = const StringFieldRef('content');
  final createdAt = const DateTimeFieldRef('created_at');
  final isApproved = const BoolFieldRef('is_approved');
}

extension CommentDartonic on Comment {
  static const $ = Comment$();
  static final objects = Manager<Comment>();
  static const tableName = 'post_comments';
  static const pkField = 'id';
  static const fieldNames = ['id', 'postId', 'authorName', 'authorEmail', 'content', 'createdAt', 'isApproved'];
}
