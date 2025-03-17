import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:hsk_learner/sql/sql_helper.dart';
import 'package:hsk_learner/utils/platform_info.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart';

void main(List<String> args) {
  //useful for testing
  if (PlatformInfo.isDesktop()) {
    // Initialize FFI
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  WidgetsFlutterBinding.ensureInitialized();
  if (1 == 1) {
    CharacterStokesSql.createTable();
  } else {
    // testArchive();
  }
}

class CharacterStokesSql {
  static Future<void> createTable() async {
    final db = await SQLHelper.db();
    const dictionaryUrl =
        'https://cdn.jsdelivr.net/gh/wuxialearn/data@main/dictionary.csv';
    const graphicsUrl =
        'https://cdn.jsdelivr.net/gh/wuxialearn/data@main/graphics.csv.bz2';

    final dictionaryResponse = await http.get(Uri.parse(dictionaryUrl));
    if (dictionaryResponse.statusCode != 200) {
      throw Exception('Failed to load dictionary CSV');
    }
    final List<List<dynamic>> csvTable = const CsvToListConverter().convert(
      dictionaryResponse.body,
    );

    final graphicsResponse = await http.get(Uri.parse(graphicsUrl));
    if (graphicsResponse.statusCode != 200) {
      throw Exception('Failed to load graphics CSV');
    }
    final Uint8List archive = await compute(
      decodeBZip2,
      graphicsResponse.bodyBytes,
    );
    final graphicsCsvString = utf8.decode(archive);

    final List<List<dynamic>> graphicsTable = const CsvToListConverter()
        .convert(graphicsCsvString);

    await db.transaction((txn) async {
      final batch = txn.batch();
      batch.execute('DROP TABLE IF EXISTS stroke_info');
      batch.execute('''
      CREATE TABLE stroke_info(
        character TEXT PRIMARY KEY,
        strokes TEXT,
        medians TEXT,
        decomposition TEXT,
        etymology TEXT,
        radical TEXT,
        matches TEXT
      )
      ''');
      for (int i = 1; i < csvTable.length; i++) {
        batch.rawInsert('''
        INSERT INTO stroke_info(character, decomposition, etymology, radical, matches)
        VALUES(?, ?, ?, ?, ?)
        ''', csvTable[i]);
      }
      for (int i = 1; i < graphicsTable.length; i++) {
        batch.rawUpdate(
          '''
        UPDATE stroke_info
        SET strokes = ?, medians = ?
        WHERE character = ?
        ''',
          [graphicsTable[i][1], graphicsTable[i][2], graphicsTable[i][0]],
        );
      }
      await batch.commit();
    });
    await db.close();
  }

  static Uint8List decodeBZip2(Uint8List data) {
    return BZip2Decoder().decodeBytes(data);
  }

  static Future<void> dropTable() async {
    final db = await SQLHelper.db();
    await db.execute('DROP TABLE IF EXISTS stroke_info');
    await db.close();
  }
}
