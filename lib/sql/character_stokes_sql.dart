import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:hsk_learner/sql/sql_helper.dart';
import 'package:hsk_learner/utils/platform_info.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:typed_data';


void main(List<String> args) {
  //useful for testing
  if (PlatformInfo.isDesktop()) {
    // Initialize FFI
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  WidgetsFlutterBinding.ensureInitialized();
  if(1==2){
    CharacterStokesSql.createTable();
  }else{
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
    final List<List<dynamic>> csvTable =
        const CsvToListConverter().convert(dictionaryResponse.body);

    final graphicsResponse = await http.get(Uri.parse(graphicsUrl));
    if (graphicsResponse.statusCode != 200) {
      throw Exception('Failed to load graphics CSV');
    }
    final Uint8List archive = BZip2Decoder().decodeBytes(graphicsResponse.bodyBytes);
    final graphicsCsvString = utf8.decode(archive);

    final List<List<
    dynamic>> graphicsTable =
        const CsvToListConverter().convert(graphicsCsvString);

    await db.transaction((txn) async {
      final batch = txn.batch();
      // Delete the table if it already exists
      batch.execute('DROP TABLE IF EXISTS stroke_info');
      // Create table named strokes with all the columns from both files
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
      // Insert all the data from the dictionary.csv file into the table
      for (int i = 1; i < csvTable.length; i++) {
        batch.rawInsert('''
        INSERT INTO stroke_info(character, decomposition, etymology, radical, matches)
        VALUES(?, ?, ?, ?, ?)
        ''', csvTable[i]);
      }
      // Update the strokes and medians columns with the data from the graphics.csv file
      for (int i = 1; i < graphicsTable.length; i++) {
        batch.rawUpdate('''
        UPDATE stroke_info
        SET strokes = ?, medians = ?
        WHERE character = ?
        ''', [graphicsTable[i][1], graphicsTable[i][2], graphicsTable[i][0]]);
      }
      await batch.commit();
      print(await txn.rawQuery('SELECT * FROM stroke_info limit 1'));
    });
    await db.close();
  }
  static Future<void> dropTable() async {
    final db = await SQLHelper.db();
    await db.execute('DROP TABLE IF EXISTS stroke_info');
    await db.close();
  }
}