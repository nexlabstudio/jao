import 'package:jao/jao.dart';

class CreateTables extends Migration {
  @override
  String get name => 'create_tables';

  @override
  void up(MigrationBuilder builder) {
    builder.createTable('poll', (table) {
      table.id('id');
      table.string('question', length: 255);
      table.timestampTz('pub_date');
    });
    builder.createTable('choice', (table) {
      table.id('id');
      table.integer('poll_id');
      table.string('choice_text', length: 255);
      table.integer('votes');
    });
  }

  @override
  void down(MigrationBuilder builder) {
    builder.dropTable('choice');
    builder.dropTable('poll');
  }
}
