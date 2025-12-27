library;

import 'package:jao/jao.dart';

part 'models.g.dart';

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

@Model()
class Tag {
  @AutoField()
  late int id;

  @CharField(maxLength: 50, unique: true)
  late String name;

  @CharField(maxLength: 7, defaultValue: '#3B82F6')
  late String color;
}

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
