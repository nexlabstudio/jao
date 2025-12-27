# JAO

**Just Another ORM** - *We know there are many, but this is the one that works the way you expect.*

A Django-inspired ORM for Dart. Framework-agnostic, type-safe, with a powerful QuerySet API.

## Features

- **Django-style API**: Familiar patterns for Django developers
- **Type-safe queries**: Compile-time checking for field names and types
- **Lazy QuerySets**: Queries don't execute until evaluated
- **Chainable API**: Build complex queries fluently
- **Database agnostic**: PostgreSQL, MySQL, SQLite adapters
- **No middleware required**: Works directly in your routes/handlers
- **Django-style CLI**: `jao makemigrations`, `jao migrate`

## Quick Start

### 1. Install

```bash
dart pub add jao

dart pub add --dev build_runner jao_generator

dart pub global activate jao_cli
```

### 2. Initialize Project

```bash
jao init
```

This creates a `jao.yaml` configuration file:

```yaml
type: sqlite
database: database.db

migrations_path: lib/migrations
models_path: lib/models
```

### 3. Define Models

```dart
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
jao makemigrations

jao migrate
```

### 6. Initialize Database (once at startup)

```dart
import 'package:jao/jao.dart';

Future<void> initializeDatabase() async {
  const adapter = SqliteAdapter();
  final config = DatabaseConfig.sqlite('database.db');
  final pool = await adapter.createPool(config);

  await Jao.configure(pool: pool, compiler: SqlCompiler(adapter.dialect));
}
```

### 7. Query Your Data

No middleware needed - just query directly in your handlers:

```dart
import 'package:your_app/models/models.dart';

Future<Response> onRequest(RequestContext context) async {
  // Get all authors
  final authors = await AuthorJao.objects.all().toList();

  // Filter with type-safe field accessors
  final activeAdults = await AuthorJao.objects
    .filter(AuthorJao.$.age.gte(18))
    .filter(AuthorJao.$.isActive.eq(true))
    .orderBy(AuthorJao.$.name.asc())
    .toList();

  // Create
  final author = await AuthorJao.objects.create({
    'name': 'John Doe',
    'email': 'john@example.com',
    'age': 30,
  });

  // Update
  await AuthorJao.objects
    .filter(AuthorJao.$.id.eq(1))
    .update({'name': 'Jane Doe'});

  // Delete
  await AuthorJao.objects
    .filter(AuthorJao.$.isActive.eq(false))
    .delete();

  return Response.json(body: authors);
}
```

## Query API

### Filtering

```dart
// Exact match
AuthorJao.objects.filter(AuthorJao.$.name.eq('John'));

// Comparisons
AuthorJao.objects.filter(AuthorJao.$.age.gte(18));
AuthorJao.objects.filter(AuthorJao.$.age.lt(65));
AuthorJao.objects.filter(AuthorJao.$.age.between(18, 65));

// String lookups
AuthorJao.objects.filter(AuthorJao.$.name.contains('John'));
AuthorJao.objects.filter(AuthorJao.$.email.endsWith('@gmail.com'));
AuthorJao.objects.filter(AuthorJao.$.name.startsWith('Dr.'));

// Case-insensitive
AuthorJao.objects.filter(AuthorJao.$.name.iContains('john'));

// Null checks
AuthorJao.objects.filter(AuthorJao.$.bio.isNull());
AuthorJao.objects.filter(AuthorJao.$.bio.isNotNull());

// In list
AuthorJao.objects.filter(AuthorJao.$.status.inList(['active', 'pending']));
```

### Boolean Logic

```dart
// AND (chained filters)
AuthorJao.objects
  .filter(AuthorJao.$.age.gte(18))
  .filter(AuthorJao.$.isActive.eq(true));

// AND (& operator)
AuthorJao.objects.filter(
  AuthorJao.$.age.gte(18) & AuthorJao.$.isActive.eq(true)
);

// OR
AuthorJao.objects.filter(
  AuthorJao.$.age.lt(18) | AuthorJao.$.age.gte(65)
);

// NOT
AuthorJao.objects.filter(~AuthorJao.$.name.eq('Admin'));
```

### Ordering & Pagination

```dart
// Ascending/Descending
AuthorJao.objects.orderBy(AuthorJao.$.name.asc());
AuthorJao.objects.orderBy(AuthorJao.$.createdAt.desc());

// Multiple columns
AuthorJao.objects.orderBy(
  AuthorJao.$.isActive.desc(),
  AuthorJao.$.name.asc(),
);

// Pagination
AuthorJao.objects.offset(20).limit(10);
AuthorJao.objects.slice(20, 30);
```

### Aggregations

```dart
final stats = await AuthorJao.objects.aggregate({
  'count': Count.all(),
  'avg_age': Avg(AuthorJao.$.age.col),
  'max_age': Max(AuthorJao.$.age.col),
});
```

### CRUD Operations

```dart
// Create
final author = await AuthorJao.objects.create({
  'name': 'John',
  'email': 'john@example.com',
  'age': 30,
});

// Get by primary key
final author = await AuthorJao.objects.get(1);

// Get or create
final (author, created) = await AuthorJao.objects.getOrCreate(
  condition: AuthorJao.$.email.eq('john@example.com'),
  defaults: {'name': 'John', 'age': 30},
);

// Update
await AuthorJao.objects
  .filter(AuthorJao.$.isActive.eq(false))
  .update({'isActive': true});

// Delete
await AuthorJao.objects
  .filter(AuthorJao.$.email.endsWith('@spam.com'))
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
jao init            # Initialize project with jao.yaml
jao makemigrations  # Auto-detect model changes and create migration
jao migrate         # Run pending migrations
jao status          # Show migration status
jao rollback        # Rollback last migration
jao reset           # Rollback all migrations
jao refresh         # Reset and re-run all migrations
```

## Database Configuration

### SQLite

```yaml
# jao.yaml
type: sqlite
database: database.db
```

### PostgreSQL

```yaml
# jao.yaml
type: postgres
host: localhost
port: 5432
database: myapp
username: user
password: pass
```

### MySQL

```yaml
# jao.yaml
type: mysql
host: localhost
port: 3306
database: myapp
username: user
password: pass
```

## License

MIT
