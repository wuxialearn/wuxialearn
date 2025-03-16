//import 'dart:js_interop';

import 'package:hsk_learner/sql/sql_helper.dart';
import 'package:postgres/postgres.dart';
import 'package:sqflite/sqflite.dart';
import 'connection_db_info.dart' as ci;
typedef  PostgreSQLConnection = Connection;

class PgUpdate {
  static late PostgreSQLConnection connection;
  static bool connected = false;
  static Future<PostgreSQLConnection> psql() async {

    if (connected == false) {

      ci.ConnectionInfo connectionInfo = ci.ConnectionInfo();

      // This line was failing as the PostgreSQLConnection type did not exist. I found that Connection seems to be a generic replacement.
      //connection = PostgreSQLConnection(
      connection = await PostgreSQLConnection.open(Endpoint(
          host: connectionInfo.host,
          port: connectionInfo.port,
          database: connectionInfo.databaseName,
          username: connectionInfo.username,
          password: connectionInfo.password), settings: ConnectionSettings(sslMode: connectionInfo.useSSL ? SslMode.require : SslMode.disable));
      connected = true;
    }
    return connection;
  }

  // This seemed to be missing from the the newer versions
  static Map<String, Map<String, dynamic>> toTableColumnMap(r, x) {
    final rowMap = <String, Map<String, dynamic>>{};
    x.tableNames.forEach((tableName) {
      rowMap[tableName] = <String, dynamic>{};
    });
    for (var i = 0; i < x.columnDescriptions.length; i++) {
      final col = x.columnDescriptions[i];
      rowMap[col.tableName]?[col.columnName] = r[i];
    }
    return rowMap;
  }

  // Added this back in so it could be easily used.
  static Future<List<Map<String, Map<String, dynamic>>>> mappedResultsQuery(String fmtString) async {
    final rs = await connection.execute(Sql.named(fmtString));
    return rs.map((row) => toTableColumnMap(row, rs)).toList();
  }


  static Future<bool> updateSqliteFromPg() async {
    List<Map<String, Map<String, dynamic>>> hsk =
        (await mappedResultsQuery("""
      SELECT * FROM courses ORDER BY id
    """));
    List<Map<String, dynamic>> hskResult = [];
    for (final row in hsk) {
      hskResult.add(row["courses"]!);
    }
    List<Map<String, Map<String, dynamic>>> sentences =
        await mappedResultsQuery("""
      SELECT * FROM sentences ORDER BY id
    """);
    List<Map<String, dynamic>> sentencesResult = [];
    for (final row in sentences) {
      sentencesResult.add(row["sentences"]!);
    }

    List<Map<String, Map<String, dynamic>>> units =
        await mappedResultsQuery("""
      SELECT * FROM units ORDER BY unit_id
    """);
    List<Map<String, dynamic>> unitsResult = [];
    for (final row in units) {
      unitsResult.add(row["units"]!);
    }

    List<Map<String, Map<String, dynamic>>> subUnits =
        await mappedResultsQuery("""
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
