import 'package:hsk_learner/sql/sql_helper.dart';

class ReviewFlashcardsSql{
  static void updateReview({required int id, required int time}) async {
    final db = await SQLHelper.db();
    db.rawUpdate("""
      UPDATE review set show_next = $time where id = $id 
    """);
  }
}