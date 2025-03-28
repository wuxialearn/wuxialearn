import 'dart:convert';
import 'dart:io';

import 'package:d4_dsv/d4_dsv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:hsk_learner/screens/settings/preferences.dart';
import 'package:hsk_learner/utils/platform_info.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tar/tar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../sql/preferences_sql.dart';
import '../../sql/sql_helper.dart';

final class Backup {
  static const int backupFileFormatVersion = 1;

  static const String backupFileFormatVersionName =
      "backup_file_format_version.txt";
  static const String subUnitName = "subunit_info.csv";
  static const String unitName = "unit_info.csv";
  static const String statsName = "stats.csv";
  static const String reviewName = "review.csv";
  static const String reviewRatingName = "review_rating.csv";
  static const String preferencesName = "preferences.csv";

  static final subUnitInfo = _BackupItem(
    name: subUnitName,
    source: _getSubunitInfo,
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
  static final review = _BackupItem(
    name: reviewName,
    source: _getReview,
    tableName: 'review',
  );
  static final reviewRating = _BackupItem(
    name: reviewRatingName,
    source: _getReviewRating,
    tableName: 'review_rating',
  );
  static final preferences = _BackupItem(
    name: preferencesName,
    source: _getPreferences,
    tableName: 'preferences',
  );

  static final backupItems = [
    subUnitInfo,
    unitInfo,
    stats,
    review,
    reviewRating,
    preferences,
  ];

  static Future<bool> startBackupWithFileSelection() async {
    if (kIsWeb) {
      return Future.value(false);
    }
    final DateTime now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd-HHmmss');
    final String date = formatter.format(now);
    final String backupFileName = 'wuxialearn-backup-$date.tar.gz';
    if (PlatformInfo.isDesktop()) {
      late File file;
      String? path;
      try {
        path = await FilePicker.platform.getDirectoryPath();
      } catch (e) {
        print(e);
      }

      if (path != null) {
        file = File(join(path, backupFileName));
      } else {
        return false;
      }
      return await createBackup(file: file);
    }

    final Directory tempDir = await getTemporaryDirectory();
    final file = File(join(tempDir.path, 'wuxialearn-backup.tar.gz'));
    final isBackupStored = await createBackup(file: file);
    if (!isBackupStored) {
      return false;
    }
    final save = await FlutterFileDialog.saveFile(
      params: SaveFileDialogParams(
        sourceFilePath: file.path,
        fileName: backupFileName,
      ),
    );
    file.delete();
    return save != null;
  }

  static Future<bool> createBackup({required File file}) async {
    late final IOSink output;
    try {
      output = file.openWrite();
    } catch (e) {
      print(e);
      return false;
    }

    var entries = [
      TarEntry.data(
        TarHeader(
          name: backupFileFormatVersionName,
          mode: int.parse('644', radix: 8),
        ),
        utf8.encode(backupFileFormatVersion.toString()),
      ),
    ];
    entries.addAll(
      await Future.wait(
        backupItems.map((item) async {
          final bytes = utf8.encode(csvFormat(await item.source()));
          return TarEntry.data(
            TarHeader(name: item.name, mode: int.parse('644', radix: 8)),
            bytes,
          );
        }),
      ),
    );

    final tarEntries = Stream<TarEntry>.fromIterable(entries);

    try {
      await tarEntries.pipe(tarWritingSink(output));
    } catch (e) {
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
    try {
      await TarReader.forEach(file.openRead(), (entry) async {
        try {
          final contents = await entry.contents.transform(utf8.decoder).join();
          switch (entry.header.name) {
            case backupFileFormatVersionName:
              break;
            case subUnitName:
              subUnitInfo.content = contents;
            case unitName:
              unitInfo.content = contents;
            case statsName:
              stats.content = contents;
            case reviewName:
              review.content = contents;
            case reviewRatingName:
              reviewRating.content = contents;
            case preferencesName:
              preferences.content = contents;
          }
        } catch (e) {
          print('Error processing entry ${entry.header.name}: $e');
        }
      });
    } catch (e) {
      print('Error reading tar file: $e');
      return false;
    }

    final complete = backupItems.every((element) => element.content != null);
    if (complete) {
      final db = await SQLHelper.db();
      await db.transaction((txn) async {
        for (final item in backupItems) {
          txn.rawDelete("delete from ${item.tableName}");
        }

        final batch = txn.batch();
        for (final item in backupItems) {
          //this should work too
          //final table2 = csvParseWith<Map<String, dynamic>>((item.content!), (d, _, __) => autoType(d)).$1;
          final table = csvParse(item.content!).$1;
          for (final row in table) {
            final entry = row.map(
              (key, value) => MapEntry(key, value.isEmpty ? null : value),
            );
            batch.insert(item.tableName, entry);
          }
        }
        batch.commit(noResult: true);
      });
    } else {
      return false;
    }
    Preferences.initPreferences();
    return true;
  }

  static Future<bool> startBackupFromTempDir() async {
    final Directory tempDir = await getTemporaryDirectory();
    final file = File(join(tempDir.path, 'wuxialearn-backup.tar.gz'));
    final isBackupStored = await createBackup(file: file);
    if (!isBackupStored) {
      return false;
    }
    final path = await SQLHelper.getDbPath();
    await SQLHelper.loadDbFromFile(path);
    final isBackupRestored = await restoreBackup(file);
    await file.delete();
    if (!isBackupRestored) {
      return false;
    }
    final latestVersion = Preferences.getPreference(
      "latest_db_version_constant",
    );
    Preferences.setPreference(name: "db_version", value: latestVersion);
    PreferencesSql.setPreference(
      name: "db_version",
      value: latestVersion,
      type: "string",
    );
    final currVersion = Preferences.getPreference("db_version");
    print(latestVersion);
    print(currVersion);
    print(latestVersion == currVersion);
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
      select id, deck, show_next, rating_id from review
    """);
  }

  static Future<List<Map<String, dynamic>>> _getReviewRating() async {
    final db = await SQLHelper.db();
    return db.rawQuery("""
      select rating_id, rating_name, rating_duration_start, rating_duration_end,
      rating_options from review_rating
    """);
  }

  static Future<List<Map<String, dynamic>>> _getPreferences() async {
    final db = await SQLHelper.db();
    return db.rawQuery("""
      select name, value, type from preferences
    """);
  }
}

final class _BackupItem {
  final String name;
  final Function source;
  final String tableName;
  String? content;
  _BackupItem({
    required this.name,
    required this.source,
    required this.tableName,
  });
}
