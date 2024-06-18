import 'package:hsk_learner/sql/sql_helper.dart';

class WordViewSql{

  static Future<List<Map<String, dynamic>>> getSentenceFromId(int id) async {
    final db = await SQLHelper.db();
    return db.rawQuery("""
    SELECT * from sentences where characters like '%' || (
      SELECT hanzi from courses where id = $id
    ) || '%'
    order by unit asc
    """);
  }

  static Future<List<Map<String, dynamic>>> getWordInfo(int id) async {
    final db = await SQLHelper.db();
    return db.rawQuery(""" 
     SELECT t1.id, t1.hanzi, t1.pinyin, t1.translations0, t1.translations1, t1.translations2,
      t1.unit, t1.hsk, t1.subunit,	t1.course, review.show_next,
	  min(stats.date) as first_seen, max(stats.date) as last_seen, count(stats.wordid) as total_seen,
	  sum(case when stats.value = 1 Then 1 else 0 end) /  CAST(count(stats.wordid) AS FLOAT) * 100 total_correct,
      a_tl.translation as char_one, b_tl.translation as char_two, c_tl.translation as char_three, d_tl.translation as char_four
        from (
            SELECT courses.id, courses.hanzi, translations0, translations1, translations2,
            courses.pinyin, unit, hsk, subunit,	course,
             SUBSTR(hanzi, 1, 1) a, SUBSTR(hanzi, 2, 1) b,
            SUBSTR(hanzi, 3, 1) c, SUBSTR(hanzi, 4, 1) d FROM courses where id = $id
          ) as t1
          left join unihan a_tl on t1.a = a_tl.hanzi
          left join unihan b_tl on t1.b = b_tl.hanzi  
          left join unihan c_tl on t1.c = c_tl.hanzi
          left join unihan d_tl on t1.d = d_tl.hanzi 
          left join stats on stats.wordid = t1.id
          left join review on review.id = t1.id
          order by t1.id
    """);
  }

}