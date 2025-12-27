/// Dartonic - A Django-inspired ORM for Dart.
///
/// Dartonic provides a type-safe, framework-agnostic ORM with a powerful
/// QuerySet API inspired by Django's ORM.
///
/// ## Quick Start
///
/// Define your model:
///
/// ```dart
/// import 'package:dartonic/dartonic.dart';
///
/// @Model()
/// class Author {
///   @AutoField()
///   late int id;
///
///   @CharField(maxLength: 100)
///   late String name;
///
///   @IntegerField()
///   late int age;
///
///   @EmailField(unique: true)
///   late String email;
///
///   @DateTimeField(autoNowAdd: true)
///   late DateTime createdAt;
/// }
/// ```
///
/// Run the code generator to create typed field accessors.
///
/// Query your data:
///
/// ```dart
/// // Get all authors
/// final authors = await Author.objects.all().toList();
///
/// // Filter with type-safe field accessors
/// final adults = await Author.objects
///   .filter(Author.$.age.gte(18))
///   .orderBy(Author.$.name.asc())
///   .toList();
///
/// // Complex queries with Q objects
/// final result = await Author.objects
///   .filter(
///     (Author.$.age.gte(18) | Author.$.hasGuardian.eq(true)) &
///     Author.$.email.isNotNull()
///   )
///   .toList();
///
/// // Aggregations
/// final stats = await Author.objects.aggregate({
///   'avg_age': Avg(Author.$.age.col),
///   'count': Count.all(),
/// });
/// ```
///
/// ## Migrations
///
/// ```dart
/// class Migration001CreateUsers extends Migration {
///   @override
///   String get name => '001_create_users';
///
///   @override
///   void up(MigrationBuilder builder) {
///     builder.createTable('users', (table) {
///       table.id();
///       table.string('name');
///       table.string('email').unique();
///       table.timestamps();
///     });
///   }
///
///   @override
///   void down(MigrationBuilder builder) {
///     builder.dropTable('users');
///   }
/// }
/// ```
library dartonic;

// Field definitions (for model annotation)
export 'src/fields/field_def.dart';

// Field references (for queries)
export 'src/fields/field_ref.dart';

// Query system
export 'src/query/expressions.dart';
export 'src/query/queryset.dart';
export 'src/query/aggregates.dart';

// Model system
export 'src/model/model.dart';
export 'src/model/manager.dart';

// Database adapters
export 'src/db/connection.dart';
export 'src/db/compiler.dart';
export 'src/db/executor.dart';
export 'src/db/adapters/postgres.dart';
export 'src/db/adapters/mysql.dart';
export 'src/db/adapters/sqlite.dart';

// Migrations
export 'src/migrations/schema.dart';
export 'src/migrations/operations.dart';
export 'src/migrations/migration.dart';
export 'src/migrations/generator.dart';
