import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'backup.dart';
import 'preferences.dart';
import 'package:hsk_learner/sql/sql_helper.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool translation = Preferences.getPreference("showTranslations");
  bool reviewPinyin =  Preferences.getPreference("show_pinyin_by_default_in_review");
  bool checkVersionOnStart = Preferences.getPreference("check_for_new_version_on_start");
  bool debug  = Preferences.getPreference("debug");
  bool allowSkipUnits = Preferences.getPreference("allow_skip_units");
  bool showExampleSentences = Preferences.getPreference("show_sentences");
  bool allowAutoComplete =  Preferences.getPreference("allow_auto_complete_unit");
  bool showLiteralInUnitLearn = Preferences.getPreference("show_literal_meaning_in_unit_learn");
  List<String> courses = Preferences.getPreference("courses");
  String defaultCourse = Preferences.getPreference("default_course");
  String version = '1.0.13';
  int clicks = 0;
  bool showDebugOptions = false;
  @override
  void initState() {
    super.initState();
  }
  setSettingBool({required String name, required String type, required bool value}){
      String val = value == true? "1": "0";
      SQLHelper.setPreference(name: name, value: val, type: type);
      Preferences.setPreference(name: name, value: value);
  }

  setSettingString({required String name, required String type, required String value}){
    SQLHelper.setPreference(name: name, value: value, type: type);
    Preferences.setPreference(name: name, value: value);
  }

  _showActionSheet<bool>(BuildContext context) {
    showCupertinoModalPopup<bool>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        //title: const Text('Courses'),
        title: const Text('Select a default course'),
        actions:
        List<CupertinoActionSheetAction>.generate(courses.length,(index){
          return CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () {
              setSettingString(name: 'default_course', type: 'string', value: courses[index]);
              Navigator.pop(context, true);
              setState(() {
                defaultCourse = Preferences.getPreference("default_course");
              });
            },
            child: Text(courses[index]),
          );
        }),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text("Settings"),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 20,),
              const Text("Review"),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Show translations in preview"),
                  CupertinoSwitch(
                    // This bool value toggles the switch.
                    value: translation,
                    activeColor: CupertinoColors.activeBlue,
                    onChanged: (bool value) {
                      setSettingBool(name: "showTranslations", type: "bool", value: value);
                      setState(() => translation = value);
                    },
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Show pinyin by default"),
                  CupertinoSwitch(
                    // This bool value toggles the switch.
                    value: reviewPinyin,
                    activeColor: CupertinoColors.activeBlue,
                    onChanged: (bool value) {
                      setSettingBool(name: "show_pinyin_by_default_in_review", type: "bool", value: value);
                      setState(() => reviewPinyin = value);
                    },
                  ),
                ],
              ),
              const Text("Learn"),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Show example sentences in unit learn"),
                  CupertinoSwitch(
                    // This bool value toggles the switch.
                    value: showExampleSentences,
                    activeColor: CupertinoColors.activeBlue,
                    onChanged: (bool value) {
                      setSettingBool(name: "show_sentences", type: "bool", value: value);
                      setState(() => showExampleSentences = value);
                    },
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Show literal meaning in unit learn"),
                  CupertinoSwitch(
                    // This bool value toggles the switch.
                    value: showLiteralInUnitLearn,
                    activeColor: CupertinoColors.activeBlue,
                    onChanged: (bool value) {
                      setSettingBool(name: "show_literal_meaning_in_unit_learn", type: "bool", value: value);
                      setState(() => showLiteralInUnitLearn = value);
                    },
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Default course"),
                  CupertinoButton(onPressed: (){ _showActionSheet(context);}, child: Text(defaultCourse), ),
                ],
              ),
              Row(
                children: [
                  const Text("Backup data"),
                  IconButton(
                      onPressed: () async {
                        Future<bool> updated =  Backup.startBackupWithFileSelection();
                        updated.then((val) => showCupertinoDialog(
                            barrierDismissible: true,
                            context: context,
                            builder: (context) {
                              late final String text;
                              val == true? text = "backup succeeded"
                              : text = "backup failed  (folder my be protected)";
                              return CupertinoAlertDialog(
                                content: Text(text),
                              );
                            }
                        ),
                          onError:(e) => showCupertinoDialog(
                              barrierDismissible: true,
                              context: context,
                              builder: (context) {
                                return const CupertinoAlertDialog(
                                  content: Text("backup failed  (folder my be protected)"),
                                );
                              }
                          ),
                        );
                      },
                      icon: const Icon(Icons.add)
                  ),
                ],
              ),
              Row(
                children: [
                  const Text("restore from backup"),
                  IconButton(
                      onPressed: () async {
                        Future<bool> updated =  Backup.restoreFromBackup();
                        updated.then((val) => showCupertinoDialog(
                            barrierDismissible: true,
                            context: context,
                            builder: (context) {
                              late final String text;
                              val == true? text = "backup succeeded"
                                  : text = "backup failed (folder my be protected)";
                              return CupertinoAlertDialog(
                                content: Text(text),
                              );
                            }
                        ),
                          onError:(e) => showCupertinoDialog(
                              barrierDismissible: true,
                              context: context,
                              builder: (context) {
                                return const CupertinoAlertDialog(
                                  content: Text("backup failed  (folder my be protected)"),
                                );
                              }
                          ),
                        );
                      },
                      icon: const Icon(Icons.add)
                  ),
                ],
              ),
              GestureDetector(
                onTap: (){
                  clicks++;
                  if(clicks == 5){
                    setState(() {
                      showDebugOptions = true;
                    });
                  }
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Text("Version "),
                    Text(version)
                  ],
                ),
              ),
              const SizedBox(height: 10,),
              Visibility(
                visible: showDebugOptions,
                child: Column(
                  children: [
                    const Text("debug options"),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("debug mode"),
                        CupertinoSwitch(
                          // This bool value toggles the switch.
                          value: debug,
                          activeColor: CupertinoColors.activeBlue,
                          onChanged: (bool value) {
                            setSettingBool(name: "debug", type: "bool", value: value);
                            setState(()=> debug = value);
                          },
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("allow skip units"),
                        CupertinoSwitch(
                          // This bool value toggles the switch.
                          value: allowSkipUnits,
                          activeColor: CupertinoColors.activeBlue,
                          onChanged: (bool value) {
                            setSettingBool(name: "allow_skip_units", type: "bool", value: value);
                            setState(()=> allowSkipUnits = value);
                          },
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("check for new version on start"),
                        CupertinoSwitch(
                          // This bool value toggles the switch.
                          value: checkVersionOnStart,
                          activeColor: CupertinoColors.activeBlue,
                          onChanged: (bool value) {
                            setSettingBool(name: "check_for_new_version_on_start", type: "bool", value: value);
                            setState(() => checkVersionOnStart = value);
                          },
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("allow auto complete unit"),
                        CupertinoSwitch(
                          // This bool value toggles the switch.
                          value: allowAutoComplete,
                          activeColor: CupertinoColors.activeBlue,
                          onChanged: (bool value) {
                            setSettingBool(name: "allow_auto_complete_unit", type: "bool", value: value);
                            setState(() => allowAutoComplete = value);
                          },
                        ),
                      ],
                    ),
                    Visibility(
                      visible: false, //enable to fetch from db
                      child: Row(
                        children: [
                          const Text("Get latest data"),
                          IconButton(
                              onPressed: () async {
                                Future<bool> updated =  SQLHelper.updateSqliteFromPg();
                                updated.then((val) => showCupertinoDialog(
                                    barrierDismissible: true,
                                    context: context,
                                    builder: (context) {
                                      return const CupertinoAlertDialog(
                                        content: Text("updated: true"),
                                      );
                                    }
                                ),
                                  onError:(e) => showCupertinoDialog(
                                      barrierDismissible: true,
                                      context: context,
                                      builder: (context) {
                                        return const CupertinoAlertDialog(
                                          content: Text("updated: false"),
                                        );
                                      }
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add)
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10,),
            ],
          ),
        ),
      ),
    );
  }
}

// only for testing, can be deleted
Map<String, dynamic> currSentence(){
  //return  {"characters": "她叫什么名字", "pinyin": "tā jiào shénme míngzì", "meaning": "what's her name"};
  //return {"characters": "我的弟弟想长高", "pinyin": "Wǒ de dìdi xiǎng zhǎng gāo", "meaning": "my younger brother wants to grow taller",};
  return {
    "characters": "我爱我的国家，它有很多美丽的河流和公园",
    "pinyin": "wǒ ài wǒ de guójiā, tā yǒu hěnduō měilì de héliú hé gōngyuán",
    "meaning": "I love my country, it has many beautiful rivers and parks and more words"
  };
}

void sentenceGameCallBack(bool value, Map<String, dynamic> currSentence, bool buildEnglish){
}