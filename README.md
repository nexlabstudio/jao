# JAO

[![Tests](https://github.com/nexlabstudio/jao/actions/workflows/test.yml/badge.svg?branch=dev)](https://github.com/nexlabstudio/jao/actions/workflows/test.yml)
[![codecov](https://codecov.io/gh/nexlabstudio/jao/branch/dev/graph/badge.svg)](https://codecov.io/gh/nexlabstudio/jao)

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

This creates:
- `jao.yaml` - Paths configuration
- `lib/config/database.dart` - Database configuration (single source of truth)
- `lib/migrations/` - Migrations directory
- `bin/migrate.dart` - Migration CLI entry point

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

Edit `lib/config/database.dart` to configure your database:

```dart
import 'package:jao/jao.dart';

// SQLite (default)
final databaseConfig = DatabaseConfig.sqlite('database.db');
const databaseAdapter = SqliteAdapter();

// PostgreSQL:
// final databaseConfig = DatabaseConfig.postgres(
//   database: 'myapp',
//   username: 'postgres',
//   password: 'password',
// );
// const databaseAdapter = PostgresAdapter();

// MySQL:
// final databaseConfig = DatabaseConfig.mysql(
//   database: 'myapp',
//   username: 'root',
//   password: 'password',
// );
// const databaseAdapter = MySqlAdapter();
```

### 6. Register Model Schemas

After code generation, register your model schemas in `bin/migrate.dart`:

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
      // Add all your model schemas here
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

### 8. Initialize Database (once at startup)

```dart
import 'package:jao/jao.dart';
import 'lib/config/database.dart';

Future<void> initializeDatabase() async {
  await Jao.configure(
    adapter: databaseAdapter,
    config: databaseConfig,
  );
}
```

### 9. Query Your Data

No middleware needed - just query directly in your handlers:

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

// OR
Authors.objects.filter(
  Authors.$.age.lt(18) | Authors.$.age.gte(65)
);

// NOT
Authors.objects.filter(~Authors.$.name.eq('Admin'));
```

### Ordering & Pagination

```dart
// Ascending/Descending
Authors.objects.orderBy(Authors.$.name.asc());
Authors.objects.orderBy(Authors.$.createdAt.desc());

// Multiple columns
Authors.objects.orderBy(
  Authors.$.isActive.desc(),
  Authors.$.name.asc(),
);

// Pagination
Authors.objects.offset(20).limit(10);
Authors.objects.slice(20, 30);
```

### Aggregations

```dart
final stats = await Authors.objects.aggregate({
  'count': Count.all(),
  'avg_age': Avg(Authors.$.age.col),
  'max_age': Max(Authors.$.age.col),
});
```

### CRUD Operations

```dart
// Create
final author = await Authors.objects.create({
  'name': 'John',
  'email': 'john@example.com',
  'age': 30,
});

// Get by primary key
final author = await Authors.objects.get(1);

// Get or create
final (author, created) = await Authors.objects.getOrCreate(
  condition: Authors.$.email.eq('john@example.com'),
  defaults: {'name': 'John', 'age': 30},
);

// Update
await Authors.objects
  .filter(Authors.$.isActive.eq(false))
  .update({'isActive': true});

// Delete
await Authors.objects
  .filter(Authors.$.email.endsWith('@spam.com'))
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
jao init            # Initialize project structure
jao makemigrations  # Auto-detect model changes and create migration
jao migrate         # Run pending migrations
jao status          # Show migration status
jao rollback        # Rollback last migration
jao reset           # Rollback all migrations
jao refresh         # Reset and re-run all migrations
```

## Framework Integration

JAO is framework-agnostic and works with any Dart backend. Initialize once at startup.

### dart_frog

Option 1: Initialize in `main.dart`

```dart
// main.dart
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:jao/jao.dart';

import 'lib/config/database.dart';

Future<HttpServer> run(Handler handler, InternetAddress ip, int port) async {
  await Jao.configure(
    adapter: databaseAdapter,
    config: databaseConfig,
  );
  return serve(handler, ip, port);
}
```

Option 2: Initialize in middleware

```dart
// routes/_middleware.dart
import 'package:dart_frog/dart_frog.dart';
import 'package:jao/jao.dart';

import '../lib/config/database.dart';

Handler middleware(Handler handler) {
  return (context) async {
    await Jao.configure(
      adapter: databaseAdapter,
      config: databaseConfig,
    );
    return handler(context);
  };
}
```

### shelf

```dart
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:jao/jao.dart';
import 'package:your_app/models/models.dart';

import 'lib/config/database.dart';

void main() async {
  // Initialize ORM
  await Jao.configure(
    adapter: databaseAdapter,
    config: databaseConfig,
  );

  // Define routes
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(_router);

  await io.serve(handler, InternetAddress.anyIPv4, 8080);
}

Response _router(Request request) => switch (request.url.path) {
  'authors' => _getAuthors(request),
  _ => Response.notFound('Not found'),
};

Future<Response> _getAuthors(Request request) async {
  final authors = await Authors.objects.all().toList();
  return Response.ok(jsonEncode(authors.map(Authors.toRow).toList()));
}
```

### serinus

```dart
import 'package:serinus/serinus.dart';
import 'package:jao/jao.dart';
import 'package:your_app/models/models.dart';

import 'lib/config/database.dart';

void main() async {
  // Initialize ORM before app starts
  await Jao.configure(
    adapter: databaseAdapter,
    config: databaseConfig,
  );

  final app = await serinus.createApplication(entrypoint: AppModule());
  await app.serve();
}

class AppController extends Controller {
  AppController({super.path = '/authors'}) {
    on(Route.get('/'), _getAuthors);
  }

  Future<Response> _getAuthors(RequestContext context) async {
    final authors = await Authors.objects.all().toList();
    return Response.json(authors.map(Authors.toRow).toList());
  }
}
```

### alfred

```dart
import 'package:alfred/alfred.dart';
import 'package:jao/jao.dart';
import 'package:your_app/models/models.dart';

import 'lib/config/database.dart';

void main() async {
  // Initialize ORM
  await Jao.configure(
    adapter: databaseAdapter,
    config: databaseConfig,
  );

  final app = Alfred();

  app.get('/authors', (req, res) async {
    final authors = await Authors.objects.all().toList();
    return authors.map(Authors.toRow).toList();
  });

  app.get('/authors/:id', (req, res) async {
    final id = int.parse(req.params['id']);
    final author = await Authors.objects.getOrNull(id);
    if (author == null) return res.statusCode = 404;
    return Authors.toRow(author);
  });

  await app.listen(8080);
}
```

### conduit

```dart
import 'package:conduit/conduit.dart';
import 'package:jao/jao.dart';
import 'package:your_app/models/models.dart';

import 'lib/config/database.dart';

class AppChannel extends ApplicationChannel {
  @override
  Future prepare() async {
    // Initialize ORM
    await Jao.configure(
      adapter: databaseAdapter,
      config: databaseConfig,
    );
  }

  @override
  Controller get entryPoint {
    final router = Router();
    router.route('/authors/[:id]').link(() => AuthorController());
    return router;
  }
}

class AuthorController extends ResourceController {
  @Operation.get()
  Future<Response> getAll() async {
    final authors = await Authors.objects.all().toList();
    return Response.ok(authors.map(Authors.toRow).toList());
  }

  @Operation.get('id')
  Future<Response> getOne(@Bind.path('id') int id) async {
    final author = await Authors.objects.getOrNull(id);
    if (author == null) return Response.notFound();
    return Response.ok(Authors.toRow(author));
  }
}
```

### serverpod

```dart
import 'package:serverpod/serverpod.dart';
import 'package:jao/jao.dart';
import 'package:your_app/models/models.dart';

import 'lib/config/database.dart';

void run(List<String> args) async {
  final pod = Serverpod(args, /* ... */);

  // Initialize ORM in onStart
  await pod.start(onStart: () async {
    await Jao.configure(
      adapter: databaseAdapter,
      config: databaseConfig,
    );
  });
}

// In your endpoint
class AuthorEndpoint extends Endpoint {
  Future<List<Map<String, dynamic>>> getAuthors(Session session) async {
    final authors = await Authors.objects.all().toList();
    return authors.map(Authors.toRow).toList();
  }
}
```

## License

MIT
