# JAO

**J**ust **A**nother **O**RM - A Django-inspired ORM for Dart.

[![pub package](https://img.shields.io/pub/v/jao.svg)](https://pub.dev/packages/jao)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## Features

- Django-style model definitions with field annotations
- Type-safe query building with `Q` expressions
- Multi-database support (SQLite, PostgreSQL, MySQL)
- Schema migrations with up/down support
- Auto-generated `created_at` and `updated_at` timestamps
- Manager pattern for database operations

## Installation

```yaml
dependencies:
  jao: ^0.0.1

dev_dependencies:
  build_runner: ^2.4.0
  jao_generator: ^0.0.1
```

## Quick Start

### 1. Define a Model

```dart
import 'package:jao/jao.dart';

part 'user.g.dart';

@Model()
class User {
  @AutoField()
  late int id;

  @CharField(maxLength: 100)
  late String name;

  @EmailField()
  late String email;

  @BooleanField()
  late bool isActive;

  @DateTimeField(autoNowAdd: true)
  late DateTime createdAt;
}
```

### 2. Generate Code

```bash
dart run build_runner build
```

### 3. Initialize JAO

```bash
dart pub global activate jao_cli
jao init
```

This creates `lib/config/database.dart` - your single source of truth for database settings:

```dart
import 'package:jao/jao.dart';

final databaseConfig = DatabaseConfig.sqlite('app.db');
const databaseAdapter = SqliteAdapter();

// PostgreSQL:
// final databaseConfig = DatabaseConfig.postgres(
//   database: 'myapp',
//   username: 'postgres',
//   password: 'password',
// );
// const databaseAdapter = PostgresAdapter();
```

### 4. Configure at Runtime

```dart
import 'package:jao/jao.dart';
import 'lib/config/database.dart';

void main() async {
  await Jao.configure(
    adapter: databaseAdapter,
    config: databaseConfig,
  );
}
```

### 5. Query Data

```dart
// Create
final user = await Users.objects.create({
  'name': 'John',
  'email': 'john@example.com',
  'isActive': true,
});

// Read
final users = await Users.objects
    .filter(Users.$.isActive.eq(true))
    .orderBy([Users.$.name.asc()])
    .toList();

// Update
await Users.objects
    .filter(Users.$.id.eq(1))
    .update({'name': 'Jane'});

// Delete
await Users.objects
    .filter(Users.$.id.eq(1))
    .delete();
```

## Field Types

| Annotation | Dart Type | Database Type |
|------------|-----------|---------------|
| `@AutoField()` | `int` | `SERIAL` / `INTEGER AUTOINCREMENT` |
| `@BigAutoField()` | `int` | `BIGSERIAL` |
| `@CharField(maxLength: n)` | `String` | `VARCHAR(n)` |
| `@TextField()` | `String` | `TEXT` |
| `@IntegerField()` | `int` | `INTEGER` |
| `@BooleanField()` | `bool` | `BOOLEAN` |
| `@FloatField()` | `double` | `REAL` |
| `@DateTimeField()` | `DateTime` | `TIMESTAMPTZ` |
| `@DateField()` | `DateTime` | `DATE` |
| `@EmailField()` | `String` | `VARCHAR(254)` |
| `@ForeignKey(Model)` | `int` | `INTEGER REFERENCES` |

## Query Expressions

```dart
// Comparison
Users.$.age.eq(25)
Users.$.age.gt(18)
Users.$.age.gte(21)
Users.$.age.lt(65)
Users.$.age.lte(100)
Users.$.age.between(18, 65)

// String operations
Users.$.name.contains('john')
Users.$.name.startsWith('J')
Users.$.name.endsWith('son')
Users.$.email.iContains('EXAMPLE')  // case-insensitive

// Null checks
Users.$.deletedAt.isNull()
Users.$.email.isNotNull()

// Combining with Q
Users.objects.filter(
  Q(Users.$.isActive.eq(true)) & Q(Users.$.age.gte(18))
)

Users.objects.filter(
  Q(Users.$.role.eq('admin')) | Q(Users.$.role.eq('moderator'))
)
```

## Migrations

```dart
class CreateUsersTable extends Migration {
  @override
  String get name => '001_create_users';

  @override
  void up(MigrationBuilder builder) {
    builder.createTable('users', (t) {
      t.id();
      t.string('name', length: 100);
      t.string('email', length: 254, unique: true);
      t.boolean('is_active', defaultValue: true);
      t.timestamps();
    });
  }

  @override
  void down(MigrationBuilder builder) {
    builder.dropTable('users');
  }
}
```

## Database Support

| Database | Adapter | Status |
|----------|---------|--------|
| SQLite | `SqliteAdapter()` | Stable |
| PostgreSQL | `PostgresAdapter()` | Stable |
| MySQL | `MySqlAdapter()` | Stable |

## Related Packages

- [jao_generator](https://pub.dev/packages/jao_generator) - Code generator for JAO
- [jao_cli](https://pub.dev/packages/jao_cli) - CLI tools for migrations

## License

MIT License - see [LICENSE](LICENSE) for details.
