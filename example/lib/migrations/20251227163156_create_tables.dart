import 'package:dartonic/dartonic.dart';

class CreateTables extends Migration {
  @override
  String get name => 'create_tables';

  @override
  void up(MigrationBuilder builder) {
    builder.createTable('author', (table) {
      table.id('id');
      table.string('name', length: 255);
      table.string('email', length: 255);
      table.integer('age');
      table.boolean('is_active');
      table.text('bio', nullable: true);
      table.timestampTz('created_at');
      table.timestampTz('updated_at');
    });
    builder.createTable('post', (table) {
      table.id('id');
      table.string('title', length: 255);
      table.text('content');
      table.integer('author_id');
      table.boolean('is_published');
      table.timestampTz('published_at', nullable: true);
      table.timestampTz('created_at');
    });
    builder.createTable('tag', (table) {
      table.id('id');
      table.string('name', length: 255);
      table.string('color', length: 255);
    });
    builder.createTable('post_comments', (table) {
      table.id('id');
      table.integer('post_id');
      table.string('author_name', length: 255);
      table.string('author_email', length: 255);
      table.text('content');
      table.timestampTz('created_at');
      table.boolean('is_approved');
    });
  }

  @override
  void down(MigrationBuilder builder) {
    builder.dropTable('post_comments');
    builder.dropTable('tag');
    builder.dropTable('post');
    builder.dropTable('author');
  }
}
