import 'package:hsk_learner/sql/sql_helper.dart';

class ReviewFlashcardsSql {
  static void updateReview(
      {required int id, required int time, required int ratingId}) async {
    final db = await SQLHelper.db();
    db.rawUpdate("""
      UPDATE review set show_next = $time, rating_id = $ratingId where id = $id 
    """);
  }
}
