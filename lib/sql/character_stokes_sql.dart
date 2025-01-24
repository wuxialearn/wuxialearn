import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:hsk_learner/sql/sql_helper.dart';
import 'package:hsk_learner/utils/platform_info.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main(List<String> args) {
    if (PlatformInfo.isDesktop()) {
    // Initialize FFI
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  WidgetsFlutterBinding.ensureInitialized();
  CharacterStokesSql.createTable();
}

class CharacterStokesSql {
  static void createTable() async{
    final db = await SQLHelper.db();
    //character,decomposition,etymology,radical,matches
    final csvFile = await rootBundle.loadString('assets/dictionary.csv');
    //character,strokes,medians
    final graphicsCsv = await rootBundle.loadString('assets/graphics.csv');
    final List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvFile);
    final List<List<dynamic>> graphicsTable = const CsvToListConverter().convert(graphicsCsv);
    //print the first row of the csv file
    print(graphicsTable[1]);
    //return;
    await db.transaction((txn) async {
      final batch = txn.batch();
      //delete the table if it already exists
      batch.execute('DROP TABLE IF EXISTS strokes');
      batch.execute('DROP TABLE IF EXISTS stroke_info');
      //create table named strokes with all the columns from both file
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
      //insert all the data from the dictioanry.csv file into the table
      for (int i = 1; i < csvTable.length; i++) {
        batch.rawInsert('''
        INSERT INTO stroke_info(character, decomposition, etymology, radical, matches)
        VALUES(?, ?, ?, ?, ?)
        ''', csvTable[i]);
      }
      //update the strokes and medians columns with the data from the graphics.csv file
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
    await db.close(); // Ensure the database is closed after the transaction
  }
}