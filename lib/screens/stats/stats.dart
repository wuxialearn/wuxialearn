import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hsk_learner/screens/stats/word_view.dart';

import '../../utils/styles.dart';
import '../../sql/sql_helper.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({Key? key}) : super(key: key);

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {

  late Future<List<Map<String, dynamic>>> hskList;
  String sortValue = "Score";
  String orderValue = "Ascending";
  List<String> sortOptions = ["Score", "Last Seen", "Unit"];
  List<String> orderOption = ["Ascending", "Descending"];
  @override
  initState() {
    super.initState();
    refresh();
  }

  Future<List<Map<String, dynamic>>> getStats({required String sortBy, required String orderBy})  async {
    final data = await SQLHelper.getStats(sortBy: sortBy, orderBy: orderBy, deckSize: -1,);
    return data;
  }
  void refresh(){
    String orderSQL = "ASC";
    String sortSQl = "unit";
    switch(orderValue){
      case "Ascending" : orderSQL = "ASC"; break;
      case "Descending": orderSQL = "DESC"; break;
    }
    switch(sortValue){
      case "Unit": sortSQl = "unit"; break;
      case "Score": sortSQl = "score"; break;
      case "Last Seen": sortSQl = "last_seen"; break;
    }
    setState(() {
      hskList = getStats(sortBy: sortSQl, orderBy: orderSQL,);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        middle: Text("Stats"),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        children: [
                          const Text("Sort by:"),
                          TextButton(
                              onPressed: (){_showSortByActionSheet(context);},
                              child: Text(sortValue)
                          )
                        ],
                      ),
                      Row(
                        children: [
                          const Text("Order By:"),
                          TextButton(
                              onPressed: (){_showOrderByActionSheet(context);},
                              child: Text(orderValue)
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            _HskListview(hskList: hskList, showTranslation: true, connectTop: true, color: Colors.transparent, scrollAxis: Axis.vertical, showPlayButton: false,)
          ],
        ),
      ),
    );
  }

  _showSortByActionSheet<bool>(BuildContext context) {
    showCupertinoModalPopup<bool>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Sort by'),
        actions:
        List<CupertinoActionSheetAction>.generate(sortOptions.length,(index){
          return CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context, true);
              setState(() {
                sortValue = sortOptions[index];
              });
            },
            child: Text(sortOptions[index]),
          );
        }),
      ),
    );
  }
  _showOrderByActionSheet<bool>(BuildContext context) {
    showCupertinoModalPopup<bool>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Order by'),
        actions:
        List<CupertinoActionSheetAction>.generate(orderOption.length,(index){
          return CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context, true);
              setState(() {
                orderValue = orderOption[index];
              });
            },
            child: Text(orderOption[index]),
          );
        }),
      ),
    );
  }
}


class _HskListview extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> hskList;
  final bool showTranslation;
  final bool connectTop;
  final Color color;
  final Axis scrollAxis;
  final bool showPlayButton;
  const _HskListview({Key? key, required  this.hskList, required this.showTranslation, required this.connectTop, required this.color, required this.scrollAxis, required this.showPlayButton}) : super(key: key);

  get flutterTts => null;

  @override
  Widget build(BuildContext context) {
    FlutterTts flutterTts = FlutterTts();
    setLanguage() async{
      await flutterTts.setLanguage("zh-CN");
    }
    setLanguage();
    Future speak(String text) async{
      //await flutterTts.setLanguage("zh-CN");
      var result = await flutterTts.speak(text);
      //if (result == 1) setState(() => ttsState = TtsState.playing);
    }
    playCallback(String str){
      speak(str);
    }
    return FutureBuilder<List<Map<String, dynamic>>>(
            future: hskList,
            builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
              if (snapshot.hasData) {
                List<Map<String, dynamic>>? hskList = snapshot.data;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: connectTop?
                        const BorderRadius.vertical(bottom: Radius.circular(10))
                            :BorderRadius.circular(10),
                        color:color,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ListView.builder(
                                physics: const ScrollPhysics(),
                                padding: EdgeInsets.zero,
                                scrollDirection: scrollAxis,
                                itemCount: hskList!.length,
                                itemBuilder: (context, index) {
                                  return _HskListviewItem(hskList: hskList[index], showTranslation: showTranslation, separator: true, callback: playCallback, showPlayButton: showPlayButton);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }
              else{return const Center(child: CircularProgressIndicator());}
            }
        );
  }
}

class _HskListviewItem extends StatelessWidget {
  final Map<String, dynamic> hskList;
  final bool showTranslation;
  final bool separator;
  final Function(String) callback;
  final bool showPlayButton;
  const _HskListviewItem({Key? key, required this.hskList, required this.showTranslation, required this.separator, required this.callback, required this.showPlayButton,}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          //color: Colors.transparent,
          border: separator? const Border(bottom: BorderSide(width: 1.5, color: Color(0xFFECECEC)),)
              :const Border(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                    children: [
                      Text(
                        hskList["pinyin"],
                        style: const TextStyle(fontSize: 14),
                      ),
                      TextButton(
                        style: Styles.blankButtonNoPadding,
                        onPressed: (){
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WordView(wordId: hskList["id"]),
                            ),
                          );
                        },
                        child: Text(
                          hskList["hanzi"],
                          style: const TextStyle(fontSize: 25),
                        ),
                      ),
                    ]
                ),
                Visibility(
                  visible: showTranslation,
                  child: Text(
                    hskList["translations0"],
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF999EA3),
                    ),
                  ),
                )
              ],
            ),
            showPlayButton? IconButton(
                onPressed: () {
                  callback(hskList["hanzi"],);
                },
                icon: const Icon(Icons.volume_up))
                : const SizedBox(height: 0,)
          ],
        ),
      ),
    );
  }
}
