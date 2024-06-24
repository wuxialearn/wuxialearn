import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:sqflite/sqflite.dart' as sql;
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../utils/platform_info.dart';

class SQLHelper {
  static Future<sql.Database> db() async {
    if (PlatformInfo.isWeb()){
      var factory = databaseFactoryFfiWeb;
      var exists = await factory.databaseExists("demo_asset_example.db");
      if(!exists){
        final data = await rootBundle.load(url.join('assets', 'example.db'));
        final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await factory.writeDatabaseBytes("demo_asset_example.db", bytes);
      }
      return factory.openDatabase('demo_asset_example.db');
    }
    final String path = await getDbPath();
    final bool exists = await sql.databaseExists(path);
    if (!exists) {
      await loadDbFromFile(path);
    }
    return sql.openDatabase(path);
  }
  static Future<String> getDbPath() async {
    if (PlatformInfo.isDesktop()) {
      final databasesPath = (await path_provider.getApplicationSupportDirectory()).path;
      return  join(databasesPath, "demo_asset_example.db");
    }else{
      final databasesPath = await sql.getDatabasesPath();
      return join(databasesPath, "demo_asset_example.db");
    }
  }
  static Future<bool> loadDbFromFile(String path) async{
    try {
      await Directory(dirname(path)).create(recursive: true);
    } catch (_) {}
    // Copy from asset
    ByteData data = await rootBundle.load("assets/example.db");
    List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    // Write and flush the bytes written
    await File(path).writeAsBytes(bytes, flush: true);
    return true;
  }

  static Future<bool> tableExists(String table, DatabaseExecutor db) async{
    final exists = await db.rawQuery("""
        SELECT count(*) as exist FROM sqlite_master WHERE type='table' AND name='review_rating'
      """);
    return exists[0]["exist"] == 0;
  }
}