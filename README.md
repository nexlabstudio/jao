# JAO - Django-inspired ORM for Dart

[![Tests](https://github.com/nexlabstudio/jao/actions/workflows/test.yml/badge.svg?branch=dev)](https://github.com/nexlabstudio/jao/actions/workflows/test.yml)
[![codecov](https://codecov.io/gh/nexlabstudio/jao/branch/dev/graph/badge.svg)](https://codecov.io/gh/nexlabstudio/jao)
[![pub package](https://img.shields.io/pub/v/jao.svg)](https://pub.dev/packages/jao)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A type-safe, model-first ORM for Dart backend development. Built for PostgreSQL, SQLite, and MySQL. Works seamlessly with Dart Frog, Shelf, or any Dart server framework.

> **JAO** (Just Another ORM) — Because writing raw SQL shouldn't be your only option.

---

## Why JAO?

**The problem:** Dart's backend ecosystem lacks a Django style ORM. You're stuck with raw SQL strings, manual result mapping, and runtime errors waiting to happen.

**The solution:** JAO brings Django's elegant query API to Dart.

```dart
// ❌ Before: Raw SQL, manual mapping, runtime errors
final result = await db.query(
  'SELECT * FROM authors WHERE age >= ? AND is_active = ? ORDER BY name LIMIT ?',
  [18, true, 10]
);
final authors = result.map((row) => Author.fromMap(row)).toList();

// ✅ After: Type-safe, chainable, IDE autocomplete
final authors = await Authors.objects
  .filter(Authors.$.age.gte(18) & Authors.$.isActive.eq(true))
  .orderBy(Authors.$.name.asc())
  .limit(10)
  .toList();
```

---

## Features

- **Type-safe queries** — Catch errors at compile time, not runtime
- **Lazy QuerySets** — Chain filters without hitting the DB until needed
- **Django-style API** — Familiar patterns: `filter()`, `exclude()`, `orderBy()`
- **Cross-database** — PostgreSQL, SQLite, MySQL with zero code changes
- **Django-style CLI** — `jao makemigrations`, `jao migrate`, `jao rollback`
- **Code generation** — Define models once, get queries and serialization for free
- **Framework agnostic** — Works with Dart Frog, Shelf, or any Dart backend
- **No middleware required** — Query directly in your route handlers

---

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

This creates:
- `jao.yaml` — Paths configuration
- `lib/config/database.dart` — Database configuration
- `lib/migrations/` — Migrations directory
- `bin/migrate.dart` — Migration CLI entry point

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

### 5. Configure Database

Edit `lib/config/database.dart`:

```dart
import 'package:jao/jao.dart';

// SQLite (default)
final databaseConfig = DatabaseConfig.sqlite('database.db');
const databaseAdapter = SqliteAdapter();

// PostgreSQL
// final databaseConfig = DatabaseConfig.postgres(
//   database: 'myapp',
//   username: 'postgres',
//   password: 'password',
// );
// const databaseAdapter = PostgresAdapter();

// MySQL
// final databaseConfig = DatabaseConfig.mysql(
//   database: 'myapp',
//   username: 'root',
//   password: 'password',
// );
// const databaseAdapter = MySqlAdapter();
```

### 6. Register Model Schemas

In `bin/migrate.dart`:

```dart
import 'dart:io';
import 'package:jao_cli/jao_cli.dart';
import 'package:your_app/models/models.dart';

import '../lib/config/database.dart';
import '../lib/migrations/migrations.dart';

void main(List<String> args) async {
  final config = MigrationRunnerConfig(
    database: databaseConfig,
    adapter: databaseAdapter,
    migrations: allMigrations,
    modelSchemas: [
      Authors.schema,
      Posts.schema,
    ],
  );

  final cli = JaoCli(config);
  exit(await cli.run(args));
}
```

### 7. Create & Run Migrations

```bash
jao makemigrations
jao migrate
```

### 8. Initialize Database

Call once at application startup:

```dart
import 'package:jao/jao.dart';
import 'lib/config/database.dart';

Future<void> main() async {
  await Jao.configure(
    adapter: databaseAdapter,
    config: databaseConfig,
  );
  
  // Start your server...
}
```

### 9. Query Your Data

```dart
import 'package:your_app/models/models.dart';

Future<Response> onRequest(RequestContext context) async {
  // Get all authors
  final authors = await Authors.objects.all().toList();

  // Filter with type-safe field accessors
  final activeAdults = await Authors.objects
    .filter(Authors.$.age.gte(18))
    .filter(Authors.$.isActive.eq(true))
    .orderBy(Authors.$.name.asc())
    .toList();

  // Create
  final author = await Authors.objects.create({
    'name': 'John Doe',
    'email': 'john@example.com',
    'age': 30,
  });

  // Update
  await Authors.objects
    .filter(Authors.$.id.eq(1))
    .update({'name': 'Jane Doe'});

  // Delete
  await Authors.objects
    .filter(Authors.$.isActive.eq(false))
    .delete();

  return Response.json(body: authors);
}
```

---

## Query API

### Filtering

```dart
// Exact match
Authors.objects.filter(Authors.$.name.eq('John'));

// Comparisons
Authors.objects.filter(Authors.$.age.gte(18));
Authors.objects.filter(Authors.$.age.lt(65));
Authors.objects.filter(Authors.$.age.between(18, 65));

// String lookups
Authors.objects.filter(Authors.$.name.contains('John'));
Authors.objects.filter(Authors.$.email.endsWith('@gmail.com'));
Authors.objects.filter(Authors.$.name.startsWith('Dr.'));

// Case-insensitive
Authors.objects.filter(Authors.$.name.iContains('john'));

// Null checks
Authors.objects.filter(Authors.$.bio.isNull());
Authors.objects.filter(Authors.$.bio.isNotNull());

// In list
Authors.objects.filter(Authors.$.status.inList(['active', 'pending']));
```

### Boolean Logic

```dart
// AND (chained filters)
Authors.objects
  .filter(Authors.$.age.gte(18))
  .filter(Authors.$.isActive.eq(true));

// AND (& operator)
Authors.objects.filter(
  Authors.$.age.gte(18) & Authors.$.isActive.eq(true)
);

// OR (| operator)
Authors.objects.filter(
  Authors.$.age.lt(18) | Authors.$.age.gte(65)
);

// NOT (~ operator)
Authors.objects.filter(~Authors.$.name.eq('Admin'));

// Complex queries
Authors.objects.filter(
  (Authors.$.age.gte(18) & Authors.$.isActive.eq(true)) |
  Authors.$.role.eq('admin')
);
```

### Ordering & Pagination

```dart
// Ascending
Authors.objects.orderBy(Authors.$.name.asc());

// Descending
Authors.objects.orderBy(Authors.$.createdAt.desc());

// Multiple columns
Authors.objects.orderBy(
  Authors.$.isActive.desc(),
  Authors.$.name.asc(),
);

// Pagination
Authors.objects.offset(20).limit(10);

// Slice
Authors.objects.slice(20, 30);
```

### Aggregations

```dart
final stats = await Authors.objects.aggregate({
  'count': Count.all(),
  'avg_age': Avg(Authors.$.age.col),
  'max_age': Max(Authors.$.age.col),
  'min_age': Min(Authors.$.age.col),
});
// stats = {'count': 150, 'avg_age': 34.5, 'max_age': 89, 'min_age': 18}
```

### CRUD Operations

```dart
// Create
final author = await Authors.objects.create({
  'name': 'John',
  'email': 'john@example.com',
  'age': 30,
});

// Bulk create
final authors = await Authors.objects.bulkCreate([
  {'name': 'Alice', 'email': 'alice@example.com', 'age': 25},
  {'name': 'Bob', 'email': 'bob@example.com', 'age': 35},
]);

// Get by primary key
final author = await Authors.objects.get(1);

// Get or null
final author = await Authors.objects.getOrNull(999);

// First / Last
final first = await Authors.objects.orderBy(Authors.$.name.asc()).first();
final last = await Authors.objects.orderBy(Authors.$.name.asc()).last();

// Exists / Count
final hasAdmins = await Authors.objects.filter(Authors.$.role.eq('admin')).exists();
final count = await Authors.objects.count();

// Get or create
final (author, created) = await Authors.objects.getOrCreate(
  condition: Authors.$.email.eq('john@example.com'),
  defaults: {'name': 'John', 'age': 30},
);

// Update
final updatedCount = await Authors.objects
  .filter(Authors.$.isActive.eq(false))
  .update({'isActive': true});

// Delete
final deletedCount = await Authors.objects
  .filter(Authors.$.email.endsWith('@spam.com'))
  .delete();
```

---

## Field Types

| Annotation | Dart Type | Database Type | Description |
|------------|-----------|---------------|-------------|
| `@AutoField()` | `int` | SERIAL | Auto-increment primary key |
| `@BigAutoField()` | `int` | BIGSERIAL | Big auto-increment primary key |
| `@CharField(maxLength: n)` | `String` | VARCHAR(n) | Limited-length string |
| `@TextField()` | `String` | TEXT | Unlimited-length string |
| `@EmailField()` | `String` | VARCHAR(254) | Email with validation |
| `@IntegerField()` | `int` | INTEGER | Standard integer |
| `@BigIntegerField()` | `int` | BIGINT | Large integer |
| `@SmallIntegerField()` | `int` | SMALLINT | Small integer |
| `@PositiveIntegerField()` | `int` | INTEGER | Positive integer (min: 0) |
| `@FloatField()` | `double` | REAL | Floating point |
| `@DecimalField(decimalPlaces: n)` | `double` | DECIMAL | Fixed precision decimal |
| `@BooleanField()` | `bool` | BOOLEAN | True/False |
| `@DateField()` | `DateTime` | DATE | Date only |
| `@DateTimeField()` | `DateTime` | TIMESTAMPTZ | Date and time with timezone |
| `@DateTimeField(autoNowAdd: true)` | `DateTime` | TIMESTAMPTZ | Auto-set on create |
| `@DateTimeField(autoNow: true)` | `DateTime` | TIMESTAMPTZ | Auto-set on every save |
| `@DurationField()` | `Duration` | INTERVAL | Time duration |
| `@TimeField()` | `Duration` | TIME | Time of day |
| `@UuidField()` | `String` | UUID | UUID string |
| `@JsonField()` | `dynamic` | JSONB | JSON data |
| `@BinaryField()` | `List<int>` | BYTEA | Binary data |
| `@ForeignKey(Model)` | `int` | INTEGER | Foreign key relationship |
| `@OneToOneField(Model)` | `int` | INTEGER | One-to-one relationship |

### Field Options

All fields support these common options:

```dart
@CharField(
  maxLength: 100,
  nullable: true,        // Allow NULL values
  unique: true,          // Add UNIQUE constraint
  index: true,           // Create index
  defaultValue: 'N/A',   // Default value
  dbColumn: 'custom_name', // Custom column name
)
late String? name;
```

---

## CLI Commands

```bash
jao init              # Initialize project structure
jao makemigrations    # Auto-detect model changes and create migration
jao migrate           # Run pending migrations
jao status            # Show migration status
jao rollback          # Rollback last migration
jao rollback --step=3 # Rollback last 3 migrations
jao reset             # Rollback all migrations
jao refresh           # Reset and re-run all migrations
jao sql               # Show SQL for pending migrations
```

---

## Database Support

| Database | Adapter | Status |
|----------|---------|--------|
| PostgreSQL | `PostgresAdapter()` | ✅ Full support |
| SQLite | `SqliteAdapter()` | ✅ Full support |
| MySQL | `MySqlAdapter()` | ✅ Full support |

JAO handles database-specific differences automatically:
- DateTime handling (PostgreSQL returns `DateTime`, SQLite returns strings)
- Boolean handling (PostgreSQL returns `bool`, SQLite returns `0`/`1`)
- Parameter placeholders (`$1` vs `?` vs `?1`)

---

## Framework Integration

JAO is framework-agnostic. Here's how to integrate with popular frameworks:

### Dart Frog

```dart
// main.dart
import 'package:dart_frog/dart_frog.dart';
import 'package:jao/jao.dart';
import 'config/database.dart';

Future<HttpServer> run(Handler handler, InternetAddress ip, int port) async {
  await Jao.configure(adapter: databaseAdapter, config: databaseConfig);
  return serve(handler, ip, port);
}

// routes/authors/index.dart
import 'package:your_app/models/models.dart';

Future<Response> onRequest(RequestContext context) async {
  final authors = await Authors.objects.all().toList();
  return Response.json(body: authors.map((a) => Authors.toRow(a)).toList());
}
```

### Shelf

```dart
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:jao/jao.dart';
import 'config/database.dart';
import 'models/models.dart';

void main() async {
  await Jao.configure(adapter: databaseAdapter, config: databaseConfig);

  final handler = Pipeline()
    .addMiddleware(logRequests())
    .addHandler(_router);

  await io.serve(handler, 'localhost', 8080);
}

Response _router(Request request) {
  // Query your data directly
  return Response.ok('Hello!');
}
```

---

## Comparison

| Feature | JAO | Drift | Floor |
|---------|:---:|:-----:|:-----:|
| Django-style API | ✅ | ❌ | ❌ |
| Type-safe queries | ✅ | ✅ | ✅ |
| Lazy QuerySets | ✅ | ❌ | ❌ |
| Chainable filters | ✅ | ⚠️ | ⚠️ |
| PostgreSQL | ✅ | ✅ | ❌ |
| MySQL | ✅ | ✅ | ❌ |
| SQLite | ✅ | ✅ | ✅ |
| Migrations CLI | ✅ | ❌ | ❌ |
| Auto-detect migrations | ✅ | ❌ | ❌ |
| Raw SQL escape hatch | ✅ | ✅ | ✅ |
| Code generation | ✅ | ✅ | ✅ |
| No annotations on queries | ✅ | ❌ | ❌ |

---

## Community

- [GitHub Issues](https://github.com/nexlabstudio/jao/issues) — Bug reports and feature requests
- [GitHub Discussions](https://github.com/nexlabstudio/jao/discussions) — Questions and ideas

---

## Contributing

Contributions are welcome! Please read our [contributing guide](CONTRIBUTING.md) before submitting a PR.

```bash
# Clone the repo
git clone https://github.com/nexlabstudio/jao.git

# Install dependencies
cd jao && dart pub get
cd jao_cli && dart pub get
cd jao_generator && dart pub get

# Run tests
dart test
```

---

## Credits

Built by [Nexlab Studio](https://nexlabstudio.com)

---

## License

MIT License — see [LICENSE](LICENSE) for details.