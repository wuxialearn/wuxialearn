import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hsk_learner/screens/learn/unit_learn.dart';
import '../../sql/sql_helper.dart';
import '../../utils/styles.dart';
import '../../widgets/hsk_listview/hsk_listview.dart';
import '../games/unit_game.dart';
import '../settings/preferences.dart';


class SubunitView extends StatefulWidget {
  const SubunitView({super.key, required this.hskList, required this.unit, required this.subunit, required this.lastSubunit, required this.name, required this.completed, required this.updateUnits});
  final List<Map<String, dynamic>> hskList;
  final int unit;
  final int subunit;
  final bool lastSubunit;
  final String name;
  final bool completed;
  final Function updateUnits;

  @override
  State<SubunitView> createState() => _SubunitViewState();
}

class _SubunitViewState extends State<SubunitView> {

  late Future<List<Map<String, dynamic>>> sentenceList;
  final bool debug = Preferences.getPreference("debug");
  final bool allowSkipUnits = Preferences.getPreference("allow_skip_units");

  @override
  void initState() {
    sentenceList = SQLHelper.getSentencesForSubunit(widget.unit, widget.subunit);
    setLanguage();
    super.initState();
  }

  FlutterTts flutterTts = FlutterTts();
  setLanguage() async{
    await flutterTts.setLanguage("zh-CN");
  }
  Future speak(String text) async{
    await flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    print(widget.completed);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text("Subunit ${widget.unit}"),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                physics: const ScrollPhysics(),
                padding: EdgeInsets.zero,
                scrollDirection: Axis.vertical,
                itemCount: widget.hskList.length,
                itemBuilder: (context, index) {
                  return HskListviewItem(
                    hskList: widget.hskList[index],
                    showTranslation: true,
                    separator: true,
                    callback: (String s){
                      speak(s);
                    },
                    showPlayButton: true,
                  );
                },
              ),
            ),
            FutureBuilder<List<Map<String, dynamic>>>(
                future: sentenceList,
                builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot){
                  if(snapshot.hasData){
                    List<Map<String, dynamic>> sentenceList = snapshot.data!;
                    return Row(
                      children: [
                        Flexible(
                          fit: FlexFit.tight,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(context, MaterialPageRoute(
                                  builder: (context) => UnitLearn(
                                    hskList: widget.hskList,
                                    unit: widget.unit,
                                    subunit: widget.subunit,
                                    lastSubunit: widget.lastSubunit,
                                    name: widget.name,
                                    updateUnits: widget.updateUnits,
                                  ),
                                )).then((_){
                                  Navigator.pop(context);
                                });
                              },
                              child: const Text(
                                "Learn",
                                style: TextStyle(color: Colors.blue, fontSize: 25),
                              ),
                            ),
                          ),
                        ),
                        widget.completed || debug || allowSkipUnits?
                        Flexible(
                          fit: FlexFit.tight,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (context) => UnitGame(hskList: widget.hskList, unit: widget.unit,  sentenceList: sentenceList, subunit: widget.subunit, lastSubunit: widget.lastSubunit, name: "", updateUnits: widget.updateUnits,),
                                )).then((_){
                                  print("we havve completed and returned to unit view");
                                  widget.updateUnits();
                                  Navigator.pop(context);
                                });
                              },
                              child: const Text(
                                "Quiz",
                                style: TextStyle(color: Colors.blue, fontSize: 25),
                              ),
                            ),
                          ),
                        )
                            : const SizedBox(height: 0,),
                      ],
                    );
                  }else{
                    return const SizedBox(height: 0,);
                  }
                }
            ),
          ],
        ),
      ),
    );
  }
}