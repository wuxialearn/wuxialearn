import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:hsk_learner/sql/sql_helper.dart';

class Preferences{
  static late final dynamic data;
  static Map<String, dynamic>  preferences =  {};
  static getPreference(String preference) {
    if (!preferences.containsKey(preference)){
      setPreferenceFromJson(preference);
    }
    return preferences[preference];
  }
  static getAllPreferences(){
    return preferences;
  }
  static setPreference({required String name, required dynamic value}){
    preferences[name] = value;
  }
  static setPreferences(List<Map<String, dynamic>> newPreferences){
    for(int i = 0; i< newPreferences.length; i++){
      String name = newPreferences[i]["name"];
      String type = newPreferences[i]["type"];
      String value = newPreferences[i]["value"];
      insertPref(name: name, value: value, type: type);
    }
  }

  static insertPref({required String name, required String value, required String type}){
    switch (type){
      case "bool":
        bool newValue = (value == "1");
        preferences[name] = newValue;
      case 'json' :
        preferences[name] = jsonDecode(value).cast<String>();
      case 'string' :
        preferences[name] = value.toString();
    }
  }

  static setPreferenceFromJson(String preference)  {
    print("setPreferenceFromJson");
    print(data);
    final pref = data[preference];
    print(pref);
    SQLHelper.insertPreference(name: preference, value: pref["value"], type: pref["type"]);
    insertPref(name: preference, value: pref["value"], type: pref["type"]);
  }

  static Future<void>  loadDefaultPreferences() async {
    final String response = await rootBundle.loadString('assets/default_prefs.json');
    data = await json.decode(response);
  }
}