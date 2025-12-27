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

  static bool _registered = false;
  static final Manager<Author> _objects = Manager<Author>();

  /// Default manager for database operations.
  static Manager<Author> get objects {
    if (!_registered) {
      _registered = true;
      Dartonic.registerModel<Author>(ModelRegistration(
        tableName: tableName,
        pkField: pkField,
        fromRow: fromRow,
        toRow: (m) => m.toRow(),
        autoNowAddFields: ['created_at'],
        autoNowFields: ['updated_at'],
      ));
    }
    return _objects;
  }

  /// Database table name.
  static const tableName = 'author';

  /// Primary key field name.
  static const pkField = 'id';

  /// List of all field names.
  static const fieldNames = [
    'id',
    'name',
    'email',
    'age',
    'isActive',
    'bio',
    'createdAt',
    'updatedAt',
  ];

  /// Create instance from database row.
  static Author fromRow(Map<String, dynamic> row) {
    return Author()
      ..id = row['id'] as int
      ..name = row['name'] as String
      ..email = row['email'] as String
      ..age = row['age'] as int
      ..isActive = row['is_active'] == 1 || row['is_active'] == true
      ..bio = row['bio'] as String?
      ..createdAt = DateTime.parse(row['created_at'] as String)
      ..updatedAt = DateTime.parse(row['updated_at'] as String);
  }

  /// Convert instance to database row.
  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'age': age,
      'is_active': isActive,
      'bio': bio,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Model schema for migrations.
  static final schema = ModelSchema(
    className: 'Author',
    tableName: 'author',
    fields: [
      ModelFieldSchema(
        name: 'id',
        columnName: 'id',
        dbType: FieldType.serial,
        nullable: false,
        primaryKey: true,
        autoIncrement: true,
        autoNowAdd: false,
        autoNow: false,
      ),
      ModelFieldSchema(
        name: 'name',
        columnName: 'name',
        dbType: FieldType.varchar,
        nullable: false,
        primaryKey: false,
        autoIncrement: false,
        autoNowAdd: false,
        autoNow: false,
      ),
      ModelFieldSchema(
        name: 'email',
        columnName: 'email',
        dbType: FieldType.varchar,
        nullable: false,
        primaryKey: false,
        autoIncrement: false,
        autoNowAdd: false,
        autoNow: false,
      ),
      ModelFieldSchema(
        name: 'age',
        columnName: 'age',
        dbType: FieldType.integer,
        nullable: false,
        primaryKey: false,
        autoIncrement: false,
        autoNowAdd: false,
        autoNow: false,
      ),
      ModelFieldSchema(
        name: 'isActive',
        columnName: 'is_active',
        dbType: FieldType.boolean,
        nullable: false,
        primaryKey: false,
        autoIncrement: false,
        autoNowAdd: false,
        autoNow: false,
      ),
      ModelFieldSchema(
        name: 'bio',
        columnName: 'bio',
        dbType: FieldType.text,
        nullable: true,
        primaryKey: false,
        autoIncrement: false,
        autoNowAdd: false,
        autoNow: false,
      ),
      ModelFieldSchema(
        name: 'createdAt',
        columnName: 'created_at',
        dbType: FieldType.timestampTz,
        nullable: false,
        primaryKey: false,
        autoIncrement: false,
        autoNowAdd: true,
        autoNow: false,
      ),
      ModelFieldSchema(
        name: 'updatedAt',
        columnName: 'updated_at',
        dbType: FieldType.timestampTz,
        nullable: false,
        primaryKey: false,
        autoIncrement: false,
        autoNowAdd: false,
        autoNow: true,
      ),
    ],
  );
}

/// Typed field accessors for [Post].
///
/// Use these for type-safe queries:
/// ```dart
/// Post.objects.filter(Post.$.fieldName.eq(value));
/// ```
class Post$ implements ModelFields<Post> {
  const Post$();

  /// Field accessor for [id]
  final id = const IntFieldRef('id');

  /// Field accessor for [title]
  final title = const StringFieldRef('title');

  /// Field accessor for [content]
  final content = const StringFieldRef('content');

  /// Field accessor for [authorId]
  final authorId = const IntFieldRef('author_id');

  /// Field accessor for [isPublished]
  final isPublished = const BoolFieldRef('is_published');

  /// Field accessor for [publishedAt]
  final publishedAt = const DateTimeFieldRef('published_at');

  /// Field accessor for [createdAt]
  final createdAt = const DateTimeFieldRef('created_at');
}

/// Extension providing static accessors for [Post].
extension PostDartonic on Post {
  /// Typed field accessors for queries.
  static const $ = Post$();

  static bool _registered = false;
  static final Manager<Post> _objects = Manager<Post>();

  /// Default manager for database operations.
  static Manager<Post> get objects {
    if (!_registered) {
      _registered = true;
      Dartonic.registerModel<Post>(ModelRegistration(
        tableName: tableName,
        pkField: pkField,
        fromRow: fromRow,
        toRow: (m) => m.toRow(),
        autoNowAddFields: ['created_at'],
      ));
    }
    return _objects;
  }

