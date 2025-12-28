import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:jao_example/models/models.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405, body: 'Method not allowed');
  }

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

  try {
    final body = await context.request.body();
    final data = jsonDecode(body) as Map<String, dynamic>;

    if (!data.containsKey('choice')) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'choice is required'},
      );
    }

    final choiceId = data['choice'] as int;

    // Get the choice and verify it belongs to this poll
    final choice = await Choices.objects.getOrNull(choiceId);
    if (choice == null) {
      return Response.json(
        statusCode: 404,
        body: {'error': 'Choice not found'},
      );
    }

    if (choice.pollId != pollId) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'Choice does not belong to this poll'},
      );
    }

    // Increment the vote count
    await Choices.objects.filter(Choices.$.id.eq(choiceId)).update({'votes': choice.votes + 1});

    final updated = await Choices.objects.get(choiceId);

    return Response.json(
      body: {
        'id': updated.id,
        'poll': pollId,
        'choice_text': updated.choiceText,
        'votes': updated.votes,
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 400,
      body: {'error': e.toString()},
    );
  }
}
