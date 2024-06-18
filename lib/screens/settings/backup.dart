import 'dart:convert';
import 'dart:io';

import 'package:d4_dsv/d4_dsv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tar/tar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../sql/sql_helper.dart';

final class Backup{
  static const String subUnitName = "subunit_info.csv";
  static const String unitName = "unit_info.csv";
  static const String statsName = "stats.csv";
  static const String reviewName = "review.csv";

  static final subUnitInfo = _BackupItem(
    name: subUnitName,
    source:  _getSubunitInfo,
    tableName: 'subunit_info',
  );
  static final unitInfo = _BackupItem(
    name: unitName,
    source: _getUnitInfo,
    tableName: 'unit_info',
  );
  static final stats = _BackupItem(
    name: statsName,
    source: _getStats,
    tableName: 'stats',
  );
  static final review  = _BackupItem(
    name: reviewName,
    source: _getReview,
    tableName: 'review',
  );

  static final backupItems = [
    subUnitInfo,
    unitInfo,
    stats,
    review,
  ];

  static Future<bool> startBackupWithFileSelection() async {
    if (kIsWeb){
      return Future.value(false);
    }
    late File file;
    String? path;
    try{
      path = await FilePicker.platform.getDirectoryPath();
    }catch(e){
      print(e);
    }

    if (path != null) {
      file = File(join(path, 'wuxialearn-backup.tar.gz'));
    } else {
      return false;
    }
    return await createBackup(file: file);
  }


  static Future<bool> createBackup({required File file}) async{
    late final IOSink output;
    try {
      output = file.openWrite();
    }catch(e){
      print(e);
      return false;
    }

    final entries = await Future.wait(backupItems.map((item) async {
      final bytes = utf8.encode(csvFormat(await item.source()));
      return TarEntry.data(
          TarHeader(
            name: item.name,
            mode: int.parse('644', radix: 8),
          ),
          bytes);
    }));

    final tarEntries = Stream<TarEntry>.fromIterable(entries);

    try {
      await tarEntries.pipe(tarWritingSink(output));
    }catch(e){
      print(e);
      return false;
    }
    return true;
  }

  static Future<bool> restoreBackupFromUserFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    late File file;
    if (result != null) {
      file = File(result.files.single.path!);
    } else {
      return false;
    }

    return restoreBackup(file);
  }

  static Future<bool> restoreBackup(File file) async {

    await TarReader.forEach(file.openRead(), (entry) async {
      final contents = await entry.contents.transform(utf8.decoder).first;
      switch(entry.header.name){
        case subUnitName: subUnitInfo.content = contents;
        case unitName: unitInfo.content = contents;
        case statsName: stats.content = contents;
        case reviewName: review.content = contents;
      }
    });

    final complete = backupItems.every((element) => element.content != null);
    if(complete){

      final db = await SQLHelper.db();
      await db.transaction((txn) async {

        txn.rawDelete("delete from subunit_info");
        txn.rawDelete("delete from unit_info");
        txn.rawDelete("delete from stats");
        txn.rawDelete("delete from review");

        final batch = txn.batch();
        for (final item in backupItems){
          final table = csvParse(item.content!).$1;
          for (final row in table){
            batch.insert(item.tableName, row);
          }
        }
        batch.commit(noResult: true);
      });
    }else{
      return false;
    }
    return true;
  }

  static Future<bool> startBackupFromTempDir() async {
    final Directory tempDir = await getTemporaryDirectory();
    final file = File(join(tempDir.path, 'wuxialearn-backup.tar.gz'));
    final isBackupStored = await createBackup(file: file);
    if(!isBackupStored){
      return false;
    }
    final path = await SQLHelper.getDbPath();
    await SQLHelper.loadDbFromFile(path);
    final isBackupRestored = await restoreBackup(file);
    if(!isBackupRestored){
      return false;
    }
    await file.delete();
    return true;
  }

  static Future<List<Map<String, dynamic>>> _getSubunitInfo() async {
    final db = await SQLHelper.db();
    return db.rawQuery("""
      select subunit_id, completed from subunit_info
    """);
  }
  static Future<List<Map<String, dynamic>>> _getUnitInfo() async {
    final db = await SQLHelper.db();
    return db.rawQuery("""
      select unit_id, completed from unit_info
    """);
  }
  static Future<List<Map<String, dynamic>>> _getStats() async {
    final db = await SQLHelper.db();
    return db.rawQuery("""
      select wordid, date, value from stats
    """);
  }
  static Future<List<Map<String, dynamic>>> _getReview() async {
    final db = await SQLHelper.db();
    return db.rawQuery("""
      select id, deck, show_next from review
    """);
  }
}

final class _BackupItem{
  final String name;
  final Function source;
  final String tableName;
  String? content;
  _BackupItem({required this.name, required this.source, required this.tableName,});
}