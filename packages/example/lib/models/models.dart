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
  late int? pollId;

  @CharField(maxLength: 200)
  late String choiceText;

  @IntegerField()
  late int votes;
}
