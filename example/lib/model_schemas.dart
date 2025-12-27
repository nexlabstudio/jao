/// Model schemas for auto-migration detection.
///
/// This file defines the schema representations of your models
/// that the migration system uses to detect changes.
///
/// These are typically generated, but can be written manually.
library;

import 'package:dartonic/dartonic.dart';

/// Schema for Author model.
final authorSchema = ModelSchema(
  className: 'Author',
  tableName: 'author',
  fields: [
    ModelFieldSchema(name: 'id', columnName: 'id', dbType: FieldType.serial, primaryKey: true, autoIncrement: true),
    ModelFieldSchema(name: 'name', columnName: 'name', dbType: FieldType.varchar, maxLength: 100),
    ModelFieldSchema(name: 'email', columnName: 'email', dbType: FieldType.varchar, maxLength: 254, unique: true),
    ModelFieldSchema(name: 'age', columnName: 'age', dbType: FieldType.integer),
    ModelFieldSchema(name: 'isActive', columnName: 'is_active', dbType: FieldType.boolean, defaultValue: 'true'),
    ModelFieldSchema(name: 'bio', columnName: 'bio', dbType: FieldType.text, nullable: true),
    ModelFieldSchema(
      name: 'createdAt',
      columnName: 'created_at',
      dbType: FieldType.timestampTz,
      defaultValue: 'CURRENT_TIMESTAMP',
    ),
    ModelFieldSchema(
      name: 'updatedAt',
      columnName: 'updated_at',
      dbType: FieldType.timestampTz,
      defaultValue: 'CURRENT_TIMESTAMP',
    ),
  ],
);

/// Schema for Post model.
final postSchema = ModelSchema(
  className: 'Post',
  tableName: 'post',
  fields: [
    ModelFieldSchema(name: 'id', columnName: 'id', dbType: FieldType.serial, primaryKey: true, autoIncrement: true),
    ModelFieldSchema(name: 'title', columnName: 'title', dbType: FieldType.varchar, maxLength: 200),
    ModelFieldSchema(name: 'content', columnName: 'content', dbType: FieldType.text),
    ModelFieldSchema(
      name: 'authorId',
      columnName: 'author_id',
      dbType: FieldType.integer,
      foreignKey: ForeignKeyInfo(referencedTable: 'author', referencedColumn: 'id', onDelete: OnDeleteAction.cascade),
    ),
    ModelFieldSchema(name: 'isPublished', columnName: 'is_published', dbType: FieldType.boolean, defaultValue: 'false'),
    ModelFieldSchema(name: 'publishedAt', columnName: 'published_at', dbType: FieldType.timestampTz, nullable: true),
    ModelFieldSchema(
      name: 'createdAt',
      columnName: 'created_at',
      dbType: FieldType.timestampTz,
      defaultValue: 'CURRENT_TIMESTAMP',
    ),
  ],
);

/// Schema for Tag model.
final tagSchema = ModelSchema(
  className: 'Tag',
  tableName: 'tag',
  fields: [
    ModelFieldSchema(name: 'id', columnName: 'id', dbType: FieldType.serial, primaryKey: true, autoIncrement: true),
    ModelFieldSchema(name: 'name', columnName: 'name', dbType: FieldType.varchar, maxLength: 50, unique: true),
    ModelFieldSchema(
      name: 'color',
      columnName: 'color',
      dbType: FieldType.varchar,
      maxLength: 7,
      defaultValue: '#3B82F6',
    ),
  ],
);

/// Schema for Comment model.
final commentSchema = ModelSchema(
  className: 'Comment',
  tableName: 'post_comments',
  fields: [
    ModelFieldSchema(name: 'id', columnName: 'id', dbType: FieldType.serial, primaryKey: true, autoIncrement: true),
    ModelFieldSchema(
      name: 'postId',
      columnName: 'post_id',
      dbType: FieldType.integer,
      foreignKey: ForeignKeyInfo(referencedTable: 'post', referencedColumn: 'id', onDelete: OnDeleteAction.cascade),
    ),
    ModelFieldSchema(name: 'authorName', columnName: 'author_name', dbType: FieldType.varchar, maxLength: 100),
    ModelFieldSchema(name: 'authorEmail', columnName: 'author_email', dbType: FieldType.varchar, maxLength: 254),
    ModelFieldSchema(name: 'content', columnName: 'content', dbType: FieldType.text),
    ModelFieldSchema(
      name: 'createdAt',
      columnName: 'created_at',
      dbType: FieldType.timestampTz,
      defaultValue: 'CURRENT_TIMESTAMP',
    ),
    ModelFieldSchema(name: 'isApproved', columnName: 'is_approved', dbType: FieldType.boolean, defaultValue: 'false'),
  ],
);

/// All model schemas for migration detection.
final allModelSchemas = <ModelSchema>[authorSchema, postSchema, tagSchema, commentSchema];
