import 'package:hsk_learner/sql/sql_helper.dart';

class CharacterViewSql {
  static Future<List<Map<String, dynamic>>> getSentenceFromId(
      String char) async {
    final db = await SQLHelper.db();
    final a = db.rawQuery("""
    SELECT * from sentences where characters like '%$char%'
    order by unit asc
    """);
    //print(await a);
    return a;
  }

  static Future<List<Map<String, dynamic>>> getCharInfo(String char) async {
    final db = await SQLHelper.db();
    print("we are hjere");
    final a = db.rawQuery("""
     SELECT
     id, hanzi, pinyin, translation
     from unihan
     where hanzi = '$char'
     limit 1
    """);
    print(await a);
    return a;
  }
}