  /// Database table name.
  static const tableName = 'post';

  /// Primary key field name.
  static const pkField = 'id';

  /// List of all field names.
  static const fieldNames = [
    'id',
    'title',
    'content',
    'authorId',
    'isPublished',
    'publishedAt',
    'createdAt',
  ];

  /// Create instance from database row.
  static Post fromRow(Map<String, dynamic> row) {
    return Post()
      ..id = row['id'] as int
      ..title = row['title'] as String
      ..content = row['content'] as String
      ..authorId = row['author_id'] as int
      ..isPublished = row['is_published'] == 1 || row['is_published'] == true
      ..publishedAt = row['published_at'] == null
          ? null
          : DateTime.parse(row['published_at'] as String)
      ..createdAt = DateTime.parse(row['created_at'] as String);
  }

  /// Convert instance to database row.
  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'author_id': authorId,
      'is_published': isPublished,
      'published_at': publishedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Model schema for migrations.
  static final schema = ModelSchema(
    className: 'Post',
    tableName: 'post',
    fields: [
      ModelFieldSchema(
        name: 'id',
        columnName: 'id',
        dbType: FieldType.serial,
        nullable: false,
        primaryKey: true,
        autoIncrement: true,
        autoNowAdd: false,
        autoNow: false,
      ),
      ModelFieldSchema(
        name: 'title',
        columnName: 'title',
        dbType: FieldType.varchar,
        nullable: false,
        primaryKey: false,
        autoIncrement: false,
        autoNowAdd: false,
        autoNow: false,
      ),
      ModelFieldSchema(
        name: 'content',
        columnName: 'content',
        dbType: FieldType.text,
        nullable: false,
        primaryKey: false,
        autoIncrement: false,
        autoNowAdd: false,
        autoNow: false,
      ),
      ModelFieldSchema(
        name: 'authorId',
        columnName: 'author_id',
        dbType: FieldType.integer,
        nullable: false,
        primaryKey: false,
        autoIncrement: false,
        autoNowAdd: false,
        autoNow: false,
      ),
      ModelFieldSchema(
        name: 'isPublished',
        columnName: 'is_published',
        dbType: FieldType.boolean,
        nullable: false,
        primaryKey: false,
        autoIncrement: false,
        autoNowAdd: false,
        autoNow: false,
      ),
      ModelFieldSchema(
        name: 'publishedAt',
        columnName: 'published_at',
        dbType: FieldType.timestampTz,
        nullable: true,
        primaryKey: false,
        autoIncrement: false,
        autoNowAdd: false,
        autoNow: false,
      ),
      ModelFieldSchema(
        name: 'createdAt',
        columnName: 'created_at',
        dbType: FieldType.timestampTz,
        nullable: false,
        primaryKey: false,
        autoIncrement: false,
        autoNowAdd: true,
        autoNow: false,
      ),
    ],
  );
}

/// Typed field accessors for [Tag].
///
/// Use these for type-safe queries:
/// ```dart
/// Tag.objects.filter(Tag.$.fieldName.eq(value));
/// ```
class Tag$ implements ModelFields<Tag> {
  const Tag$();

  /// Field accessor for [id]
  final id = const IntFieldRef('id');

  /// Field accessor for [name]
  final name = const StringFieldRef('name');

  /// Field accessor for [color]
  final color = const StringFieldRef('color');
}

/// Extension providing static accessors for [Tag].
extension TagDartonic on Tag {
  /// Typed field accessors for queries.
  static const $ = Tag$();

  static bool _registered = false;
  static final Manager<Tag> _objects = Manager<Tag>();

  /// Default manager for database operations.
  static Manager<Tag> get objects {
    if (!_registered) {
      _registered = true;
      Dartonic.registerModel<Tag>(ModelRegistration(
        tableName: tableName,
        pkField: pkField,
        fromRow: fromRow,
        toRow: (m) => m.toRow(),
      ));
    }
    return _objects;
  }

  /// Database table name.
  static const tableName = 'tag';

  /// Primary key field name.
  static const pkField = 'id';

  /// List of all field names.
  static const fieldNames = [
    'id',
    'name',
    'color',
  ];

  /// Create instance from database row.
  static Tag fromRow(Map<String, dynamic> row) {
    return Tag()
      ..id = row['id'] as int
      ..name = row['name'] as String
      ..color = row['color'] as String;
  }

