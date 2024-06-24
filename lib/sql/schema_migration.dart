import 'package:hsk_learner/sql/sql_helper.dart';

class SchemaMigration{
  static run() async {
    await checkReviewTable();
    checkReviewRating();
  }
  static Future<void> checkReviewTable() async {
    final db = await SQLHelper.db();
    await db.transaction((txn) async {
      var exists = await SQLHelper.tableExists("review", txn);
      print(exists);
      if (!exists){
        txn.execute("""
          CREATE TABLE IF NOT EXISTS "review" (
            "id"	INTEGER NOT NULL,
            "deck"	TEXT,
            "show_next"	INTEGER,
            "rating_id" INTEGER,
            UNIQUE(id,deck) ON CONFLICT IGNORE
          )
        """);
        txn.execute("""
          CREATE TABLE IF NOT EXISTS "review_rating" (
            "rating_id"	INTEGER PRIMARY KEY,
            "rating_name" text not null,
            "rating_duration_start" integer not null,
            "rating_duration_end" integer not null,
            "rating_options" text,
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

  static Future<void> checkReviewRating() async{
    final db = await SQLHelper.db();
    await db.transaction((txn) async {
      var exists = await SQLHelper.tableExists("review_rating", txn);
      print("review rating exists: $exists");
      print(exists);
      if (!exists){
        txn.execute("""
          CREATE TABLE IF NOT EXISTS "review_rating" (
            "rating_id"	INTEGER PRIMARY KEY,
            "rating_name" text not null,
            "rating_duration_start" integer not null,
            "rating_duration_end" integer not null,
            "rating_options" text
          )
        """);
        String again = "again";
        int againStart = const Duration(minutes: 1).inSeconds;
        String hard = "hard";
        int hardStart = const Duration(minutes: 6).inSeconds;
        String good = "good";
        int goodStart = const Duration(hours: 12).inSeconds;
        String easy = "easy";
        int easyStart = const Duration(days: 4).inSeconds;
        String perfect = "perfect";
        int perfectStart = const Duration(days: 10).inSeconds;
        int perfectEnd = const Duration(days: 30).inSeconds;

        txn.rawInsert("""
        insert into review_rating ('rating_name', rating_duration_start, rating_duration_end) 
        values 
        ('$again', $againStart, $againStart),
        ('$hard', $hardStart, $hardStart),
        ('$good', $goodStart, $goodStart),
        ('$easy', $easyStart, $easyStart),
        ('$perfect', $perfectStart, $perfectEnd)
        
        """);
        txn.execute("""
          ALTER TABLE review ADD COLUMN rating_id integer;
        """);
      }else{
        print("review rating exists");
      }
    });
  }
}