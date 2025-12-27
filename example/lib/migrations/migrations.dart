/// Example migrations for the dartonic ORM.
///
/// Migrations allow you to evolve your database schema over time.
/// Run migrations with the MigrationRunner.
library;

import 'package:dartonic/dartonic.dart';

/// Initial migration - creates the core tables.
class Migration001Initial extends Migration {
  @override
  String get name => '001_initial';

  @override
  void up(MigrationBuilder builder) {
    // Create authors table
    builder.createTable('author', (table) {
      table.id();
      table.string('name', length: 100);
      table.string('email', length: 254);
      table.unique('email');
      table.integer('age');
      table.boolean('is_active', defaultValue: true);
      table.text('bio', nullable: true);
      table.timestamps();
    });

    // Create posts table
    builder.createTable('post', (table) {
      table.id();
      table.string('title', length: 200);
      table.text('content');
      table.foreignKey('author_id', 'author');
      table.boolean('is_published', defaultValue: false);
      table.timestampTz('published_at', nullable: true);
      table.timestampTz('created_at', useCurrent: true);
    });

    // Create tags table
    builder.createTable('tag', (table) {
      table.id();
      table.string('name', length: 50);
      table.unique('name');
      table.string('color', length: 7, defaultValue: "'#3B82F6'");
    });

    // Create post_tags junction table for many-to-many
    builder.createTable('post_tag', (table) {
      table.id();
      table.foreignKey('post_id', 'post');
      table.foreignKey('tag_id', 'tag');
      table.uniqueIndex(['post_id', 'tag_id']);
    });

    // Create comments table
    builder.createTable('post_comments', (table) {
      table.id();
      table.foreignKey('post_id', 'post');
      table.string('author_name', length: 100);
      table.string('author_email', length: 254);
      table.text('content');
      table.timestampTz('created_at', useCurrent: true);
      table.boolean('is_approved', defaultValue: false);
    });

    // Add indexes for common queries
    builder.createIndex('author', ['is_active']);
    builder.createIndex('post', ['is_published']);
    builder.createIndex('post', ['author_id']);
    builder.createIndex('post_comments', ['post_id']);
    builder.createIndex('post_comments', ['is_approved']);
  }

  @override
  void down(MigrationBuilder builder) {
    // Drop in reverse order due to foreign keys
    builder.dropTable('post_comments');
    builder.dropTable('post_tag');
    builder.dropTable('tag');
    builder.dropTable('post');
    builder.dropTable('author');
  }
}

/// Add slug field to posts.
class Migration002AddPostSlug extends Migration {
  @override
  String get name => '002_add_post_slug';

  @override
  List<String> get dependencies => ['001_initial'];

  @override
  void up(MigrationBuilder builder) {
    builder.addStringColumn('post', 'slug', length: 200, nullable: true);
    builder.createUniqueIndex('post', ['slug'], name: 'uq_post_slug');
  }

  @override
  void down(MigrationBuilder builder) {
    builder.dropIndex('uq_post_slug');
    builder.dropColumn('post', 'slug');
  }
}

/// Add view count to posts.
class Migration003AddPostViewCount extends Migration {
  @override
  String get name => '003_add_post_view_count';

  @override
  List<String> get dependencies => ['002_add_post_slug'];

  @override
  void up(MigrationBuilder builder) {
    builder.addIntegerColumn('post', 'view_count', defaultValue: 0);
  }

  @override
  void down(MigrationBuilder builder) {
    builder.dropColumn('post', 'view_count');
  }
}

/// Add soft delete to authors.
class Migration004AddAuthorSoftDelete extends Migration {
  @override
  String get name => '004_add_author_soft_delete';

  @override
  List<String> get dependencies => ['001_initial'];

  @override
  void up(MigrationBuilder builder) {
    builder.addBooleanColumn('author', 'is_deleted', defaultValue: false);
    builder.addTimestampColumn('author', 'deleted_at', nullable: true);
    builder.createIndex('author', ['is_deleted']);
  }

  @override
  void down(MigrationBuilder builder) {
    builder.dropIndex('idx_author_is_deleted');
    builder.dropColumn('author', 'deleted_at');
    builder.dropColumn('author', 'is_deleted');
  }
}

/// Data migration example - populate slugs for existing posts.
class Migration005PopulatePostSlugs extends Migration {
  @override
  String get name => '005_populate_post_slugs';

  @override
  List<String> get dependencies => ['002_add_post_slug'];

  @override
  void up(MigrationBuilder builder) {
    // Use raw SQL for data migrations
    builder.rawSql('''
      UPDATE post 
      SET slug = LOWER(REPLACE(REPLACE(title, ' ', '-'), '.', ''))
      WHERE slug IS NULL
    ''');

    // Then make slug not nullable
    builder.alterColumn('post', 'slug', (col) {
      col.notNullable();
    });
  }

  @override
  void down(MigrationBuilder builder) {
    // Make slug nullable again
    builder.alterColumn('post', 'slug', (col) {
      col.nullable();
    });
  }
}

/// List of all migrations in order.
final allMigrations = <Migration>[
  Migration001Initial(),
  Migration002AddPostSlug(),
  Migration003AddPostViewCount(),
  Migration004AddAuthorSoftDelete(),
  Migration005PopulatePostSlugs(),
];
