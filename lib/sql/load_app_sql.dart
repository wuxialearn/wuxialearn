import 'package:d4_dsv/d4_dsv.dart';
import 'package:hsk_learner/sql/sql_helper.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

class LoadAppSql {
  static Future<bool> updateSqliteFromCsv() async {
    final db = await SQLHelper.db();

    const String coursesUrl =
        'https://cdn.jsdelivr.net/gh/wuxialearn/data@main/courses.tsv';
    final coursesReq = await http.get(Uri.parse(coursesUrl));
    final coursesResult = tsvParse(coursesReq.body);

    const String sentencesUrl =
        'https://cdn.jsdelivr.net/gh/wuxialearn/data@main/sentences.tsv';
    final sentencesReq = await http.get(Uri.parse(sentencesUrl));
    final sentencesResult = tsvParse(sentencesReq.body);

    const String unitsUrl =
        'https://cdn.jsdelivr.net/gh/wuxialearn/data@main/units.tsv';
    final unitsReq = await http.get(Uri.parse(unitsUrl));
    final unitsResult = tsvParse(unitsReq.body);

    const String subUnitsUrl =
        'https://cdn.jsdelivr.net/gh/wuxialearn/data@main/subunits.tsv';
    final subUnitsReq = await http.get(Uri.parse(subUnitsUrl));
    final subUnitsResult = tsvParse(subUnitsReq.body);
    await db.transaction((txn) async {
      Batch csvBatch = txn.batch();
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
    });
    print("update from tsv completed");
    return true;
  }
}
