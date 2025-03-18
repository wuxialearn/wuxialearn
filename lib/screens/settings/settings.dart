import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hsk_learner/sql/pg_update.dart';
import 'package:hsk_learner/sql/preferences_sql.dart';
import '../../sql/character_stokes_sql.dart';
import '../../utils/platform_info.dart';
import 'backup.dart';
import 'preferences.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:flutter/services.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool translation = Preferences.getPreference("showTranslations");
  bool reviewPinyin =
      Preferences.getPreference("show_pinyin_by_default_in_review");
  bool checkVersionOnStart =
      Preferences.getPreference("check_for_new_version_on_start");
  bool debug = Preferences.getPreference("debug");
  bool allowSkipUnits = Preferences.getPreference("allow_skip_units");
  bool showExampleSentences = Preferences.getPreference("show_sentences");
  bool allowAutoComplete =
      Preferences.getPreference("allow_auto_complete_unit");
  bool showLiteralInUnitLearn =
      Preferences.getPreference("show_literal_meaning_in_unit_learn");
  List<String> courses = Preferences.getPreference("courses");
  List<String> homePages = ["home", "review", "stats"];
  String defaultCourse = Preferences.getPreference("default_course");
  String defaultHomePage = Preferences.getPreference("default_home_page");
  String version = '1.0.13';
  int clicks = 0;
  bool showDebugOptions = false;
  bool isDownloading = false;
  bool isDeleting = false;
  bool isDataDownloaded =
      SharedPrefs.prefs.getBool('character_stroke_data_downloaded') ?? false;

  @override
  void initState() {
    super.initState();
  }

  setSettingBool(
      {required String name, required String type, required bool value}) {
    String val = value == true ? "1" : "0";
    PreferencesSql.setPreference(name: name, value: val, type: type);
    Preferences.setPreference(name: name, value: value);
  }

  setSettingString(
      {required String name, required String type, required String value}) {
    PreferencesSql.setPreference(name: name, value: value, type: type);
    Preferences.setPreference(name: name, value: value);
  }

  _showDefaultCourseActionSheet<bool>(BuildContext context) {
    showCupertinoModalPopup<bool>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        //title: const Text('Courses'),
        title: const Text('Select a default course'),
        actions:
            List<CupertinoActionSheetAction>.generate(courses.length, (index) {
          return CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () {
              setSettingString(
                  name: 'default_course',
                  type: 'string',
                  value: courses[index]);
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

  _showDefaultHomePageActionSheet<bool>(BuildContext context) {
    showCupertinoModalPopup<bool>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        //title: const Text('Courses'),
        title: const Text('Select a default home page'),
        actions: List<CupertinoActionSheetAction>.generate(homePages.length,
            (index) {
          return CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () {
              setSettingString(
                  name: 'default_home_page',
                  type: 'string',
                  value: homePages[index]);
              Navigator.pop(context, true);
              setState(() {
                defaultHomePage =
                    Preferences.getPreference("default_home_page");
              });
            },
            child: Text(homePages[index]),
          );
        }),
      ),
    );
  }

  _showThemeSelectionDialog(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Select Theme'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              SharedPrefs.prefs.setString('theme', 'light');
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Light'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              SharedPrefs.prefs.setString('theme', 'dark');
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Dark'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              SharedPrefs.prefs.setString('theme', 'system');
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('System'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  static const String backupFailedMessage =
      "backup failed  (Folder may be protected. Try using the documents directory)";
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text("Settings"),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: ListView(
            children: [
              const SizedBox(
                height: 20,
              ),
              Column(
                children: [
                  const Text("Review"),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Show translations in preview"),
                      CupertinoSwitch(
                        // This bool value toggles the switch.
                        value: translation,
                        activeTrackColor: CupertinoColors.activeBlue,
                        onChanged: (bool value) {
                          setSettingBool(
                              name: "showTranslations",
                              type: "bool",
                              value: value);
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
                        activeTrackColor: CupertinoColors.activeBlue,
                        onChanged: (bool value) {
                          setSettingBool(
                              name: "show_pinyin_by_default_in_review",
                              type: "bool",
                              value: value);
                          setState(() => reviewPinyin = value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                children: [
                  const Text("Learn"),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Show example sentences in unit learn"),
                      CupertinoSwitch(
                        // This bool value toggles the switch.
                        value: showExampleSentences,
                        activeTrackColor: CupertinoColors.activeBlue,
                        onChanged: (bool value) {
                          setSettingBool(
                              name: "show_sentences",
                              type: "bool",
                              value: value);
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
                        activeTrackColor: CupertinoColors.activeBlue,
                        onChanged: (bool value) {
                          setSettingBool(
                              name: "show_literal_meaning_in_unit_learn",
                              type: "bool",
                              value: value);
                          setState(() => showLiteralInUnitLearn = value);
                        },
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Default course"),
                      CupertinoButton(
                        onPressed: () {
                          _showDefaultCourseActionSheet(context);
                        },
                        child: Text(defaultCourse),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Default home page"),
                      CupertinoButton(
                        onPressed: () {
                          _showDefaultHomePageActionSheet(context);
                        },
                        child: Text(defaultHomePage),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                children: [
                  const Text("Theme"),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Dark mode (requires app restart)"),
                      CupertinoButton(
                        onPressed: () {
                          _showThemeSelectionDialog(context);
                        },
                        child: Text(
                          switch (SharedPrefs.prefs.getString('theme')) {
                            "dark" => "Dark",
                            "light" => "Light",
                            _ => "System",
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                children: [
                  const Text("Character View"),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Download character stroke data (30MB)"),
                      Row(
                        children: [
                          CupertinoButton(
                            onPressed: isDataDownloaded
                                ? null
                                : () async {
                                    setState(() {
                                      isDownloading = true;
                                    });
                                    CharacterStokesSql.createTable().then(
                                      (value) {
                                        SharedPrefs.prefs.setBool(
                                            'character_stroke_data_downloaded',
                                            true);
                                        setState(() {
                                          isDataDownloaded = true;
                                        });
                                        showCupertinoDialog(
                                          barrierDismissible: true,
                                          context: context,
                                          builder: (context) {
                                            return const CupertinoAlertDialog(
                                              content:
                                                  Text("Download succeeded"),
                                            );
                                          },
                                        );
                                      },
                                      onError: (e) {
                                        showCupertinoDialog(
                                          barrierDismissible: true,
                                          context: context,
                                          builder: (context) {
                                            return const CupertinoAlertDialog(
                                              content: Text("Download failed"),
                                            );
                                          },
                                        );
                                      },
                                    ).whenComplete(() {
                                      setState(() {
                                        isDownloading = false;
                                      });
                                    });
                                  },
                            child: const Text("Download"),
                          ),
                          if (isDownloading) const CupertinoActivityIndicator(),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Visibility(
                //disabled for ios as it is currently not working
                visible: !PlatformInfo.isIOs(),
                child: Column(
                  children: [
                    const Text("Backup"),
                    Row(
                      children: [
                        const Text("Backup data"),
                        IconButton(
                            onPressed: () async {
                              Future<bool> updated =
                                  Backup.startBackupWithFileSelection();
                              updated.then(
                                (val) => showCupertinoDialog(
                                    barrierDismissible: true,
                                    context: context,
                                    builder: (context) {
                                      late final String text;
                                      val == true
                                          ? text = "backup succeeded"
                                          : text = backupFailedMessage;
                                      return CupertinoAlertDialog(
                                        content: Text(text),
                                      );
                                    }),
                                onError: (e) => showCupertinoDialog(
                                    barrierDismissible: true,
                                    context: context,
                                    builder: (context) {
                                      return const CupertinoAlertDialog(
                                        content: Text(backupFailedMessage),
                                      );
                                    }),
                              );
                            },
                            icon: const Icon(Icons.add)),
                      ],
                    ),
                    Row(
                      children: [
                        const Text("restore from backup"),
                        IconButton(
                            onPressed: () async {
                              bool updated =
                                  await Backup.restoreBackupFromUserFile();
                              setState(() {});
                              showCupertinoDialog(
                                  barrierDismissible: true,
                                  context: context,
                                  builder: (context) {
                                    late final String text;
                                    updated
                                        ? text = "backup succeeded"
                                        : text = backupFailedMessage;
                                    return CupertinoAlertDialog(
                                      content: Text(text),
                                    );
                                  });
                            },
                            icon: const Icon(Icons.add)),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  clicks++;
                  if (clicks == 5) {
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
                    FutureBuilder<String>(
                      future: _getVersion(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CupertinoActivityIndicator();
                        } else if (snapshot.hasError) {
                          return const Text("Error");
                        } else {
                          return Text(snapshot.data ?? 'Unknown');
                        }
                      },
                    )
                  ],
                ),
              ),
              const SizedBox(
                height: 10,
              ),
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
                          activeTrackColor: CupertinoColors.activeBlue,
                          onChanged: (bool value) {
                            setSettingBool(
                                name: "debug", type: "bool", value: value);
                            setState(() => debug = value);
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
                          activeTrackColor: CupertinoColors.activeBlue,
                          onChanged: (bool value) {
                            setSettingBool(
                                name: "allow_skip_units",
                                type: "bool",
                                value: value);
                            setState(() => allowSkipUnits = value);
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
                          activeTrackColor: CupertinoColors.activeBlue,
                          onChanged: (bool value) {
                            setSettingBool(
                                name: "check_for_new_version_on_start",
                                type: "bool",
                                value: value);
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
                          activeTrackColor: CupertinoColors.activeBlue,
                          onChanged: (bool value) {
                            setSettingBool(
                                name: "allow_auto_complete_unit",
                                type: "bool",
                                value: value);
                            setState(() => allowAutoComplete = value);
                          },
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Delete stroke data"),
                        Row(
                          children: [
                            CupertinoButton(
                              onPressed: () async {
                                setState(() {
                                  isDeleting = true;
                                });
                                CharacterStokesSql.dropTable().then(
                                  (value) {
                                    SharedPrefs.prefs.setBool(
                                        'character_stroke_data_downloaded',
                                        false);
                                    showCupertinoDialog(
                                      barrierDismissible: true,
                                      context: context,
                                      builder: (context) {
                                        return const CupertinoAlertDialog(
                                          content: Text("Deletion succeeded"),
                                        );
                                      },
                                    );
                                  },
                                  onError: (e) {
                                    showCupertinoDialog(
                                      barrierDismissible: true,
                                      context: context,
                                      builder: (context) {
                                        return const CupertinoAlertDialog(
                                          content: Text("Deletion failed"),
                                        );
                                      },
                                    );
                                  },
                                ).whenComplete(() {
                                  setState(() {
                                    isDeleting = false;
                                  });
                                });
                              },
                              child: const Text("Delete"),
                            ),
                            if (isDeleting) const CupertinoActivityIndicator(),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () async {
                            final map = Preferences.getAllPreferences();
                            print(map);
                            List settings = [];
                            map.forEach((k, v) => settings.add([k, v]));
                            showCupertinoDialog(
                                barrierDismissible: true,
                                context: context,
                                builder: (context) {
                                  return Dialog(
                                    child: ListView.builder(
                                        itemCount: settings.length,
                                        itemBuilder:
                                            (BuildContext context, int index) {
                                          return Center(
                                            child: Text(
                                                "${settings[index][0]}: ${settings[index][1]}"),
                                          );
                                        }),
                                  );
                                });
                          },
                          child: const Text("Show all settings"),
                        )
                      ],
                    ),
                    Visibility(
                      visible: false, //enable to fetch from db
                      child: Row(
                        children: [
                          const Text("Get latest data"),
                          IconButton(
                              onPressed: () async {
                                Future<bool> updated =
                                    PgUpdate.updateSqliteFromPg();
                                updated.then(
                                  (val) => showCupertinoDialog(
                                      barrierDismissible: true,
                                      context: context,
                                      builder: (context) {
                                        return const CupertinoAlertDialog(
                                          content: Text("updated: true"),
                                        );
                                      }),
                                  onError: (e) => showCupertinoDialog(
                                      barrierDismissible: true,
                                      context: context,
                                      builder: (context) {
                                        return const CupertinoAlertDialog(
                                          content: Text("updated: false"),
                                        );
                                      }),
                                );
                              },
                              icon: const Icon(Icons.add)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String> _getVersion() async {
    final content = await rootBundle.loadString('pubspec.yaml');
    final pubspec = Pubspec.parse(content);
    final version = pubspec.version?.toString() ?? 'Unknown';
    return version.split('+').first;
  }
}

// only for testing, can be deleted
Map<String, dynamic> currSentence() {
  //return  {"characters": "她叫什么名字", "pinyin": "tā jiào shénme míngzì", "meaning": "what's her name"};
  //return {"characters": "我的弟弟想长高", "pinyin": "Wǒ de dìdi xiǎng zhǎng gāo", "meaning": "my younger brother wants to grow taller",};
  return {
    "characters": "我爱我的国家，它有很多美丽的河流和公园",
    "pinyin": "wǒ ài wǒ de guójiā, tā yǒu hěnduō měilì de héliú hé gōngyuán",
    "meaning":
        "I love my country, it has many beautiful rivers and parks and more words"
  };
}

void sentenceGameCallBack(
    bool value, Map<String, dynamic> currSentence, bool buildEnglish) {}
