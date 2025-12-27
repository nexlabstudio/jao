# Dartonic

A Django-inspired ORM for Dart. Framework-agnostic, type-safe, with a powerful QuerySet API.

## Installation

```bash
# Add to your project
dart pub add dartonic

# Install CLI globally
dart pub global activate dartonic_cli
```

## Quick Start

```bash
# Initialize project
dartonic init

# Create a migration
dartonic make --name=create_users

# Run migrations
dartonic migrate

# Check status
dartonic status
```

## Features

- **Django-style API**: Familiar patterns for Django developers
- **Type-safe queries**: Compile-time checking for field names and types
- **Lazy QuerySets**: Queries don't execute until evaluated
- **Chainable API**: Build complex queries fluently
- **Database agnostic**: PostgreSQL, MySQL, SQLite adapters
- **Code generation**: Minimal boilerplate with `build_runner`
- **Django-style CLI**: `dartonic makemigrations`, `dartonic migrate`

## Quick Start

### 1. Add dependencies

```yaml
dependencies:
  dartonic: ^0.0.1

dev_dependencies:
  build_runner: ^2.4.0
  dartonic_generator: ^0.0.1
```

### 2. Define your models

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
  
  @DateTimeField(autoNowAdd: true)
  late DateTime createdAt;
}
```

### 3. Generate the code

```bash
dart run build_runner build
```

### 4. Query your data

```dart
// Get all authors
final authors = await Author.objects.all().toList();

// Filter with type-safe field accessors
final adults = await Author.objects
  .filter(Author.$.age.gte(18))
  .orderBy(Author.$.name.asc())
  .toList();

// Complex queries with Q objects
final result = await Author.objects
  .filter(
    (Author.$.age.gte(18) | Author.$.hasGuardian.eq(true)) &
    Author.$.email.isNotNull()
  )
  .toList();
```

## Query API

### Filtering

```dart
// Exact match
Author.objects.filter(Author.$.name.eq('John'));

// Comparisons
Author.objects.filter(Author.$.age.gte(18));
Author.objects.filter(Author.$.age.lt(65));
Author.objects.filter(Author.$.age.between(18, 65));

// String lookups
Author.objects.filter(Author.$.name.contains('John'));
Author.objects.filter(Author.$.email.endsWith('@gmail.com'));
Author.objects.filter(Author.$.name.startsWith('Dr.'));

// Case-insensitive
Author.objects.filter(Author.$.name.iContains('john'));

// Null checks
Author.objects.filter(Author.$.bio.isNull());
Author.objects.filter(Author.$.bio.isNotNull());

// In list
Author.objects.filter(Author.$.status.inList(['active', 'pending']));
```

### Boolean Logic

```dart
// AND (multiple filters)
Author.objects
  .filter(Author.$.age.gte(18))
  .filter(Author.$.isActive.eq(true));

// AND (& operator)
Author.objects.filter(
  Author.$.age.gte(18) & Author.$.isActive.eq(true)
);

// OR
Author.objects.filter(
  Author.$.age.lt(18) | Author.$.age.gte(65)
);

// NOT
Author.objects.filter(~Author.$.name.eq('Admin'));

// Complex nested
Author.objects.filter(
  (Author.$.age.gte(18) & Author.$.isActive.eq(true)) |
  Author.$.role.eq('admin')
);
```

### Ordering

```dart
// Ascending
Author.objects.orderBy(Author.$.name.asc());

// Descending
Author.objects.orderBy(Author.$.createdAt.desc());

// Multiple columns
Author.objects.orderBy(
  Author.$.isActive.desc(),
  Author.$.name.asc(),
);
```

### Pagination

```dart
// Limit
Author.objects.limit(10);

// Offset
Author.objects.offset(20).limit(10);

// Slice (Python-style)
Author.objects.slice(20, 30);
```

### Aggregations

```dart
// Single
final result = await Author.objects.aggregate({
  'avg_age': Avg(Author.$.age.col),
});

// Multiple
final stats = await Author.objects.aggregate({
  'count': Count.all(),
  'avg_age': Avg(Author.$.age.col),
  'max_age': Max(Author.$.age.col),
  'min_age': Min(Author.$.age.col),
});
```

### Mutations

```dart
// Create
final author = await Author.objects.create({
  'name': 'John',
  'email': 'john@example.com',
  'age': 30,
});

// Update
await Author.objects
  .filter(Author.$.isActive.eq(false))
  .update({'isActive': true});

// Delete
await Author.objects
  .filter(Author.$.email.endsWith('@spam.com'))
  .delete();

