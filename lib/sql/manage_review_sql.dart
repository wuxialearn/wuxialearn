import 'package:hsk_learner/sql/sql_helper.dart';

class ManageReviewSql{
  static Future<void> removeFromDeck({required int id, required String deck}) async {
    final db = await SQLHelper.db();
    db.rawDelete("""
      delete from review where deck = '$deck' and id = $id
    """);
  }

  static Future<List<Map<String, dynamic>>> getManageReview({required int deckSize, required String sortBy, required String orderBy, required String deck}) async {
    final db = await SQLHelper.db();
    return db.rawQuery("""
    SELECT courses.id, right_occurrence, wrong_occurrence, 
    courses.hanzi, courses.hsk, courses.pinyin, courses.translations0,
    last_seen,
    (right_occurrence - wrong_occurrence) as score,
    ROUND(right_occurrence * 100.0 / (right_occurrence + wrong_occurrence), 1) AS percent_correct
    FROM(
      SELECT
        wordid,
        SUM(CASE stats.value WHEN 1 THEN 1 ELSE 0 END) right_occurrence,
        SUM(CASE stats.value WHEN 0 THEN 1 ELSE 0 END) wrong_occurrence,
        MAX(stats.date) last_seen
      FROM stats
      WHERE date > 0
      GROUP BY 
        wordid
    )
    INNER JOIN courses on courses.id = wordid
    join review on review.id = wordid
    $deck
    ORDER BY $sortBy $orderBy
    LIMIT $deckSize;
    """);
  }

  static void addToReviewDeck ({required int id, required String deck, required bool value}) async {
    final db = await SQLHelper.db();
    await db.transaction((txn) async {
      await txn.rawInsert(
          "INSERT INTO review(id, deck) VALUES($id, '$deck')"
      );
      await txn.rawInsert(
          "INSERT INTO review(id, deck) VALUES($id, 'any')"
      );
      DateTime duration = switch(value){
        true => DateTime.now().add(const Duration(days: 4)),
        false =>  DateTime.now().add(const Duration(minutes: 1))
      };
      int timeStamp = duration.toUtc().millisecondsSinceEpoch ~/ 1000;
      txn.rawUpdate("""
        UPDATE review SET show_next = $timeStamp WHERE id = $id
      """);
    });

  }

}