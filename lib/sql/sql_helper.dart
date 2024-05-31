import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:postgres/postgres.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:d4_dsv/d4_dsv.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'connection_db_info.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SQLHelper {
  static Future<sql.Database> db() async {
    if (kIsWeb){
      var factory = databaseFactoryFfiWeb;
      var exists = await factory.databaseExists("demo_asset_example.db");
      if(!exists){
        final data = await rootBundle.load(url.join('assets', 'example.db'));
        final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await factory.writeDatabaseBytes("demo_asset_example.db", bytes);
      }
      return factory.openDatabase('demo_asset_example.db');
    }
    late String databasesPath;
    late String path;
    late bool exists;
    if (Platform.isWindows || Platform.isLinux) {
      //var databaseFactory = databaseFactoryFfi;
      databasesPath = (await path_provider.getApplicationSupportDirectory()).path;
      path = join(databasesPath, "demo_asset_example.db");
      // Check if the database exists
      exists = await File(path).exists();
    }else{
      databasesPath = await sql.getDatabasesPath();
      path = join(databasesPath, "demo_asset_example.db");
      // Check if the database exists
      exists = await sql.databaseExists(path);
    }
    if (!exists) {
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}
      // Copy from asset
      ByteData data = await rootBundle.load("assets/example.db");
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      // Write and flush the bytes written
      await File(path).writeAsBytes(bytes, flush: true);
    } else {
    }
    return sql.openDatabase(path);

  }



  static Future<List<Map<String, dynamic>>> getPreferences() async {
    final db = await SQLHelper.db();
    return db.rawQuery("SELECT * FROM preferences; ");

  }

  //raw query
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

  static Future<List<Map<String, dynamic>>> count2({required String courseName}) async {
    final db = await SQLHelper.db();
    var result =
     db.rawQuery("""
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
    print("getUnit");
    return db.rawQuery("""
      SELECT
        id, hanzi, pinyin, translations0, subunit, unit
      FROM courses
      WHERE unit = $unit
      ORDER BY subunit ASC
    """);
  }


  static Future<List<Map<String, dynamic>>> getUnitWithLiteralMeaning(int unit) async {
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

  static Future<List<Map<String, dynamic>>> getSentencesForSubunit(int unit, int subunit) async {
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


  static void completeUnit ({required int unit,}) async {
    final db = await SQLHelper.db();
    await db.rawInsert('UPDATE unit_info SET completed = 1 WHERE unit_id = $unit ');
  }

  static void completeSubUnit({required int unit, required int subUnit }) async {
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

  static Future<List<Map<String, dynamic>>> getSubunitInfo({required int unit,}) async{
    final db = await SQLHelper.db();
    var result =
     db.rawQuery("""
      SELECT unit, subunit, completed
      FROM subunits_with_info as subunits
      WHERE unit = $unit
    """);
    return result;
  }

  static void insertPreference ({required String name, required String value, required String type}) async {
    final db = await SQLHelper.db();
    await db.rawInsert("""
        insert into preferences(name, value, type) values('$name', '$value', '$type')
        """);
  }

  static void setPreference ({required String name, required String value, required String type}) async {
    final db = await SQLHelper.db();
    await db.rawInsert("UPDATE preferences SET name = '$name', value = '$value', type  = '$type' WHERE name = '$name' ");
  }

  static void insertStat ({required int value, required int id}) async {
    final db = await SQLHelper.db();
    await db.rawInsert(
        "INSERT INTO stats(date, wordid, value) VALUES(strftime('%s', 'now'), $id, $value)"
    );
  }

  static void addToReviewDeck ({required int id, required String deck}) async {
    final db = await SQLHelper.db();
    await db.rawInsert(
        "INSERT INTO review(id, deck) VALUES($id, '$deck')"
    );
    await db.rawInsert(
        "INSERT INTO review(id, deck) VALUES($id, 'any')"
    );
  }

  static void deleteStats() async{
    final db = await SQLHelper.db();
    await db.rawDelete("delete from stats");
  }

  static Future<List<Map<String, dynamic>>> getStats({required int deckSize, required String sortBy, required String orderBy, String where = ""}) async {
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

  static Future<void> removeFromDeck({required int id, required String deck}) async {
    final db = await SQLHelper.db();
    db.rawDelete("""
      delete from review where deck = '$deck' and id = $id
    """);
  }


  static Future<List<Map<String, dynamic>>> getKnownWords() async {
    final db = await SQLHelper.db();
    return db.rawQuery("""
    SELECT wordid, courses.hanzi
    FROM(SELECT DISTINCT wordid FROM stats)
    INNER JOIN courses on courses.id = wordid  
    """);
  }

  static Future<List<Map<String, dynamic>>> getKnownSentences(List<Map<String, dynamic>> words) async {
    final db = await SQLHelper.db();
    String sql = "SELECT * from sentences where characters REGEXP";
    sql += "'^(?:(?: ，|。";
    for(int i = 0; i< words.length; i++){
      sql += "| ${words[i]["hanzi"]}";
    }
    sql += "))*\$'";
    return db.rawQuery(sql);
  }

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
      t1.unit, t1.hsk, t1.subunit,	t1.course,
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
          order by t1.id
    """);
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

  static Future<List<Map<String, dynamic>>> getOverview({required int deckSize, required String sortBy, required String orderBy}) async {
    final db = await SQLHelper.db();
    return db.rawQuery("""
    SELECT wordid, right_occurrence, wrong_occurrence, 
    courses.hanzi, courses.hsk, courses.pinyin, courses.translations0,
    new_word,
    (right_occurrence - wrong_occurrence) as score 
    FROM(
      SELECT
        wordid,
        SUM(CASE stats.value WHEN 1 THEN 1 ELSE 0 END) right_occurrence,
        SUM(CASE stats.value WHEN 0 THEN 1 ELSE 0 END) wrong_occurrence,
        CASE WHEN MIN(stats.date) >= cast(strftime('%s', 'now', '-7 days') as int) THEN 1 ELSE 0 END new_word
      FROM stats
      WHERE date > 0
      GROUP BY 
        wordid
    )
    INNER JOIN courses on courses.id = wordid
   
    ORDER BY $sortBy $orderBy
    LIMIT $deckSize;
    """);
  }

  static Future<List<Map<String, dynamic>>> getTimeline({required int deckSize, required String sortBy, required String orderBy}) async {
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

  static Future<List<Map<String, dynamic>>> getTestOutWords({required int hsk}) async {
    final db = await SQLHelper.db();
    var a =  db.rawQuery("""
      SELECT
          id, hanzi, pinyin, translations0
        FROM courses
        join units on units.unit_id = courses.unit
        where units.hsk <= $hsk
        order by random()
		limit 5
    """);
    return a;
  }


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
      INSERT INTO review(id, deck) select id, course 
      from courses where hsk <= $hsk
    """);
    testOutBatch.commit();
  }

  static Future<List<Map<String, dynamic>>> sqlTest(String sql) async {
    final db = await SQLHelper.db();
    return db.rawQuery(sql);
  }

  static Future<List<Map<String, dynamic>>> queryBuilder(List wordList) async {
    String sql = "";
    for (var value in wordList) {
      sql += """
      SELECT 
        characters, pinyin, meaning 
      FROM sentences  
      WHERE instr(characters, '$value') > 0 LIMIT 3 ;
    """;
    }
    final result = await sqlTest(sql);
    return result;
  }
  static late PostgreSQLConnection connection;
  static bool connected = false;
  static Future<PostgreSQLConnection> psql() async{
    if (connected == false || connection.isClosed){
      // will be added back later
      ConnectionInfo connectionInfo = ConnectionInfo();
      connection = PostgreSQLConnection(connectionInfo.host, connectionInfo.port, connectionInfo.databaseName, username: connectionInfo.username, password: connectionInfo.password, useSSL: connectionInfo.useSSL);
      await connection.open();
      connected = true;
    }
    return connection;
  }

  static Future<bool> updateSqliteFromPg() async {
    final pgdb = await SQLHelper.psql();
    List<Map<String, Map<String, dynamic>>> hsk = await pgdb.mappedResultsQuery("""
      SELECT * FROM courses ORDER BY id
    """);
    List<Map<String, dynamic>> hskResult = [];
    for (final row in hsk) {
      hskResult.add(row["courses"]!);
    }
    List<Map<String, Map<String, dynamic>>> sentences = await pgdb.mappedResultsQuery("""
      SELECT * FROM sentences ORDER BY id
    """);
    List<Map<String, dynamic>> sentencesResult = [];
    for (final row in sentences) {
      sentencesResult.add(row["sentences"]!);
    }

    List<Map<String, Map<String, dynamic>>> units = await pgdb.mappedResultsQuery("""
      SELECT * FROM units ORDER BY unit_id
    """);
    List<Map<String, dynamic>> unitsResult = [];
    for (final row in units) {
      unitsResult.add(row["units"]!);
    }

    List<Map<String, Map<String, dynamic>>> subUnits = await pgdb.mappedResultsQuery("""
      select unit, subunit, 0 as completed from courses
      where unit is not null and subunit is not null
      group by unit, subunit
      order by unit, subunit
    """);
    List<Map<String, dynamic>> subUnitsResult = [];
    for (final row in subUnits) {
      subUnitsResult.add(row["courses"]!);
    }


    final db = await SQLHelper.db();
    Batch hskBatch = db.batch();
    db.execute("delete from courses");
    for (final row in hskResult) {
      hskBatch.insert('courses', row);
    }
    hskBatch.commit();

    Batch sentenceBatch = db.batch();
    db.execute("delete from sentences");
    for (final row in sentencesResult) {
      sentenceBatch.insert('sentences', row);
    }
    sentenceBatch.commit();

    Batch unitBatch = db.batch();
    db.execute("delete from units");
    for (final row in unitsResult) {
      unitBatch.insert('units', row);
    }
    unitBatch.commit();

    Batch subUnitBatch = db.batch();
    db.execute("delete from subunits");
    for (final row in subUnitsResult) {
      subUnitBatch.insert('subUnits', row);
    }
    subUnitBatch.commit();

    return true;
  }

  static Future<bool> updateSqliteFromCsv() async{

    final db = await SQLHelper.db();

    const String coursesUrl = 'https://cdn.jsdelivr.net/gh/wuxialearn/data@main/courses.tsv';
    final coursesReq = await http.get(Uri.parse(coursesUrl));
    final coursesResult = tsvParse(coursesReq.body);

    const String sentencesUrl = 'https://cdn.jsdelivr.net/gh/wuxialearn/data@main/sentences.tsv';
    final sentencesReq = await http.get(Uri.parse(sentencesUrl));
    final sentencesResult = tsvParse(sentencesReq.body);

    const String unitsUrl = 'https://cdn.jsdelivr.net/gh/wuxialearn/data@main/units.tsv';
    final unitsReq = await http.get(Uri.parse(unitsUrl));
    final unitsResult = tsvParse(unitsReq.body);

    const String subUnitsUrl = 'https://cdn.jsdelivr.net/gh/wuxialearn/data@main/subunits.tsv';
    final subUnitsReq = await http.get(Uri.parse(subUnitsUrl));
    final subUnitsResult = tsvParse(subUnitsReq.body);

    Batch csvBatch = db.batch();
    csvBatch.execute("delete from courses");
    for (final row in coursesResult.$1) {
      csvBatch.insert('courses', row);
    }
    csvBatch.execute("delete from sentences");
    for (final row in sentencesResult.$1) {
      csvBatch.insert('sentences', row);
    }
    csvBatch.execute("delete from units");
    for (final row in unitsResult.$1) {
      csvBatch.insert('units', row);
    }
    csvBatch.execute("delete from subunits");
    for (final row in subUnitsResult.$1) {
      csvBatch.insert('subUnits', row);
    }
    csvBatch.commit();

    print("update from tsv completed");
    return true;
  }


}