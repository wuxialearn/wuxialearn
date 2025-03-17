import 'package:flutter/material.dart';
import 'package:hsk_learner/data_model/word_item.dart';
import 'package:hsk_learner/screens/games/unit_game.dart';
import 'package:hsk_learner/sql/learn_sql.dart';

class ReviewQuiz extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> hskList;
  const ReviewQuiz({Key? key, required this.hskList}) : super(key: key);

  @override
  State<ReviewQuiz> createState() => _ReviewQuizState();
}

class _ReviewQuizState extends State<ReviewQuiz> {
  late Future<List<Map<String, List<Map<String, dynamic>>>>> hskMap;
  @override
  void initState() {
    hskMap = getSentenceList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, List<Map<String, dynamic>>>>>(
      future: hskMap,
      builder: (
        BuildContext context,
        AsyncSnapshot<List<Map<String, List<Map<String, dynamic>>>>> snapshot,
      ) {
        if (snapshot.hasData) {
          List<Map<String, List<Map<String, dynamic>>>>? hskMap = snapshot.data;
          List<WordItem> wordList = [];
          List<Map<String, dynamic>> sentenceList = [];
          if (hskMap != null) {
            for (var i = 0; i < hskMap.length; i++) {
              wordList.add(WordItem(hskMap[i]["hskList"]![0]));
              if (hskMap[i]["sentenceList"] != null) {
                if (hskMap[i]["sentenceList"]!.isNotEmpty) {
                  sentenceList.add(hskMap[i]["sentenceList"]![0]);
                }
              }
            }
            return UnitGame(
              courseName: "",
              wordList: wordList,
              sentenceList: sentenceList,
              unit: 0,
              subunit: 0,
              lastSubunit: false,
              name: "review",
              updateUnits: () {},
            );
          } else {
            return Container();
          }
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Future<List<Map<String, List<Map<String, dynamic>>>>>
  getSentenceList() async {
    List<Map<String, dynamic>> completedHskList = await widget.hskList;
    Future<Map<String, List<Map<String, dynamic>>>> getUnits(int index) async {
      final data = await LearnSql.getExamples(completedHskList[index]["hanzi"]);
      Map<String, List<Map<String, dynamic>>> hskMap = {
        "hskList": [completedHskList[index]],
        "sentenceList": data,
      };
      return hskMap;
    }

    List<Future<Map<String, List<Map<String, dynamic>>>>> hskMap =
        List.generate(completedHskList.length, (i) => getUnits(i));
    return await Future.wait(hskMap);
  }
}
