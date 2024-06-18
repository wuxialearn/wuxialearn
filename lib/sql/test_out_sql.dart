import 'package:hsk_learner/sql/sql_helper.dart';
import 'package:sqflite/sqflite.dart';

class TestOutSql{
  static void completeHSKLevel(int hsk) async {
    final db = await SQLHelper.db();
    Batch testOutBatch = db.batch();
    testOutBatch.rawInsert("""
    UPDATE unit_info set completed = true where unit_id in 
      (select unit_id from units where hsk = $hsk)
    """);
    testOutBatch.rawInsert("""
    update subunit_info set completed = 1 where subunit_id in (SELECT subunit_id from subunits
        join units on units.unit_id = subunits.unit
		    where units.hsk <= $hsk
		order by subunits.unit)
    """);
    testOutBatch.rawInsert( """
    INSERT INTO stats(date, wordid, value)
        SELECT strftime('%s', 'now'), courses.id, 1 from courses
        join units on units.unit_id = courses.unit
		    where units.hsk <= $hsk
    """);
    testOutBatch.rawInsert("""
      INSERT INTO review(id, deck, show_next) select id, course, strftime('%s', 'now') + (1 * 24 * 60 * 60)
      from courses where hsk <= $hsk
    """);
    testOutBatch.commit();
  }


  static Future<List<Map<String, dynamic>>> getTestOutWords({required int hsk}) async {
    final db = await SQLHelper.db();
    var a =  db.rawQuery("""
      SELECT
          id, hanzi, pinyin, translations0
        FROM courses
        join units on units.unit_id = courses.unit
        where units.hsk <= $hsk
        order by random()
		limit 15
    """);
    return a;
  }
}