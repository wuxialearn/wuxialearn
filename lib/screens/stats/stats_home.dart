import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hsk_learner/screens/stats/stats.dart';
import 'package:hsk_learner/screens/stats/word_view.dart';
import 'package:hsk_learner/sql/sql_helper.dart';
import 'package:hsk_learner/sql/stats_sql.dart';
import 'package:hsk_learner/utils/larg_text.dart';
import 'package:hsk_learner/utils/prototype.dart';
import 'package:hsk_learner/utils/styles.dart';
import '../../data_model/word_item.dart';
import 'chart.dart';
import '../../widgets/hsk_listview/hsk_listview.dart';

class StatsHome extends StatefulWidget {
  const StatsHome({Key? key}) : super(key: key);

  @override
  State<StatsHome> createState() => _StatsHomeState();
}

class _StatsHomeState extends State<StatsHome> {

  late Future<List<Map<String, dynamic>>> recentHskList;
  late Future<List<Map<String, dynamic>>> weakHskList;
  late Future<List<Map<String, dynamic>>> statsListFuture;
  late Future<List<Map<String, dynamic>>> timelineList;
  late Future<List<Map<String, dynamic>>> globalStats;

  @override
  initState() {
    super.initState();
    weakHskList = getStats(sortBy: "percent_correct", orderBy: "ASC", deckSize: 10, where: "WHERE wrong_occurrence > 0");
    recentHskList = getStats(sortBy: "last_seen", orderBy: "DESC", deckSize: 10);
    statsListFuture = StatsSql.getOverview();
    timelineList = getTimeLine(sortBy: "string_date", orderBy: "ASC");
    globalStats = getGlobalStats();
  }

  Future<List<Map<String, dynamic>>> getStats({required String sortBy, required String orderBy, required int deckSize, String where = ""}) async {
    return await StatsSql.getStats(sortBy: sortBy, orderBy: orderBy, deckSize: deckSize, where: where);
  }

  Future<List<Map<String, dynamic>>> getGlobalStats() async {
    return await StatsSql.getTotalStats();
  }


  Future<List<Map<String, dynamic>>> getTimeLine({required String sortBy, required String orderBy,}) async {
    return await StatsSql.getTimeline(sortBy: sortBy, orderBy: orderBy, deckSize: -1,);
  }
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text("Stats"),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5)
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 15.0),
                            child: Text("This Week"),
                          ),
                          Visibility(
                            maintainState: true,
                            maintainAnimation: true,
                            maintainSize: true,
                            visible: false,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 0),
                              child: IconButton(onPressed: (){}, icon: const Icon(Icons.tune_rounded)),
                            ),
                          ),
                        ],
                      ),
                      FutureBuilder<List<Map<String, dynamic>>>(
                          future: timelineList,
                          builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                            if (snapshot.hasData) { List<Map<String, dynamic>> timeline = snapshot.data!;
                            return _StatsChart(timeline: timeline,);
                            } else {
                              return const _StatsChart(timeline: [{"string_date": "2022-10-26", "right_occurrence": 0, "wrong_occurrence": 0, "new_word": 0, "total": 0, "score": 0}]);
                            }
                          }
                      ),
                      FutureBuilder<List<Map<String, dynamic>>>(
                          future: statsListFuture,
                          builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                            if (snapshot.hasData) {
                              List<Map<String, dynamic>> statsList = snapshot.data!;
                              final String mostSeen = statsList[0]["most_seen"];
                              final int mostSeenId = statsList[0]["most_seen_id"];
                              final int newWords = statsList[0]["new_words"];
                              final int reviewWords = statsList[0]["review_words"];
                              final int successRate = statsList[0]["percent_correct"];
                              return _QuickStats(newWords: newWords.toString(), reviewWords: reviewWords.toString(), successRate: successRate.toString(), mostSeen: mostSeen, id: mostSeenId);
                            } else {
                              return PrototypeHeight(
                                prototype: const _QuickStats(newWords: "0", reviewWords: "0", successRate: "0", mostSeen: "爱", id:0),
                                child: Container(),
                              );
                            }
                          }
                      ),
                    ],
                  ),
                ),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: globalStats,
                  builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                      if (snapshot.hasData) { List<Map<String, dynamic>> globalStats = snapshot.data!;
                        return TotalStats(globalStats: globalStats[0]);
                      } else {
                        Map<String, dynamic> globalStats = {
                          "current_hsk": 2,
                          "percent_current_hsk_completed": 1.1,
                          "number_of_words_seen" : 0,
                          "number_characters_seen" : 0
                        };
                        return PrototypeHeight(
                          prototype: TotalStats(globalStats: globalStats,),
                          child: Container(color: Colors.white,),
                        );
                      }
                  },
                ),
                _HorizontalHskList(hskList: recentHskList, title: "Recent Words", showPlayButton: false),
                _HorizontalHskList(hskList: weakHskList, title: "Difficult Words", showPlayButton: false,)
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TotalStats extends StatelessWidget {
  final Map<String, dynamic> globalStats;
  const TotalStats({super.key, required this.globalStats});

  @override
  Widget build(BuildContext context) {
    final String currHsk = globalStats["current_hsk"] == "2"? "1-2": globalStats["current_hsk"].toString();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 15),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(7)
        ),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Total Stats"),
              ],
            ),
            const SizedBox(height: 20,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text("hsk $currHsk"),
                    Text("${globalStats["percent_current_hsk_completed"].toString().substring(0,3)}%")
                  ],
                ),

                Column(
                  children: [
                    const Text("total words"),
                    Text(globalStats["number_of_words_seen"].toString())
                  ],
                ),
                Column(
                  children: [
                    const Text("total characters"),
                    Text(globalStats["number_characters_seen"].toString())
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class _QuickStats extends StatelessWidget {
  const _QuickStats({required this.newWords, required this.reviewWords, required this.successRate, required this.mostSeen, required this.id});
  final String newWords;
  final String reviewWords;
  final String successRate;
  final String mostSeen;
  final int id;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        padding: const EdgeInsets.only(top: 10, bottom: 10),
        child: Column(
          children: [
            const Text("Quick Stats"),
            const SizedBox(height: 20,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text("New"),
                    Text(newWords)
                  ],
                ),
                Column(
                  children: [
                    const Text("Reviewed"),
                    Text(reviewWords)
                  ],
                ),
                Column(
                  children: [
                    const Text("Correct"),
                    Text("$successRate%")
                  ],
                ),
                Column(
                  children: [
                    const Text("Most Seen"),
                    TextButton(
                      style: Styles.blankButtonNoPadding,
                      onPressed: (){
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WordView(wordId: id),
                          ),
                        );
                      },
                      child: Text(mostSeen),
                    )
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class _StatsChart extends StatelessWidget {
  const _StatsChart({required this.timeline});
  final List<Map<String, dynamic>> timeline;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Activity"),
            ],),
          const SizedBox(height: 10,),
          Padding(
            padding: const EdgeInsets.only(right: 20, left: 10,),
            child: SizedBox(
                height: 150,
                child: HskChart(timelineList: timeline, numDays: 7)
            ),
          ),
        ],
      ),
    );
  }
}


