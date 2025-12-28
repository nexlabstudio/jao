# JAO CLI

Command-line interface for [JAO](https://pub.dev/packages/jao) ORM. Manage migrations, generate schemas, and interact with your database.

[![pub package](https://img.shields.io/pub/v/jao_cli.svg)](https://pub.dev/packages/jao_cli)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## Installation

### Global Installation

```bash
dart pub global activate jao_cli
```

### Project Dependency

```yaml
dev_dependencies:
  jao_cli: ^0.0.1
```

## Quick Start

### Initialize a New Project

```bash
jao init
```

This creates:
- `jao.yaml` - Paths configuration
- `lib/config/database.dart` - Database configuration (single source of truth)
- `lib/migrations/` - Migrations directory
- `lib/migrations/migrations.dart` - Migration registry
- `bin/migrate.dart` - Migration CLI entry point

### Create a Migration

```bash
jao makemigrations
```

### Run Migrations

```bash
jao migrate
```

## Commands

### `init`

Initialize JAO in your project.

```bash
jao init
```

Creates project structure with centralized database config in `lib/config/database.dart`.

### `make`

Create a new empty migration file.

```bash
jao make [options]

Options:
  -n, --name=<name>   Migration name (required)
  -p, --path=<path>   Output path (default: lib/migrations)

Examples:
  jao make -n=create_users_table
  jao make --name=add_email_to_users
  jao make create_posts  # name as positional argument
```

### `makemigrations`

Auto-generate migrations from model changes.

```bash
jao makemigrations [options]

Options:
  -n, --name=<name>   Custom migration name
  -p, --path=<path>   Output path
  --dry-run, -n       Show changes without creating files
  --empty             Create empty migration
```

### `migrate`

Apply pending migrations.

```bash
jao migrate [options]

Options:
  --dry-run, -n   Show SQL without executing
  -v, --verbose   Show detailed output
```

### `rollback`

Rollback the last migration(s).

```bash
jao rollback [options]

Options:
  -s, --step=<n>  Number of migrations to rollback (default: 1)
  --dry-run, -n   Show SQL without executing
  -v, --verbose   Show detailed output
```

### `status`

Show migration status.

```bash
jao status [options]

Options:
  -v, --verbose   Show detailed output
```

### `reset`

Rollback all migrations.

```bash
jao reset [options]

Options:
  -f, --force     Skip confirmation prompt
  --dry-run, -n   Show SQL without executing
```

### `refresh`

Reset and re-run all migrations.

```bash
jao refresh [options]

Options:
  -f, --force     Skip confirmation prompt
  --dry-run, -n   Show SQL without executing
```

### `sql`

Show SQL for migrations without executing.

```bash
jao sql [options]

Options:
  -m, --migration=<name>   Show specific migration
  --down                   Show rollback SQL
```

## Configuration

### jao.yaml

Paths configuration only:

```yaml
migrations_path: lib/migrations
models_path: lib/models
```

### lib/config/database.dart

Database configuration (single source of truth for both migrations and runtime):

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

// MySQL:
// final databaseConfig = DatabaseConfig.mysql(
//   database: 'myapp',
//   username: 'root',
//   password: 'password',
// );
// const databaseAdapter = MySqlAdapter();
```

### Environment Variables

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | Full connection URL (overrides jao.yaml) |
| `DATABASE_TYPE` | Database type: postgres, mysql, sqlite |
| `DATABASE_HOST` | Database host |
| `DATABASE_PORT` | Database port |
| `DATABASE_NAME` | Database name |
| `DATABASE_USER` | Username |
| `DATABASE_PASSWORD` | Password |
| `DATABASE_SSL` | Enable SSL: true/false |

### Connection URLs

```bash
# PostgreSQL
DATABASE_URL=postgres://user:pass@localhost:5432/mydb

# MySQL
DATABASE_URL=mysql://user:pass@localhost:3306/mydb

# SQLite
DATABASE_URL=sqlite:///path/to/database.db
```

## Project Setup

### bin/migrate.dart

```dart
import 'dart:io';
import 'package:jao_cli/jao_cli.dart';

import '../lib/config/database.dart';
import '../lib/migrations/migrations.dart';

void main(List<String> args) async {
  final config = MigrationRunnerConfig(
    database: databaseConfig,
    adapter: databaseAdapter,
    migrations: allMigrations,
    verbose: args.contains('-v') || args.contains('--verbose'),
  );

  final cli = JaoCli(config);
  exit(await cli.run(args));
}
```


## Examples

### Full Workflow

```bash
# Initialize project
jao init

# Configure database in lib/config/database.dart

# Either manually create a migration:
jao make -n=create_users_table
# Edit the migration file...

# Or auto-generate from models:
jao makemigrations

# Apply migrations
jao migrate

# Check status
jao status

# Rollback if needed
jao rollback

# Reset everything
jao reset --force

# Refresh (reset + migrate)
jao refresh --force
```

### Preview SQL

```bash
# Show all pending migration SQL
jao sql

# Show rollback SQL
jao sql --down

# Show specific migration
jao sql -m=20240101120000_create_users
```

## Related Packages

- [jao](https://pub.dev/packages/jao) - Core ORM package
- [jao_generator](https://pub.dev/packages/jao_generator) - Code generator

## License

MIT License - see [LICENSE](LICENSE) for details.
