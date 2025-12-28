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

  // Check if poll exists
  final poll = await Polls.objects.getOrNull(pollId);
  if (poll == null) {
    return Response.json(
      statusCode: 404,
      body: {'error': 'Poll not found'},
    );
  }

  return switch (context.request.method) {
    HttpMethod.get => _listChoices(pollId),
    HttpMethod.post => _createChoice(context, pollId),
    _ => Future.value(
        Response(statusCode: 405, body: 'Method not allowed'),
      ),
  };
}

Future<Response> _listChoices(int pollId) async {
  final choices = await Choices.objects
      .filter(Choices.$.pollId.eq(pollId))
      .toList();

  return Response.json(
    body: choices
        .map((c) => {
              'id': c.id,
              'poll': pollId,
              'choice_text': c.choiceText,
              'votes': c.votes,
            })
        .toList(),
  );
}

Future<Response> _createChoice(RequestContext context, int pollId) async {
  try {
    final body = await context.request.body();
    final data = jsonDecode(body) as Map<String, dynamic>;

    if (!data.containsKey('choice_text')) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'choice_text is required'},
      );
    }

    final choice = await Choices.objects.create({
      'poll_id': pollId,
      'choice_text': data['choice_text'] as String,
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
  } catch (e) {
    return Response.json(
      statusCode: 400,
      body: {'error': e.toString()},
    );
  }
}
