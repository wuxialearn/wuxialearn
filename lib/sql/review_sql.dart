import 'package:hsk_learner/sql/sql_helper.dart';

class ReviewSql {
  static Future<List<Map<String, dynamic>>> getSrsReview(
      {required int deckSize}) async {
    final db = await SQLHelper.db();
    String limit = "limit $deckSize";
    if (deckSize < 0) {
      limit = "";
    }
    final a = db.rawQuery("""
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
    return a;
  }

  static Future<List<Map<String, dynamic>>> getUncategorizedWords({required String deck, required int deckSize}) async {
    final db = await SQLHelper.db();
    String limit = "limit $deckSize";
    if (deckSize < 0) {
      limit = "";
    }
    final a = await db.rawQuery("""
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
        WHERE deck = '$deck' AND rating_id IS NULL
        GROUP BY t1.id
        ORDER BY t1.id ASC
        $limit
      """);
    return a;
  }

  static Future<List<Map<String, dynamic>>> getReview({
    required int deckSize,
    required String sortBy,
    required String orderBy,
    required String deckName,
  }) async {
    final db = await SQLHelper.db();
    final a = db.rawQuery("""
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

  static Future<List<Map<String, dynamic>>> getReviewRatings() async {
    final db = await SQLHelper.db();
    final a = await db.rawQuery("""
        SELECT rating_id, rating_name, rating_duration_start, rating_duration_end
        from review_rating
        order by rating_duration_start asc
      """);
    return a;
  }

  static Future<void> setReviewRating(
      {required int id,
      required String name,
      required int start,
      required int end}) async {
    final db = await SQLHelper.db();
    db.rawUpdate("""
      update review_rating set rating_name = '$name', 
      rating_duration_start = $start, rating_duration_end = $end
      where rating_id = $id
    """);
  }

  static Future<List<Map<String, dynamic>>> test({required String deck}) async {
    final db = await SQLHelper.db();
    //await db.rawQuery("update review set rating_id = null where rating_id = ''");
    final a = await db.rawQuery("""
        SELECT rating_id from review  where rating_id = ''
      """);
    print(a);
    return a;
  }

  static Future<List<Map<String, dynamic>>> getProgress(
      {required String deck}) async {
    final db = await SQLHelper.db();
    final a = await db.rawQuery("""
        SELECT review_rating.rating_id, count(1) as count, rating_name, 1 as rs 
        from review_rating
        join review on  review.rating_id = review_rating.rating_id
        where deck = '$deck'
        group by review_rating.rating_id
        union ALL select review_rating.rating_id, 0 as count, rating_name, 2 from review_rating
        where review_rating.rating_id not in (
	          SELECT review_rating.rating_id from review_rating
            join review on  review.rating_id = review_rating.rating_id
            where deck = '$deck'
            group by review_rating.rating_id
        )
        union all select -1, count(1), 'uncategorized', 3
        from review where deck = '$deck' AND rating_id is null
        union all select -2, count(1), 'total', 4
        from review
        where deck = '$deck'
        order by rs
      """);
    return a;
  }

  static Future<void> insertRating(
      {required String name, required int start, required int end}) async {
    final db = await SQLHelper.db();
    await db.rawInsert("""
      insert into review_rating (rating_name, rating_duration_start, rating_duration_end)
      values ('$name', $start, $end)
    """);
  }

  static Future<void> deleteRating({required int id}) async {
    final db = await SQLHelper.db();
    db.rawDelete("""
    delete from review_rating where rating_id = $id
    """);
    db.rawUpdate("""
    update review set rating_id = null where rating_id = $id
    """);
  }


    
}
