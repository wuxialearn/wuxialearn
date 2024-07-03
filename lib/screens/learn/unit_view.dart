import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hsk_learner/data_model/word_item.dart';
import 'package:hsk_learner/screens/learn/subunit_view.dart';
import '../../sql/learn_sql.dart';
import '../../sql/manage_review_sql.dart';
import '../../sql/stats_sql.dart';
import '../settings/preferences.dart';
import '../../sql/sql_helper.dart';

class UnitView extends StatefulWidget {
  final int unit;
  final String name;
  final Function updateUnits;
  final String courseName;
  const UnitView(
      {Key? key,
      required this.unit,
      required this.name,
      required this.updateUnits,
      required this.courseName})
      : super(key: key);

  @override
  State<UnitView> createState() => _UnitViewState();
}

class _UnitViewState extends State<UnitView> {
  late Future<List<Map<String, dynamic>>> hskFuture;
  late Future<List<Map<String, dynamic>>> sentencesFuture;
  late Future<List<Map<String, dynamic>>> subunitFuture;
  final bool debug = Preferences.getPreference("debug");
  final bool allowAutoComplete =
      Preferences.getPreference("allow_auto_complete_unit");

  @override
  initState() {
    super.initState();
    sentencesFuture = LearnSql.getSentences(widget.unit);
    hskFuture = LearnSql.getUnitWithLiteralMeaning(widget.unit);
    subunitFuture = LearnSql.getSubunitInfo(unit: widget.unit);
  }

