import 'package:hsk_learner/sql/sql_helper.dart';

class SchemaMigration{
  static run(){
    checkReviewTable();
  }
  static Future<void> checkReviewTable() async {
    final db = await SQLHelper.db();
    await db.transaction((txn) async {
      var exists = await txn.rawQuery("""
        SELECT count(*) as exist FROM sqlite_master WHERE type='table' AND name='review'
      """);
      print(exists);
      print(exists[0]["exist"]);
      if (exists[0]["exist"] == 0){
        txn.execute("""
          CREATE TABLE IF NOT EXISTS "review" (
            "id"	INTEGER NOT NULL,
            "deck"	TEXT,
            "show_next"	INTEGER,
            UNIQUE(id,deck) ON CONFLICT IGNORE
          )
        """);
        txn.execute("""
          insert into review (id, deck, show_next)
          SELECT id, course, strftime('%s', 'now') FROM courses
          JOIN stats on stats.wordid = courses.id
          GROUP BY courses.id
        """);
        txn.execute("""
          insert into review (id, deck)
          SELECT id, 'any' FROM courses
          JOIN stats on stats.wordid = courses.id
          GROUP BY courses.id
        """);
      }else{
        print("review exists");
      }
    });
  }
}