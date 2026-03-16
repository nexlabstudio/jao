# JAO Generator

Code generator for [JAO](https://pub.dev/packages/jao) ORM. Generates typed field accessors, model metadata, and serialization methods.

[![pub package](https://img.shields.io/pub/v/jao_generator.svg)](https://pub.dev/packages/jao_generator)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## Installation

```yaml
dependencies:
  jao: ^0.3.0

dev_dependencies:
  build_runner: ^2.4.0
  jao_generator: ^0.3.0
```

## Usage

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

  @DateTimeField(autoNowAdd: true)
  late DateTime createdAt;
}
```

### 2. Run the Generator

```bash
dart run build_runner build
```

Or watch for changes:

```bash
dart run build_runner watch
```

## Generated Code

For a `User` model, the generator creates:

### Field Class (`User$`)

```dart
class User$ implements ModelFields<User> {
  const User$();

  final id = const IntFieldRef('id');
  final name = const StringFieldRef('name');
  final email = const StringFieldRef('email');
  final createdAt = const DateTimeFieldRef('created_at');
}
```

### Companion Class (`Users`)

```dart
class Users {
  static const $ = User$();
  static Manager<User> get objects => ...;

  static const tableName = 'user';
  static const pkField = 'id';

  static User fromRow(Map<String, dynamic> row) => ...;
  static Map<String, dynamic> toRow(User model) => ...;

  static final schema = ModelSchema(...);
}
```

## Build Optimization

For large projects, limit which files are scanned by adding a `build.yaml`:

```yaml
targets:
  $default:
    builders:
      jao_generator|jao:
        generate_for:
          include:
            - lib/models/**
```

## Model Options

### Custom Table Name

```dart
@Model(tableName: 'app_users')
class User {
  // ...
}
```

### Auto Timestamps

```dart
@Model()
class Post {
  @AutoField()
  late int id;

  @DateTimeField(autoNowAdd: true)  // Set on create
  late DateTime createdAt;

  @DateTimeField(autoNow: true)     // Set on every update
  late DateTime updatedAt;
}
```

## Supported Field Types

| Annotation | Generated FieldRef |
|------------|-------------------|
| `@AutoField()` | `IntFieldRef` |
| `@BigAutoField()` | `IntFieldRef` |
| `@CharField()` | `StringFieldRef` |
| `@TextField()` | `StringFieldRef` |
| `@IntegerField()` | `IntFieldRef` |
| `@BooleanField()` | `BoolFieldRef` |
| `@FloatField()` | `DoubleFieldRef` |
| `@DateTimeField()` | `DateTimeFieldRef` |
| `@DurationField()` | `DurationFieldRef` |

## Troubleshooting

### Generated file not found

Run the generator:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Slow builds

Add `generate_for` filter in `build.yaml` to only scan model directories.

### Conflicting outputs

```bash
dart run build_runner clean
dart run build_runner build
```

## Related Packages

- [jao](https://pub.dev/packages/jao) - Core ORM package
- [jao_cli](https://pub.dev/packages/jao_cli) - CLI tools for migrations

## License

MIT License - see [LICENSE](LICENSE) for details.