  updateUnits() {
    setState(() {
      widget.updateUnits();
      hskFuture = LearnSql.getUnitWithLiteralMeaning(widget.unit);
      subunitFuture = LearnSql.getSubunitInfo(unit: widget.unit);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.name),
      ),
      child: SafeArea(
        child: Column(
          children: [
            FutureBuilder<List<Map<String, dynamic>>>(
                future: hskFuture,
                builder: (BuildContext context,
                    AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                  if (snapshot.hasData) {
                    List<Map<String, dynamic>> hskList = snapshot.data!;
                    final wordList = createWordListWithSubunit(hskList);
                    int hskLength = hskList.length;
                    List<int> unitIndex = [0];
                    List<int> unitLength = [];
                    int lastIndex = 1;
                    int length = 0;
                    for (int i = 0; i < wordList.length; i++) {
                      if (wordList[i].subunit != lastIndex) {
                        unitIndex.add(i);
                        lastIndex++;
                        unitLength.add(i - length);
                        length += i - length;
                      }
                      if (i == wordList.length - 1) {
                        unitLength.add(i - length + 1);
                      }
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                                padding:
                                    const EdgeInsets.fromLTRB(13, 20, 20, 13),
                                child: RichText(
                                  text: TextSpan(
                                    style: DefaultTextStyle.of(context).style,
                                    children: <TextSpan>[
                                      TextSpan(
                                          text: hskLength.toString(),
                                          style: const TextStyle(
                                              color: Colors.blue)),
                                      const TextSpan(text: ' words'),
                                    ],
                                  ),
                                )),
                            Visibility(
                                visible: allowAutoComplete,
                                child: TextButton(
                                  onPressed: () {
                                    //should use transaction here and elsewhere
                                    for (final word in wordList) {
                                      StatsSql.insertStat(
                                          value: 1, id: word.id);
                                      ManageReviewSql.addToReviewDeck(
                                          id: word.id,
                                          deck: widget.courseName,
                                          value: true);
                                    }
                                    for (int i = 0;
                                        i < unitLength.length;
                                        i++) {
                                      LearnSql.completeSubUnit(
                                          unit: widget.unit, subUnit: i + 1);
                                    }
                                    LearnSql.completeUnit(unit: widget.unit);
                                  },
                                  child: const Text("Complete Unit"),
                                ))
                          ],
                        ),
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: subunitFuture,
                          builder: (BuildContext context,
                              AsyncSnapshot<List<Map<String, dynamic>>>
                                  snapshot) {
                            if (snapshot.hasData) {
                              List<Map<String, dynamic>> subunits =
                                  snapshot.data!;
                              return Column(
                                  children: List<Widget>.generate(
                                      unitIndex.length, (i) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0, vertical: 5),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: subunits[i]["completed"] == 1
                                          ? Colors.lightBlue
                                          : Colors.white,
                                      border: Border.all(
                                          width: 2.0, color: Colors.lightBlue),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          top: 8.0,
                                          left: 5.0,
                                          right: 3.0,
                                          bottom: 8.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8.0),
                                                  child: Text(
                                                    "Lesson ${i + 1}",
                                                    style: const TextStyle(
                                                        fontSize: 15),
                                                  ),
                                                ),
                                                Text(
                                                  wordList
                                                      .sublist(
                                                          unitIndex[i],
                                                          unitIndex[i] +
                                                              unitLength[i])
                                                      .map((e) => e.hanzi)
                                                      .toList()
                                                      .join(', '),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                      fontSize: 23),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                              highlightColor:
                                                  Colors.transparent,
                                              onPressed: () {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) => SubunitView(
                                                            courseName: widget
                                                                .courseName,
                                                            wordList: wordList.sublist(
                                                                unitIndex[i],
                                                                unitIndex[i] +
                                                                    unitLength[
                                                                        i]),
                                                            unit: widget.unit,
                                                            subunit: i + 1,
                                                            lastSubunit:
                                                                i + 1 ==
                                                                    unitIndex
                                                                        .length,
                                                            name: widget.name,
                                                            completed: subunits[
                                                                        i][
                                                                    "completed"] ==
                                                                1,
                                                            updateUnits:
                                                                updateUnits))).then(
                                                    (_) {
                                                  setState(() {
                                                    subunitFuture =
                                                        LearnSql.getSubunitInfo(
                                                            unit: widget.unit);
                                                  });
                                                });
                                              },
                                              icon: Container(
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(
                                                                100)),
                                                  ),
                                                  child: const Icon(
                                                    CupertinoIcons.arrow_right,
                                                    size: 30,
                                                  )))
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }));
                            } else {
                              return const CircularProgressIndicator();
                            }
                          },
                        )
                      ],
                    );
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                }),
            if (debug)
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "Sentences",
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                    _Sentences(
                      sentencesFuture: sentencesFuture,
                    )
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Sentences extends StatelessWidget {
  const _Sentences({required this.sentencesFuture});
  final Future<List<Map<String, dynamic>>> sentencesFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
        future: sentencesFuture,
        builder: (BuildContext context,
            AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.hasData) {
            List<Map<String, dynamic>>? sentences = snapshot.data;
            if (sentences!.isEmpty) {
              return const SliverToBoxAdapter(
                child: Column(
                  children: [
                    SizedBox(
                      height: 20,
                    ),
                    Text(
                      "There are no sentences yet for this unit",
                      style: TextStyle(fontSize: 20),
                    ),
                  ],
                ),
              );
            } else {
              List<int> unitIndex = [0];
              List<int> unitLength = [];
              int lastIndex = 1;
              int length = 0;
              for (int i = 0; i < sentences.length; i++) {
                if (sentences[i]["subunit"] != lastIndex) {
                  unitIndex.add(i);
                  lastIndex++;
                  unitLength.add(i - length - 1);
                  length += i - length - 1;
                }
                if (i == sentences.length - 1) {
                  unitLength.add(i - length);
                }
              }
              return SliverList(
                delegate:
                    SliverChildBuilderDelegate(childCount: sentences.length,
                        (BuildContext context, int index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        unitIndex.contains(index)
                            ? Text(
                                "subunit ${unitIndex.indexOf(index) + 1}",
                                style: const TextStyle(color: Colors.blue),
                              )
                            : const SizedBox(
                                height: 0,
                              ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sentences[index]["pinyin"],
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    sentences[index]["characters"],
                                    style: const TextStyle(fontSize: 20),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    sentences[index]["meaning"],
                                    style: const TextStyle(fontSize: 20),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(
                          height: 20,
                          thickness: 1,
                          indent: 5,
                          endIndent: 5,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  );
                }),
              );
            }
          } else {
            return const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()));
          }
        });
  }
}
