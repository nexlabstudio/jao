# Dartonic

A Django-inspired ORM for Dart. Framework-agnostic, type-safe, with a powerful QuerySet API.

## Features

- **Django-style API**: Familiar patterns for Django developers
- **Type-safe queries**: Compile-time checking for field names and types
- **Lazy QuerySets**: Queries don't execute until evaluated
- **Chainable API**: Build complex queries fluently
- **Database agnostic**: PostgreSQL, MySQL, SQLite adapters
- **No middleware required**: Works directly in your routes/handlers
- **Django-style CLI**: `dartonic makemigrations`, `dartonic migrate`

## Quick Start

### 1. Install

```bash
dart pub add dartonic

dart pub add --dev build_runner dartonic_generator

dart pub global activate dartonic_cli
```

### 2. Initialize Project

```bash
dartonic init
```

This creates a `dartonic.yaml` configuration file:

```yaml
type: sqlite
database: database.db

migrations_path: lib/migrations
models_path: lib/models
```

### 3. Define Models

```dart
import 'package:dartonic/dartonic.dart';

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

  @DateTimeField(autoNowAdd: true)
  late DateTime createdAt;
}
```

### 4. Generate Code

```bash
dart run build_runner build
```

### 5. Create & Run Migrations

```bash
dartonic makemigrations

dartonic migrate
```

### 6. Initialize Database (once at startup)

```dart
import 'package:dartonic/dartonic.dart';

Future<void> initializeDatabase() async {
  const adapter = SqliteAdapter();
  final config = DatabaseConfig.sqlite('database.db');
  final pool = await adapter.createPool(config);

  await Dartonic.configure(pool: pool, compiler: SqlCompiler(adapter.dialect));
}
```

### 7. Query Your Data

No middleware needed - just query directly in your handlers:

```dart
import 'package:your_app/models/models.dart';

Future<Response> onRequest(RequestContext context) async {
  // Get all authors
  final authors = await AuthorDartonic.objects.all().toList();

  // Filter with type-safe field accessors
  final activeAdults = await AuthorDartonic.objects
    .filter(AuthorDartonic.$.age.gte(18))
    .filter(AuthorDartonic.$.isActive.eq(true))
    .orderBy(AuthorDartonic.$.name.asc())
    .toList();

  // Create
  final author = await AuthorDartonic.objects.create({
    'name': 'John Doe',
    'email': 'john@example.com',
    'age': 30,
  });

  // Update
  await AuthorDartonic.objects
    .filter(AuthorDartonic.$.id.eq(1))
    .update({'name': 'Jane Doe'});

  // Delete
  await AuthorDartonic.objects
    .filter(AuthorDartonic.$.isActive.eq(false))
    .delete();

  return Response.json(body: authors);
}
```

## Query API

### Filtering

```dart
// Exact match
AuthorDartonic.objects.filter(AuthorDartonic.$.name.eq('John'));

// Comparisons
AuthorDartonic.objects.filter(AuthorDartonic.$.age.gte(18));
AuthorDartonic.objects.filter(AuthorDartonic.$.age.lt(65));
AuthorDartonic.objects.filter(AuthorDartonic.$.age.between(18, 65));

// String lookups
AuthorDartonic.objects.filter(AuthorDartonic.$.name.contains('John'));
AuthorDartonic.objects.filter(AuthorDartonic.$.email.endsWith('@gmail.com'));
AuthorDartonic.objects.filter(AuthorDartonic.$.name.startsWith('Dr.'));

// Case-insensitive
AuthorDartonic.objects.filter(AuthorDartonic.$.name.iContains('john'));

// Null checks
AuthorDartonic.objects.filter(AuthorDartonic.$.bio.isNull());
AuthorDartonic.objects.filter(AuthorDartonic.$.bio.isNotNull());

// In list
AuthorDartonic.objects.filter(AuthorDartonic.$.status.inList(['active', 'pending']));
```

### Boolean Logic

