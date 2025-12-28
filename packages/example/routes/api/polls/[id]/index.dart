import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:jao_example/models/models.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final pollId = int.tryParse(id);
  if (pollId == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'Invalid poll id'},
    );
  }

  return switch (context.request.method) {
    HttpMethod.get => _getPoll(pollId),
    HttpMethod.put => _updatePoll(context, pollId),
    HttpMethod.delete => _deletePoll(pollId),
    _ => Future.value(
        Response(statusCode: 405, body: 'Method not allowed'),
      ),
  };
}

Future<Response> _getPoll(int id) async {
  final poll = await Polls.objects.getOrNull(id);
  if (poll == null) {
    return Response.json(
      statusCode: 404,
      body: {'error': 'Poll not found'},
    );
  }

  final choices = await Choices.objects.filter(Choices.$.pollId.eq(id)).toList();

  return Response.json(
    body: {
      'id': poll.id,
      'question': poll.question,
      'pub_date': poll.pubDate.toIso8601String(),
      'choices': choices
          .map((c) => {
                'id': c.id,
                'choice_text': c.choiceText,
                'votes': c.votes,
              })
          .toList(),
    },
  );
}

Future<Response> _updatePoll(RequestContext context, int id) async {
  final poll = await Polls.objects.getOrNull(id);
  if (poll == null) {
    return Response.json(
      statusCode: 404,
      body: {'error': 'Poll not found'},
    );
  }

  try {
    final body = await context.request.body();
    final data = jsonDecode(body) as Map<String, dynamic>;

    if (!data.containsKey('question')) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'question is required'},
      );
    }

    await Polls.objects.filter(Polls.$.id.eq(id)).update({'question': data['question'] as String});

    final updated = await Polls.objects.get(id);

    return Response.json(
      body: {
        'id': updated.id,
        'question': updated.question,
        'pub_date': updated.pubDate.toIso8601String(),
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 400,
      body: {'error': e.toString()},
    );
  }
}

Future<Response> _deletePoll(int id) async {
  final poll = await Polls.objects.getOrNull(id);
  if (poll == null) {
    return Response.json(
      statusCode: 404,
      body: {'error': 'Poll not found'},
    );
  }

  // Delete associated choices first
  await Choices.objects.filter(Choices.$.pollId.eq(id)).delete();
  await Polls.objects.filter(Polls.$.id.eq(id)).delete();

  return Response(statusCode: 204);
}
