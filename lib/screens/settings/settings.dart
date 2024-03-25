import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'preferences.dart';
import 'package:hsk_learner/sql/sql_helper.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool translation = Preferences.getPreference("showTranslations");
  bool debug  = Preferences.getPreference("debug");
  bool allowSkipUnits = Preferences.getPreference("allow_skip_units");
  bool showExampleSentences = Preferences.getPreference("show_sentences");
  List<String> courses = Preferences.getPreference("courses");
  String defaultCourse = Preferences.getPreference("default_course");
  String version = '1.0.11';
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
                  const Text("Default course"),
                  CupertinoButton(onPressed: (){ _showActionSheet(context);}, child: Text(defaultCourse), ),
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