```dart
// AND (chained filters)
AuthorDartonic.objects
  .filter(AuthorDartonic.$.age.gte(18))
  .filter(AuthorDartonic.$.isActive.eq(true));

// AND (& operator)
AuthorDartonic.objects.filter(
  AuthorDartonic.$.age.gte(18) & AuthorDartonic.$.isActive.eq(true)
);

// OR
AuthorDartonic.objects.filter(
  AuthorDartonic.$.age.lt(18) | AuthorDartonic.$.age.gte(65)
);

// NOT
AuthorDartonic.objects.filter(~AuthorDartonic.$.name.eq('Admin'));
```

### Ordering & Pagination

```dart
// Ascending/Descending
AuthorDartonic.objects.orderBy(AuthorDartonic.$.name.asc());
AuthorDartonic.objects.orderBy(AuthorDartonic.$.createdAt.desc());

// Multiple columns
AuthorDartonic.objects.orderBy(
  AuthorDartonic.$.isActive.desc(),
  AuthorDartonic.$.name.asc(),
);

// Pagination
AuthorDartonic.objects.offset(20).limit(10);
AuthorDartonic.objects.slice(20, 30);
```

### Aggregations

```dart
final stats = await AuthorDartonic.objects.aggregate({
  'count': Count.all(),
  'avg_age': Avg(AuthorDartonic.$.age.col),
  'max_age': Max(AuthorDartonic.$.age.col),
});
```

### CRUD Operations

```dart
// Create
final author = await AuthorDartonic.objects.create({
  'name': 'John',
  'email': 'john@example.com',
  'age': 30,
});

// Get by primary key
final author = await AuthorDartonic.objects.get(1);

// Get or create
final (author, created) = await AuthorDartonic.objects.getOrCreate(
  condition: AuthorDartonic.$.email.eq('john@example.com'),
  defaults: {'name': 'John', 'age': 30},
);

// Update
await AuthorDartonic.objects
  .filter(AuthorDartonic.$.isActive.eq(false))
  .update({'isActive': true});

// Delete
await AuthorDartonic.objects
  .filter(AuthorDartonic.$.email.endsWith('@spam.com'))
  .delete();
```

## Field Types

| Annotation | Dart Type | Description |
|------------|-----------|-------------|
| `@AutoField()` | `int` | Auto-increment primary key |
| `@BigAutoField()` | `int` | Big auto-increment primary key |
| `@CharField(maxLength: n)` | `String` | VARCHAR(n) |
| `@TextField()` | `String` | TEXT |
| `@EmailField()` | `String` | Email with validation |
| `@IntegerField()` | `int` | INTEGER |
| `@BigIntegerField()` | `int` | BIGINT |
| `@FloatField()` | `double` | FLOAT |
| `@DecimalField()` | `double` | DECIMAL |
| `@BooleanField()` | `bool` | BOOLEAN |
| `@DateField()` | `DateTime` | DATE |
| `@DateTimeField()` | `DateTime` | TIMESTAMP |
| `@DateTimeField(autoNowAdd: true)` | `DateTime` | Auto-set on create |
| `@DateTimeField(autoNow: true)` | `DateTime` | Auto-set on every save |
| `@DurationField()` | `Duration` | INTERVAL |
| `@UuidField()` | `String` | UUID |
| `@JsonField()` | `dynamic` | JSONB |
| `@ForeignKey(Model)` | `int` | Foreign key relationship |

## CLI Commands

```bash
dartonic init            # Initialize project with dartonic.yaml
dartonic makemigrations  # Auto-detect model changes and create migration
dartonic migrate         # Run pending migrations
dartonic status          # Show migration status
dartonic rollback        # Rollback last migration
dartonic reset           # Rollback all migrations
dartonic refresh         # Reset and re-run all migrations
```

## Database Configuration

### SQLite

```yaml
# dartonic.yaml
type: sqlite
database: database.db
```

### PostgreSQL

```yaml
# dartonic.yaml
type: postgres
host: localhost
port: 5432
database: myapp
username: user
password: pass
```

### MySQL

```yaml
# dartonic.yaml
type: mysql
host: localhost
port: 3306
database: myapp
username: user
password: pass
```

## License

MIT
