/// Example models demonstrating dartonic ORM usage.
///
/// Run `dart run build_runner build` to generate the typed field accessors.
library;

import 'package:dartonic/dartonic.dart';

part 'models.g.dart';

/// An author who can write posts.
@Model()
class Author {
  @AutoField()
  late int id;

  @CharField(maxLength: 100)
  late String name;

  @EmailField(unique: true)
  late String email;

  @IntegerField(min: 0)
  late int age;

  @BooleanField(defaultValue: true)
  late bool isActive;

  @TextField(nullable: true)
  late String? bio;

  @DateTimeField(autoNowAdd: true)
  late DateTime createdAt;

  @DateTimeField(autoNow: true)
  late DateTime updatedAt;
}

/// A blog post written by an author.
@Model()
class Post {
  @AutoField()
  late int id;

  @CharField(maxLength: 200)
  late String title;

  @TextField()
  late String content;

  @ForeignKey(Author, onDelete: OnDelete.cascade)
  late int authorId;

  @BooleanField(defaultValue: false)
  late bool isPublished;

  @DateTimeField(nullable: true)
  late DateTime? publishedAt;

  @DateTimeField(autoNowAdd: true)
  late DateTime createdAt;
}

/// A tag that can be applied to posts.
@Model()
class Tag {
  @AutoField()
  late int id;

  @CharField(maxLength: 50, unique: true)
  late String name;

  @CharField(maxLength: 7, defaultValue: '#3B82F6')
  late String color;
}

/// A comment on a post.
@Model(tableName: 'post_comments')
class Comment {
  @AutoField()
  late int id;

  @ForeignKey(Post, onDelete: OnDelete.cascade)
  late int postId;

  @CharField(maxLength: 100)
  late String authorName;

  @EmailField()
  late String authorEmail;

  @TextField()
  late String content;

  @DateTimeField(autoNowAdd: true)
  late DateTime createdAt;

  @BooleanField(defaultValue: false)
  late bool isApproved;
}