class _HorizontalHskList extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> hskList;
  final String title;
  final bool showPlayButton;
  const _HorizontalHskList({Key? key, required this.hskList, required this.title, required this.showPlayButton}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final wordMap = WordItem(LargeText.hskMap);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5)
        ),
        padding: const EdgeInsets.only(left: 8, right: 8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title),
                CupertinoButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StatsPage(),
                      ),
                    );
                  },
                  child: const Text("Show All"),
                )
              ],
            ),
            PrototypeHeight(
              prototype: PrototypeHorizontalHskListView(connectTop: true, color: Colors.white, wordItem: wordMap, showTranslation: true, playCallback: (String s){}, showPlayButton: showPlayButton, showPinyin: true,),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: hskList,
                  builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                    if (snapshot.hasData) {
                      List<Map<String, dynamic>>? hskList = snapshot.data;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: 1 == 1?
                            const BorderRadius.vertical(bottom: Radius.circular(10))
                                :BorderRadius.circular(10),
                            color:Colors.white,
                          ),
                          child: ListView.builder(
                            physics: const ScrollPhysics(),
                            padding: EdgeInsets.zero,
                            scrollDirection: Axis.horizontal,
                            itemCount: hskList!.length,
                            itemBuilder: (context, index) {
                              return _HskListviewItem(
                                hskList: hskList[index],
                                showTranslation: true,
                                separator: false,
                                callback: (String s){},
                                showPlayButton: showPlayButton,
                              );
                            },
                          ),
                        ),
                      );
                    }
                    else{
                      return PrototypeHeight(
                        prototype: PrototypeHorizontalHskListView(connectTop: true, color: Colors.white, wordItem: wordMap, showTranslation: true, playCallback: (String s){}, showPlayButton: showPlayButton, showPinyin: true,),
                        child: Container(),
                      );
                    }
                  }
              ),
            ),
          ],
        ),
      ),
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


/*
this has the potential to be disheartening
Column(
  children: [
    const Text("percent_course_completed"),
    Text(globalStats[0]["percent_course_completed"].toString())
  ],
),
 */