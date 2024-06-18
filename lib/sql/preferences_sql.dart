import 'package:hsk_learner/sql/sql_helper.dart';

class PreferencesSql{
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

  static Future<List<Map<String, dynamic>>> getPreferences() async {
    final db = await SQLHelper.db();
    return db.rawQuery("SELECT * FROM preferences; ");

  }
}