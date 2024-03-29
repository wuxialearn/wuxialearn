import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hsk_learner/screens/home/home_page.dart';
import 'package:hsk_learner/sql/sql_helper.dart';
import '../settings/preferences.dart';
import 'package:http/http.dart' as http;

class LoadApp extends StatefulWidget {
  const LoadApp({Key? key}) : super(key: key);

  @override
  State<LoadApp> createState() => _LoadAppState();
}

class _LoadAppState extends State<LoadApp> {
  bool isLoading = true;
  @override
  void initState() {
    getPreferences();
    super.initState();
  }
  void getPreferences() async {
    final data = await SQLHelper.getPreferences();
    Preferences.setPreferences(data);
    checkForDbUpdate();
    setState(() {
      isLoading = false;
    });
  }
  @override
  Widget build(BuildContext context) {
    return isLoading? const Loading(): const MyHomePage(tab: 0);
  }

  void checkForDbUpdate() async {
      const String dbPref = 'db_version';
      final prefs = Preferences.getAllPreferences();
      print(prefs);
      final String lastVersion = Preferences.getPreference(dbPref);
      print(lastVersion);
      const String versionUrl = 'https://cdn.jsdelivr.net/gh/wuxialearn/data@main/version';
      final req = await http.get(Uri.parse(versionUrl));
      final String version = req.body.trim();
      print("version: $version");
      if(version != lastVersion){
        await SQLHelper.updateSqliteFromCsv();
        Preferences.setPreference(name: dbPref, value: version);
        SQLHelper.setPreference(name: dbPref, value: version, type: 'string');
        //todo: when we implement real state management we should update the courses screen here
        setState(() {

        });
      }
  }
}

class Loading extends StatelessWidget {
  const Loading({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      child: SizedBox(height: 10,),
    );
  }
}