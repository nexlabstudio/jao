// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JaoGenerator
// **************************************************************************

class Author$ implements ModelFields<Author> {
  const Author$();

  final id = const IntFieldRef('id');
  final name = const StringFieldRef('name');
  final email = const StringFieldRef('email');
  final age = const IntFieldRef('age');
  final isActive = const BoolFieldRef('is_active');
  final bio = const StringFieldRef('bio');
  final createdAt = const DateTimeFieldRef('created_at');
  final updatedAt = const DateTimeFieldRef('updated_at');
}

extension AuthorJao on Author {
  static const $ = Author$();
  static bool _registered = false;
  static final Manager<Author> _objects = Manager<Author>();

  static Manager<Author> get objects {
    if (!_registered) {
      _registered = true;
      Jao.registerModel<Author>(ModelRegistration(
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

  static const tableName = 'author';
  static const pkField = 'id';
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

extension PostJao on Post {
  static const $ = Post$();
  static bool _registered = false;
  static final Manager<Post> _objects = Manager<Post>();

  static Manager<Post> get objects {
    if (!_registered) {
      _registered = true;
      Jao.registerModel<Post>(ModelRegistration(
        tableName: tableName,
        pkField: pkField,
        fromRow: fromRow,
        toRow: (m) => m.toRow(),
        autoNowAddFields: ['created_at'],
      ));
    }
    return _objects;
  }

  static const tableName = 'post';
  static const pkField = 'id';
  static const fieldNames = [
    'id',
    'title',
    'content',
    'authorId',
    'isPublished',
    'publishedAt',
    'createdAt',
  ];

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

class Tag$ implements ModelFields<Tag> {
  const Tag$();

  final id = const IntFieldRef('id');
  final name = const StringFieldRef('name');
  final color = const StringFieldRef('color');
}

extension TagJao on Tag {
  static const $ = Tag$();
  static bool _registered = false;
  static final Manager<Tag> _objects = Manager<Tag>();

  static Manager<Tag> get objects {
    if (!_registered) {
      _registered = true;
      Jao.registerModel<Tag>(ModelRegistration(
        tableName: tableName,
        pkField: pkField,
        fromRow: fromRow,
        toRow: (m) => m.toRow(),
      ));
    }
    return _objects;
  }

  static const tableName = 'tag';
  static const pkField = 'id';
  static const fieldNames = [
    'id',
    'name',
    'color',
  ];

  static Tag fromRow(Map<String, dynamic> row) {
    return Tag()
      ..id = row['id'] as int
      ..name = row['name'] as String
      ..color = row['color'] as String;
  }

  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'name': name,
      'color': color,
    };
  }

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

extension CommentJao on Comment {
  static const $ = Comment$();
  static bool _registered = false;
  static final Manager<Comment> _objects = Manager<Comment>();

  static Manager<Comment> get objects {
    if (!_registered) {
      _registered = true;
      Jao.registerModel<Comment>(ModelRegistration(
        tableName: tableName,
        pkField: pkField,
        fromRow: fromRow,
        toRow: (m) => m.toRow(),
        autoNowAddFields: ['created_at'],
      ));
    }
    return _objects;
  }

  static const tableName = 'post_comments';
  static const pkField = 'id';
  static const fieldNames = [
    'id',
    'postId',
    'authorName',
    'authorEmail',
    'content',
    'createdAt',
    'isApproved',
  ];

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
