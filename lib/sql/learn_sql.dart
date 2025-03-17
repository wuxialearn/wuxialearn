import 'package:hsk_learner/sql/sql_helper.dart';

class LearnSql {
  static Future<List<Map<String, dynamic>>> count() async {
    final db = await SQLHelper.db();
    return db.rawQuery("""
      SELECT
        SUM(CASE WHEN hsk = 1 THEN 1 ELSE 0 END) hsk1,
        SUM(CASE WHEN hsk = 2 THEN 1 ELSE 0 END) hsk2,
        SUM(CASE WHEN hsk = 3 THEN 1 ELSE 0 END) hsk3,
        SUM(CASE WHEN hsk = 4 THEN 1 ELSE 0 END) hsk4,
        SUM(CASE WHEN hsk = 5 THEN 1 ELSE 0 END) hsk5,
        SUM(CASE WHEN hsk = 6 THEN 1 ELSE 0 END) hsk6
      FROM courses  
    """);
  }

  static Future<List<Map<String, dynamic>>> count2({
    required String courseName,
  }) async {
    final db = await SQLHelper.db();
    var result = db.rawQuery("""
      SELECT
        *
      FROM units_with_info as units
      WHERE course = '$courseName'
      and visible = 1
      ORDER BY unit_order
    """);
    return result;
  }

  static Future<List<Map<String, dynamic>>> getHskLevel(int unit) async {
    final db = await SQLHelper.db();
    return db.rawQuery("""
      SELECT
        id, hanzi, pinyin, translations0, subunit
      FROM courses
      WHERE unit = $unit
      ORDER BY subunit ASC
    """);
  }

  static Future<List<Map<String, dynamic>>> getUnit(int unit) async {
    final db = await SQLHelper.db();
    return db.rawQuery("""
      SELECT
        id, hanzi, pinyin, translations0, subunit, unit
      FROM courses
      WHERE unit = $unit
      ORDER BY subunit ASC
    """);
  }

  static Future<List<Map<String, dynamic>>> getUnitWithLiteralMeaning(
    int unit,
  ) async {
    final db = await SQLHelper.db();
    return db.rawQuery("""
        SELECT t1.id, t1.hanzi, t1.pinyin, translations0, subunit,
        a_tl.translation as char_one, b_tl.translation as char_two, c_tl.translation as char_three, d_tl.translation as char_four
            from(
              SELECT
                id, hanzi, pinyin, translations0, subunit, unit,
                SUBSTR(hanzi, 1, 1) a, SUBSTR(hanzi, 2, 1) b,
                SUBSTR(hanzi, 3, 1) c, SUBSTR(hanzi, 4, 1) d
              FROM courses
              WHERE unit = $unit
            ) as t1
        left join unihan a_tl on t1.a = a_tl.hanzi
        left join unihan b_tl on t1.b = b_tl.hanzi  
        left join unihan c_tl on t1.c = c_tl.hanzi
        left join unihan d_tl on t1.d = d_tl.hanzi 
        GROUP BY t1.id
        ORDER BY subunit ASC
    """);
  }

  static Future<List<Map<String, dynamic>>> getExamples(String word) async {
    final db = await SQLHelper.db();
    return db.rawQuery("""
      SELECT
        characters, pinyin, meaning 
      FROM sentences  
      WHERE instr(characters, '$word') > 0 
      ORDER BY unit ASC
      LIMIT 3;
    """);
  }

  static Future<List<Map<String, dynamic>>> getSentences(int unit) async {
    final db = await SQLHelper.db();
    return db.rawQuery("""
      SELECT
        characters, pinyin, meaning, id, subunit
      FROM sentences  
      WHERE unit = $unit
      ORDER BY subunit
    """);
  }

  static Future<List<Map<String, dynamic>>> getSentencesForSubunit(
    int unit,
    int subunit,
  ) async {
    final db = await SQLHelper.db();
    return db.rawQuery("""
      SELECT
        characters, pinyin, meaning, id, subunit
      FROM sentences  
      WHERE unit = $unit
      AND subunit = $subunit
      ORDER BY subunit
    """);
  }

  static void completeUnit({required int unit}) async {
    final db = await SQLHelper.db();
    await db.rawInsert(
      'UPDATE unit_info SET completed = 1 WHERE unit_id = $unit ',
    );
  }

  static void completeSubUnit({required int unit, required int subUnit}) async {
    final db = await SQLHelper.db();
    final String sql = """
      UPDATE subunit_info SET completed = 1 
      WHERE subunit_id = (
        select subunit_id from subunits
        where unit = $unit AND subunit = $subUnit
        limit 1
      )
    """;
    await db.rawInsert(sql);
  }

  static Future<List<Map<String, dynamic>>> getSubunitInfo({
    required int unit,
  }) async {
    final db = await SQLHelper.db();
    var result = db.rawQuery("""
      SELECT unit, subunit, completed
      FROM subunits_with_info as subunits
      WHERE unit = $unit
    """);
    return result;
  }

  static Future<List<Map<String, dynamic>>> getKnownSentences(
    List<Map<String, dynamic>> words,
  ) async {
    final db = await SQLHelper.db();
    String sql = "SELECT * from sentences where characters REGEXP";
    sql += "'^(?:(?: ，|。";
    for (int i = 0; i < words.length; i++) {
      sql += "| ${words[i]["hanzi"]}";
    }
    sql += "))*\$'";
    return db.rawQuery(sql);
  }
}
