import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:jao_example/models/models.dart';

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _listPolls(),
    HttpMethod.post => _createPoll(context),
    _ => Future.value(
        Response(statusCode: 405, body: 'Method not allowed'),
      ),
  };
}

Future<Response> _listPolls() async {
  final polls = await Polls.objects.all().toList();
  return Response.json(
    body: polls
        .map((p) => {
              'id': p.id,
              'question': p.question,
              'pub_date': p.pubDate.toIso8601String(),
            })
        .toList(),
  );
}

Future<Response> _createPoll(RequestContext context) async {
  try {
    final body = await context.request.body();
    final data = jsonDecode(body) as Map<String, dynamic>;

    if (!data.containsKey('question')) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'question is required'},
      );
    }

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
  } catch (e) {
    return Response.json(
      statusCode: 400,
      body: {'error': e.toString()},
    );
  }
}
