# Building a Polls API with JAO ORM

This tutorial walks you through building a Django-style Polls API using [JAO](../jao) (Just Another ORM) and [Dart Frog](https://dartfrog.vgv.dev/). Inspired by the [Django Polls API Tutorial](https://books.agiliq.com/projects/django-api-polls-tutorial/en/latest/index.html).

## Prerequisites

- Dart SDK 3.6.0 or later
- Basic knowledge of Dart

## Project Setup

### 1. Create a new Dart Frog project

```bash
dart_frog create polls_api
cd polls_api
```

### 2. Add dependencies

Update your `pubspec.yaml`:

```yaml
dependencies:
  dart_frog: ^1.2.0
  jao: ^0.0.1

dev_dependencies:
  build_runner: ^2.4.0
  jao_generator: ^0.0.1
```

Run `dart pub get` to install dependencies.

### 3. Install JAO CLI

Install the JAO CLI globally:

```bash
dart pub global activate jao_cli
```

### 4. Initialize JAO

```bash
jao init
```

This creates:
- `jao.yaml` - Configuration file
- `lib/migrations/` - Migrations directory

## Defining Models

Create `lib/models/models.dart`:

```dart
library;

import 'package:jao/jao.dart';

part 'models.g.dart';

@Model()
class Poll {
  @AutoField()
  late int id;

  @CharField(maxLength: 200)
  late String question;

  @DateTimeField(autoNowAdd: true)
  late DateTime pubDate;
}

@Model()
class Choice {
  @AutoField()
  late int id;

  @ForeignKey(Poll)
  late int pollId;

  @CharField(maxLength: 200)
  late String choiceText;

  @IntegerField()
  late int votes;
}
```

### Field Types

| Annotation | Description |
|------------|-------------|
| `@AutoField()` | Auto-incrementing primary key |
| `@CharField(maxLength: n)` | Variable-length string |
| `@IntegerField()` | Integer field |
| `@DateTimeField(autoNowAdd: true)` | Timestamp, auto-set on creation |
| `@ForeignKey(Model)` | Foreign key relationship |

## Generate Code

Run the code generator:

```bash
dart run build_runner build --delete-conflicting-outputs
```

This generates `lib/models/models.g.dart` with:
- `Polls` companion class with `Polls.objects` manager
- `Choices` companion class with `Choices.objects` manager
- Type-safe field references (`Polls.$`, `Choices.$`)

## Create Migrations

Generate migrations from your models:

```bash
jao makemigrations
```

Apply migrations to create database tables:

```bash
jao migrate
```

Check migration status:

```bash
jao status
```

## Database Middleware

Create `routes/_middleware.dart` to initialize the database connection:

```dart
import 'package:dart_frog/dart_frog.dart';
import 'package:jao/jao.dart';

Handler middleware(Handler handler) {
  return (context) async {
    await Jao.configure(
      adapter: SqliteAdapter(),
      config: DatabaseConfig.sqlite('database.db'),
    );
    return handler(context);
  };
}
```

## Building the API

### Polls List & Create

Create `routes/api/polls/index.dart`:

```dart
import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:your_app/models/models.dart';

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _listPolls(),
    HttpMethod.post => _createPoll(context),
    _ => Future.value(Response(statusCode: 405)),
  };
}

Future<Response> _listPolls() async {
  final polls = await Polls.objects.all().toList();
  return Response.json(
    body: polls.map((p) => {
      'id': p.id,
      'question': p.question,
      'pub_date': p.pubDate.toIso8601String(),
    }).toList(),
  );
}

Future<Response> _createPoll(RequestContext context) async {
  final body = await context.request.body();
  final data = jsonDecode(body) as Map<String, dynamic>;

  final poll = await Polls.objects.create({
    'question': data['question'] as String,
  });

  return Response.json(
    statusCode: 201,
    body: {
      'id': poll.id,
      'question': poll.question,
      'pub_date': poll.pubDate.toIso8601String(),
    },
  );
}
```

### Poll Detail, Update & Delete

Create `routes/api/polls/[id]/index.dart`:

```dart
import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:your_app/models/models.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final pollId = int.tryParse(id);
  if (pollId == null) {
    return Response.json(statusCode: 400, body: {'error': 'Invalid id'});
  }

  return switch (context.request.method) {
    HttpMethod.get => _getPoll(pollId),
    HttpMethod.put => _updatePoll(context, pollId),
    HttpMethod.delete => _deletePoll(pollId),
    _ => Future.value(Response(statusCode: 405)),
  };
}

Future<Response> _getPoll(int id) async {
  final poll = await Polls.objects.getOrNull(id);
  if (poll == null) {
    return Response.json(statusCode: 404, body: {'error': 'Not found'});
  }

  final choices = await Choices.objects
      .filter(Choices.$.pollId.eq(id))
      .toList();

  return Response.json(body: {
    'id': poll.id,
    'question': poll.question,
    'pub_date': poll.pubDate.toIso8601String(),
    'choices': choices.map((c) => {
      'id': c.id,
      'choice_text': c.choiceText,
      'votes': c.votes,
    }).toList(),
  });
}

Future<Response> _updatePoll(RequestContext context, int id) async {
  final poll = await Polls.objects.getOrNull(id);
  if (poll == null) {
    return Response.json(statusCode: 404, body: {'error': 'Not found'});
  }

  final body = await context.request.body();
  final data = jsonDecode(body) as Map<String, dynamic>;

  await Polls.objects
      .filter(Polls.$.id.eq(id))
      .update({'question': data['question']});

  final updated = await Polls.objects.get(id);
  return Response.json(body: {
    'id': updated.id,
    'question': updated.question,
    'pub_date': updated.pubDate.toIso8601String(),
  });
}

Future<Response> _deletePoll(int id) async {
  final poll = await Polls.objects.getOrNull(id);
  if (poll == null) {
    return Response.json(statusCode: 404, body: {'error': 'Not found'});
  }

  await Choices.objects.filter(Choices.$.pollId.eq(id)).delete();
  await Polls.objects.filter(Polls.$.id.eq(id)).delete();

  return Response(statusCode: 204);
}
```

### Choices

Create `routes/api/polls/[id]/choices.dart`:

```dart
import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:your_app/models/models.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final pollId = int.tryParse(id);
  if (pollId == null) {
    return Response.json(statusCode: 400, body: {'error': 'Invalid id'});
  }

  final poll = await Polls.objects.getOrNull(pollId);
  if (poll == null) {
    return Response.json(statusCode: 404, body: {'error': 'Poll not found'});
  }

  return switch (context.request.method) {
    HttpMethod.get => _listChoices(pollId),
    HttpMethod.post => _createChoice(context, pollId),
    _ => Future.value(Response(statusCode: 405)),
  };
}

Future<Response> _listChoices(int pollId) async {
  final choices = await Choices.objects
      .filter(Choices.$.pollId.eq(pollId))
      .toList();

  return Response.json(
    body: choices.map((c) => {
      'id': c.id,
      'poll': pollId,
      'choice_text': c.choiceText,
      'votes': c.votes,
    }).toList(),
  );
}

Future<Response> _createChoice(RequestContext context, int pollId) async {
  final body = await context.request.body();
  final data = jsonDecode(body) as Map<String, dynamic>;

  final choice = await Choices.objects.create({
    'poll_id': pollId,
    'choice_text': data['choice_text'],
    'votes': 0,
  });

  return Response.json(
    statusCode: 201,
    body: {
      'id': choice.id,
      'poll': pollId,
      'choice_text': choice.choiceText,
      'votes': choice.votes,
    },
  );
}
```

### Voting

Create `routes/api/polls/[id]/vote.dart`:

```dart
import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:your_app/models/models.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }

  final pollId = int.tryParse(id);
  if (pollId == null) {
    return Response.json(statusCode: 400, body: {'error': 'Invalid id'});
  }

  final poll = await Polls.objects.getOrNull(pollId);
  if (poll == null) {
    return Response.json(statusCode: 404, body: {'error': 'Poll not found'});
  }

  final body = await context.request.body();
  final data = jsonDecode(body) as Map<String, dynamic>;
  final choiceId = data['choice'] as int;

  final choice = await Choices.objects.getOrNull(choiceId);
  if (choice == null || choice.pollId != pollId) {
    return Response.json(statusCode: 400, body: {'error': 'Invalid choice'});
  }

  await Choices.objects
      .filter(Choices.$.id.eq(choiceId))
      .update({'votes': choice.votes + 1});

  final updated = await Choices.objects.get(choiceId);

  return Response.json(body: {
    'id': updated.id,
    'poll': pollId,
    'choice_text': updated.choiceText,
    'votes': updated.votes,
  });
}
```

## Running the Server

Start the development server:

```bash
dart_frog dev
```

## Testing the API

### Create a Poll

```bash
curl -X POST http://localhost:8080/api/polls \
  -H "Content-Type: application/json" \
  -d '{"question": "What is your favorite color?"}'
```

### Add Choices

```bash
curl -X POST http://localhost:8080/api/polls/1/choices \
  -H "Content-Type: application/json" \
  -d '{"choice_text": "Red"}'

curl -X POST http://localhost:8080/api/polls/1/choices \
  -H "Content-Type: application/json" \
  -d '{"choice_text": "Blue"}'
```

### Vote

```bash
curl -X POST http://localhost:8080/api/polls/1/vote \
  -H "Content-Type: application/json" \
  -d '{"choice": 1}'
```

### View Poll with Results

```bash
curl http://localhost:8080/api/polls/1
```

Response:
```json
{
  "id": 1,
  "question": "What is your favorite color?",
  "pub_date": "2025-12-28T12:09:44.292241Z",
  "choices": [
    {"id": 1, "choice_text": "Red", "votes": 1},
    {"id": 2, "choice_text": "Blue", "votes": 0}
  ]
}
```

## JAO Query Reference

### CRUD Operations

```dart
// Create
final poll = await Polls.objects.create({'question': 'New poll?'});

// Read all
final polls = await Polls.objects.all().toList();

// Read one
final poll = await Polls.objects.get(1);
final pollOrNull = await Polls.objects.getOrNull(1);

// Update
await Polls.objects.filter(Polls.$.id.eq(1)).update({'question': 'Updated?'});

// Delete
await Polls.objects.filter(Polls.$.id.eq(1)).delete();
```

### Filtering

```dart
// Equality
Polls.$.id.eq(1)

// Comparison
Choices.$.votes.gt(10)
Choices.$.votes.gte(10)
Choices.$.votes.lt(100)
Choices.$.votes.lte(100)

// String operations
Polls.$.question.contains('color')
Polls.$.question.startsWith('What')
Polls.$.question.iContains('COLOR')  // case-insensitive

// Combining conditions
Polls.objects.filter(
  Q(Polls.$.id.gt(5)) & Q(Polls.$.question.contains('test'))
)
```

### Ordering

```dart
await Choices.objects
    .filter(Choices.$.pollId.eq(1))
    .orderBy(Choices.$.votes.desc())
    .toList();
```

## Summary

You've built a complete Polls API with:
- Django-style model definitions
- Auto-generated migrations
- Type-safe queries with Q expressions
- Full CRUD operations
- Voting functionality

JAO provides a familiar Django-like experience for Dart developers building database-backed applications.