// Get or create
final (author, created) = await Author.objects.getOrCreate(
  condition: Author.$.email.eq('john@example.com'),
  defaults: {'name': 'John', 'age': 30},
);
```

## Field Types

| Annotation | Dart Type | Database Type |
|------------|-----------|---------------|
| `@AutoField()` | `int` | SERIAL/AUTO_INCREMENT |
| `@BigAutoField()` | `int` | BIGSERIAL |
| `@CharField(maxLength: n)` | `String` | VARCHAR(n) |
| `@TextField()` | `String` | TEXT |
| `@EmailField()` | `String` | VARCHAR(254) |
| `@IntegerField()` | `int` | INTEGER |
| `@BigIntegerField()` | `int` | BIGINT |
| `@FloatField()` | `double` | FLOAT |
| `@DecimalField(maxDigits, decimalPlaces)` | `double` | DECIMAL |
| `@BooleanField()` | `bool` | BOOLEAN |
| `@DateField()` | `DateTime` | DATE |
| `@DateTimeField()` | `DateTime` | TIMESTAMP |
| `@DurationField()` | `Duration` | INTERVAL |
| `@UuidField()` | `String` | UUID |
| `@JsonField()` | `dynamic` | JSONB |
| `@ForeignKey(Model)` | `int` | INTEGER + FK |
| `@OneToOneField(Model)` | `int` | INTEGER + FK + UNIQUE |
| `@ManyToManyField(Model)` | `List` | Junction table |

## Field Options

```dart
@CharField(
  maxLength: 100,
  nullable: true,      // Allow NULL
  unique: true,        // Unique constraint
  index: true,         // Create index
  defaultValue: '',    // Default value
  column: 'col_name',  // Custom column name
)
```

## Roadmap

- [x] Core query API
- [x] Field definitions
- [x] Code generator (build_runner)
- [x] Database adapters (PostgreSQL, MySQL, SQLite)
- [x] SQL compiler
- [x] Migrations system
- [ ] Analyzer plugin for IDE support
- [ ] Relationship traversal in queries
- [ ] Prefetch/select related
- [ ] Raw SQL support
- [ ] Connection pooling implementations

## Database Configuration

```dart
// PostgreSQL
final config = DatabaseConfig(
  host: 'localhost',
  port: 5432,
  database: 'myapp',
  username: 'user',
  password: 'pass',
);

// From URL
final config = DatabaseConfig.fromUrl('postgres://user:pass@localhost:5432/myapp');

// SQLite
final config = DatabaseConfig.sqlite('path/to/database.db');
final config = DatabaseConfig.sqliteMemory(); // In-memory for testing

// MySQL
final config = DatabaseConfig(
  host: 'localhost',
  port: 3306,
  database: 'myapp',
  username: 'user',
  password: 'pass',
);
```

## Migrations

### Creating Migrations

```dart
class Migration001CreateUsers extends Migration {
  @override
  String get name => '001_create_users';

  @override
  void up(MigrationBuilder builder) {
    builder.createTable('users', (table) {
      table.id();                          // Auto-increment primary key
      table.string('name', length: 100);
      table.string('email').unique();
      table.integer('age', nullable: true);
      table.boolean('is_active', defaultValue: true);
      table.text('bio', nullable: true);
      table.timestamps();                  // created_at, updated_at
    });

    builder.createIndex('users', ['email']);
  }

  @override
  void down(MigrationBuilder builder) {
    builder.dropTable('users');
  }
}
```

### Schema Builder API

```dart
// Table operations
builder.createTable('name', (table) { ... });
builder.dropTable('name');
builder.renameTable('old', 'new');

// Column types
table.id();                    // SERIAL PRIMARY KEY
table.bigId();                 // BIGSERIAL PRIMARY KEY
table.uuid();                  // UUID PRIMARY KEY
table.string('name', length: 255);
table.text('content');
table.integer('count');
table.bigInteger('big_count');
table.float('price');
table.decimal('amount', precision: 10, scale: 2);
table.boolean('active');
table.date('birth_date');
table.timestamp('created_at');
table.timestampTz('updated_at', useCurrent: true);
table.json('metadata');
table.binary('data');

// Relationships
table.foreignKey('user_id', 'users');
table.foreignKey('user_id', 'users', onDelete: OnDeleteAction.cascade);

// Indexes
table.index(['column1', 'column2']);
table.uniqueIndex(['email']);

// Convenience methods
table.timestamps();    // created_at + updated_at
table.softDeletes();   // is_deleted + deleted_at
```

### Running Migrations

```dart
final runner = MigrationRunner(
  adapter: PostgresAdapter(),
  pool: connectionPool,
);

// Run pending migrations
final result = await runner.migrate(allMigrations);

// Rollback last migration
await runner.rollback(allMigrations, count: 1);

// Reset all migrations
await runner.reset(allMigrations);

// Refresh (reset + migrate)
await runner.refresh(allMigrations);

// Check status
final status = await runner.status(allMigrations);
for (final s in status) {
  print('${s.isApplied ? "✓" : "○"} ${s.name}');
}
```

### Data Migrations

```dart
@override
void up(MigrationBuilder builder) {
  // Raw SQL
  builder.rawSql('''
    UPDATE users SET slug = LOWER(REPLACE(name, ' ', '-'))
    WHERE slug IS NULL
  ''');

  // Dart code for complex migrations
  builder.runDart((conn) async {
    final users = await conn.query('SELECT * FROM users WHERE slug IS NULL');
    for (final user in users) {
      final slug = generateSlug(user['name']);
      await conn.execute(
        'UPDATE users SET slug = \$1 WHERE id = \$2',
        [slug, user['id']],
      );
    }
  });
}
```

## Contributing

Contributions welcome! Please read our contributing guidelines first.

## License

MIT
