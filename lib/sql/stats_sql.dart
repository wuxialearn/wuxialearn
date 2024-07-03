import 'package:hsk_learner/sql/sql_helper.dart';

class StatsSql {
  static Future<List<Map<String, dynamic>>> getTimeline(
      {required int deckSize,
      required String sortBy,
      required String orderBy}) async {
    final db = await SQLHelper.db();
    return db.rawQuery("""
    SELECT string_date, right_occurrence, wrong_occurrence, 
    new_word,
    (right_occurrence + wrong_occurrence) as total,
    (right_occurrence - wrong_occurrence) as score
    FROM(
      SELECT
        DATE(stats.date, 'unixepoch') string_date,
        SUM(CASE stats.value WHEN 1 THEN 1 ELSE 0 END) right_occurrence,
        SUM(CASE stats.value WHEN 0 THEN 1 ELSE 0 END) wrong_occurrence,
        CASE WHEN MIN(date) >= cast(strftime('%s', 'now', '-7 days') as int) THEN 1 ELSE 0 END new_word
      FROM stats
      GROUP BY 
        string_date
    )
    WHERE string_date > DATE('now', '-7 days')
    ORDER BY $sortBy $orderBy
    LIMIT $deckSize;
    """);
  }

  static Future<List<Map<String, dynamic>>> getOverview() async {
    final db = await SQLHelper.db();
    const sql = """
    SELECT new_words, total_words - new_words as review_words, percent_correct, most_seen, most_seen_id
	FROM
      (SELECT
		count(1) as new_words  from (
		select count(1)from stats
		GROUP BY wordid
        HAVING MIN(stats.date) >= cast(strftime('%s', 'now', '-7 days') as int)
		)      
	  )	
      as t1,
      (SELECT
      count (1) as total_words from stats
	  where date >= cast(strftime('%s', 'now', '-7 days') as int)
      ) 
      as t2,
	  (SELECT 
		CAST (right_occurrence * 100.0 / (right_occurrence + wrong_occurrence) as INT)
		AS percent_correct
		FROM(
		  SELECT
			SUM(CASE stats.value WHEN 1 THEN 1 ELSE 0 END) right_occurrence,
			SUM(CASE stats.value WHEN 0 THEN 1 ELSE 0 END) wrong_occurrence
		  FROM stats
		  WHERE date >= cast(strftime('%s', 'now', '-7 days') as int)
		)
      ) 
      as t3,
	  (SELECT
      max (wordid) as most_seen_id, hanzi as most_seen from stats
	    JOIN courses on courses.id = stats.wordid
	    where date >= cast(strftime('%s', 'now', '-7 days') as int)
      ) 
      as t4
    """;
    final result = db.rawQuery(sql);
    return result;
  }

  static Future<List<Map<String, dynamic>>> getTotalStats() async {
    final db = await SQLHelper.db();
    const sql = """
    SELECT * FROM
      (SELECT
      CAST(count(wordid) as REAL) / count(id) * 100 as percent_current_hsk_completed
      FROM(SELECT wordid FROM stats GROUP BY wordid)
      RIGHT JOIN courses on courses.id = wordid
      WHERE courses.hsk = (
          SELECT max(hsk) as max_hsk
          FROM subunits_with_info as subunits JOIN units ON units.unit_id = unit
          WHERE subunits.completed = 1
        ) OR courses.hsk = (
          SELECT iif(most/CAST(2 as REAL) = 1, 1, most) FROM (
            SELECT max(hsk) as most
            FROM subunits_with_info as subunits JOIN units ON units.unit_id = unit
            WHERE subunits.completed = 1
            )
        )
      )
      as t1,
      (SELECT
      CAST(count(wordid) as REAL) / count(id) * 100 as percent_course_completed
      FROM(SELECT wordid FROM stats GROUP BY wordid)
      RIGHT JOIN courses on courses.id = wordid) 
      as t2,
      (SELECT
        COUNT(wordid) as number_of_words_seen
        FROM (SELECT wordid FROM stats GROUP BY wordid)
        RIGHT JOIN  courses on courses.id = wordid
      )as t3,
      (WITH cte AS (
        SELECT SUBSTR(hanzi, 1, 1) c, SUBSTR(hanzi, 2) hanzi
          FROM courses
          RIGHT JOIN (SELECT wordid FROM stats GROUP BY wordid) as stats
          ON stats.wordid = courses.id
          WHERE LENGTH(hanzi) > 0
          UNION ALL
          SELECT SUBSTR(hanzi, 1, 1), SUBSTR(hanzi, 2)
          FROM cte
          WHERE LENGTH(hanzi) > 0
        )
        SELECT COUNT(DISTINCT c) number_characters_seen
        FROM cte
      )as t4,
      (SELECT max(hsk) as current_hsk from 
          subunits_with_info as subunits JOIN units ON units.unit_id = unit
          WHERE subunits.completed = 1
      )as t5
    """;
    final result = db.rawQuery(sql);
    return result;
  }

  static Future<List<Map<String, dynamic>>> getStats(
      {required int deckSize,
      required String sortBy,
      required String orderBy,
      String where = ""}) async {
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
    $where
    ORDER BY $sortBy $orderBy
    LIMIT $deckSize;
    """);
  }

  static void insertStat({required int value, required int id}) async {
    final db = await SQLHelper.db();
    await db.rawInsert(
        "INSERT INTO stats(date, wordid, value) VALUES(strftime('%s', 'now'), $id, $value)");
  }
}
