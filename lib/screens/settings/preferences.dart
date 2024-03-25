import 'dart:convert';

class Preferences{
  static Map<String, dynamic>  preferences =  {};
  static getPreference(String preference){
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
      switch (newPreferences[i]["type"]){
        case "bool":
          bool newValue = (newPreferences[i]["value"] == "1");
          preferences[name] = newValue;
        case 'json' :
          preferences[name] = jsonDecode(newPreferences[i]["value"]).cast<String>();
        case 'string' :
          preferences[name] = newPreferences[i]["value"].toString();
      }
    }
  }
}