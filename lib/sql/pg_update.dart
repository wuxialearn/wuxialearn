import 'package:hsk_learner/sql/sql_helper.dart';
import 'package:postgres/postgres.dart';
import 'package:sqflite/sqflite.dart';

import 'connection_db_info.dart';

class PgUpdate {
  static late PostgreSQLConnection connection;
  static bool connected = false;
  static Future<PostgreSQLConnection> psql() async {
    if (connected == false || connection.isClosed) {
      // will be added back later
      ConnectionInfo connectionInfo = ConnectionInfo();
      connection = PostgreSQLConnection(
          connectionInfo.host, connectionInfo.port, connectionInfo.databaseName,
          username: connectionInfo.username,
          password: connectionInfo.password,
          useSSL: connectionInfo.useSSL);
      await connection.open();
      connected = true;
    }
    return connection;
  }

  static Future<bool> updateSqliteFromPg() async {
    final pgdb = await psql();
    List<Map<String, Map<String, dynamic>>> hsk =
        await pgdb.mappedResultsQuery("""
      SELECT * FROM courses ORDER BY id
    """);
    List<Map<String, dynamic>> hskResult = [];
    for (final row in hsk) {
      hskResult.add(row["courses"]!);
    }
    List<Map<String, Map<String, dynamic>>> sentences =
        await pgdb.mappedResultsQuery("""
      SELECT * FROM sentences ORDER BY id
    """);
    List<Map<String, dynamic>> sentencesResult = [];
    for (final row in sentences) {
      sentencesResult.add(row["sentences"]!);
    }

    List<Map<String, Map<String, dynamic>>> units =
        await pgdb.mappedResultsQuery("""
      SELECT * FROM units ORDER BY unit_id
    """);
    List<Map<String, dynamic>> unitsResult = [];
    for (final row in units) {
      unitsResult.add(row["units"]!);
    }

    List<Map<String, Map<String, dynamic>>> subUnits =
        await pgdb.mappedResultsQuery("""
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
}
