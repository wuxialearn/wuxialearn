import 'package:hsk_learner/sql/sql_helper.dart';

class ReviewSql{

  static Future<List<Map<String, dynamic>>> getSrsReview({required int deckSize}) async {
    final db = await SQLHelper.db();
    String limit = "limit $deckSize";
    if (deckSize < 0){
      limit = "";
    }
    final a =  db.rawQuery("""
        SELECT t1.id, t1.hanzi, t1.pinyin, translations0, subunit,
        a_tl.translation as char_one, b_tl.translation as char_two, c_tl.translation as char_three, d_tl.translation as char_four
            from(
              SELECT
                id, hanzi, pinyin, translations0, subunit, unit,
                SUBSTR(hanzi, 1, 1) a, SUBSTR(hanzi, 2, 1) b,
                SUBSTR(hanzi, 3, 1) c, SUBSTR(hanzi, 4, 1) d
              FROM courses
            ) as t1
        left join unihan a_tl on t1.a = a_tl.hanzi
        left join unihan b_tl on t1.b = b_tl.hanzi  
        left join unihan c_tl on t1.c = c_tl.hanzi
        left join unihan d_tl on t1.d = d_tl.hanzi 
		    join review on review.id = t1.id
		    WHERE show_next < strftime('%s')
        GROUP BY t1.id
        ORDER BY show_next ASC
		    $limit
      """);
    return  a;
  }

  static Future<List<Map<String, dynamic>>> getReview({
    required int deckSize, required String sortBy, required String orderBy,
    required String deckName,
  }) async {
    final db = await SQLHelper.db();
    final a =  db.rawQuery("""
        SELECT t1.id, t1.score, t1.percent_correct, t1.hanzi,
        t1.translations0, t1.hsk, t1.pinyin,
        a_tl.translation as char_one, b_tl.translation as char_two, 
        c_tl.translation as char_three, d_tl.translation as char_four
        FROM (
          SELECT courses.id, right_occurrence, wrong_occurrence, 
            courses.hanzi, courses.hsk, courses.pinyin, courses.translations0,
            last_seen, (right_occurrence - wrong_occurrence) as score,
            ROUND(right_occurrence * 100.0 / (right_occurrence + wrong_occurrence), 1) AS percent_correct,
            SUBSTR(hanzi, 1, 1) a, SUBSTR(hanzi, 2, 1) b,
            SUBSTR(hanzi, 3, 1) c, SUBSTR(hanzi, 4, 1) d
            FROM(
              SELECT
              wordid,
              SUM(CASE recent_stats.value WHEN 1 THEN 1 ELSE 0 END) right_occurrence,
              SUM(CASE recent_stats.value WHEN 0 THEN 1 ELSE 0 END) wrong_occurrence,
              MAX(recent_stats.date) last_seen
              FROM(
              SELECT *
                ,ROW_NUMBER() OVER (
                PARTITION BY wordid ORDER BY date DESC
              )AS group_size
              FROM stats
              )AS recent_stats
              WHERE group_size <= 5
              GROUP BY wordid
            )
          INNER JOIN courses on courses.id = wordid
        )as t1
    left join unihan a_tl on t1.a = a_tl.hanzi
    left join unihan b_tl on t1.b = b_tl.hanzi  
    left join unihan c_tl on t1.c = c_tl.hanzi
    left join unihan d_tl on t1.d = d_tl.hanzi 
    join review on review.id = t1.id
    where deck = '$deckName'
    GROUP BY t1.id
    ORDER BY $sortBy $orderBy
    LIMIT $deckSize;
    """);
    return a;
  }
}