  /// Convert instance to database row.
  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'name': name,
      'color': color,
    };
  }

  /// Model schema for migrations.
  static final schema = ModelSchema(
    className: 'Tag',
    tableName: 'tag',
    fields: [
      ModelFieldSchema(
        name: 'id',
        columnName: 'id',
        dbType: FieldType.serial,
        nullable: false,
        primaryKey: true,
        autoIncrement: true,
        autoNowAdd: false,
        autoNow: false,
      ),
      ModelFieldSchema(
        name: 'name',
        columnName: 'name',
        dbType: FieldType.varchar,
        nullable: false,
        primaryKey: false,
        autoIncrement: false,
        autoNowAdd: false,
        autoNow: false,
      ),
      ModelFieldSchema(
        name: 'color',
        columnName: 'color',
        dbType: FieldType.varchar,
        nullable: false,
        primaryKey: false,
        autoIncrement: false,
        autoNowAdd: false,
        autoNow: false,
      ),
    ],
  );
}

/// Typed field accessors for [Comment].
///
/// Use these for type-safe queries:
/// ```dart
/// Comment.objects.filter(Comment.$.fieldName.eq(value));
/// ```
class Comment$ implements ModelFields<Comment> {
  const Comment$();

  /// Field accessor for [id]
  final id = const IntFieldRef('id');

  /// Field accessor for [postId]
  final postId = const IntFieldRef('post_id');

  /// Field accessor for [authorName]
  final authorName = const StringFieldRef('author_name');

  /// Field accessor for [authorEmail]
  final authorEmail = const StringFieldRef('author_email');

  /// Field accessor for [content]
  final content = const StringFieldRef('content');

  /// Field accessor for [createdAt]
  final createdAt = const DateTimeFieldRef('created_at');

  /// Field accessor for [isApproved]
  final isApproved = const BoolFieldRef('is_approved');
}

/// Extension providing static accessors for [Comment].
extension CommentDartonic on Comment {
  /// Typed field accessors for queries.
  static const $ = Comment$();

  static bool _registered = false;
  static final Manager<Comment> _objects = Manager<Comment>();

  /// Default manager for database operations.
  static Manager<Comment> get objects {
    if (!_registered) {
      _registered = true;
      Dartonic.registerModel<Comment>(ModelRegistration(
        tableName: tableName,
        pkField: pkField,
        fromRow: fromRow,
        toRow: (m) => m.toRow(),
        autoNowAddFields: ['created_at'],
      ));
    }
    return _objects;
  }

  /// Database table name.
  static const tableName = 'post_comments';

  /// Primary key field name.
  static const pkField = 'id';

  /// List of all field names.
  static const fieldNames = [
    'id',
    'postId',
    'authorName',
    'authorEmail',
    'content',
    'createdAt',
    'isApproved',
  ];

  /// Create instance from database row.
  static Comment fromRow(Map<String, dynamic> row) {
    return Comment()
      ..id = row['id'] as int
      ..postId = row['post_id'] as int
      ..authorName = row['author_name'] as String
      ..authorEmail = row['author_email'] as String
      ..content = row['content'] as String
      ..createdAt = DateTime.parse(row['created_at'] as String)
      ..isApproved = row['is_approved'] == 1 || row['is_approved'] == true;
  }

  /// Convert instance to database row.
  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'post_id': postId,
      'author_name': authorName,
      'author_email': authorEmail,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'is_approved': isApproved,
    };
  }

  /// Model schema for migrations.
  static final schema = ModelSchema(
    className: 'Comment',
    tableName: 'post_comments',
    fields: [
      ModelFieldSchema(
        name: 'id',
        columnName: 'id',
        dbType: FieldType.serial,
        nullable: false,
        primaryKey: true,
        autoIncrement: true,
        autoNowAdd: false,
        autoNow: false,
      ),
      ModelFieldSchema(
        name: 'postId',
        columnName: 'post_id',
        dbType: FieldType.integer,
        nullable: false,
        primaryKey: false,
        autoIncrement: false,
        autoNowAdd: false,
        autoNow: false,
      ),
      ModelFieldSchema(
        name: 'authorName',
        columnName: 'author_name',
        dbType: FieldType.varchar,
        nullable: false,
        primaryKey: false,
        autoIncrement: false,
        autoNowAdd: false,
        autoNow: false,
      ),
      ModelFieldSchema(
        name: 'authorEmail',
        columnName: 'author_email',
        dbType: FieldType.varchar,
        nullable: false,
        primaryKey: false,
        autoIncrement: false,
        autoNowAdd: false,
        autoNow: false,
      ),
      ModelFieldSchema(
        name: 'content',
        columnName: 'content',
        dbType: FieldType.text,
        nullable: false,
        primaryKey: false,
        autoIncrement: false,
        autoNowAdd: false,
        autoNow: false,
      ),
      ModelFieldSchema(
        name: 'createdAt',
        columnName: 'created_at',
        dbType: FieldType.timestampTz,
        nullable: false,
        primaryKey: false,
        autoIncrement: false,
        autoNowAdd: true,
        autoNow: false,
      ),
      ModelFieldSchema(
        name: 'isApproved',
        columnName: 'is_approved',
        dbType: FieldType.boolean,
        nullable: false,
        primaryKey: false,
        autoIncrement: false,
        autoNowAdd: false,
        autoNow: false,
      ),
    ],
  );
}
