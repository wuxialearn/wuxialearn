import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hsk_learner/data_model/review_rating.dart';
import 'package:hsk_learner/data_model/word_item.dart';
import 'package:hsk_learner/screens/stats/character_view.dart';
import 'package:hsk_learner/sql/review_flashcards_sql.dart';

import '../../sql/stats_sql.dart';
import '../../sql/word_view_sql.dart';
import '../../utils/prototype.dart';
import '../settings/preferences.dart';
import 'flashcard.dart';

class ReviewFlashcards extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> hskList;
  final Function update;
  final String type;
  final int deckSize;
  final List<ReviewRating> ratings;
  const ReviewFlashcards(
      {Key? key,
      required this.hskList,
      required this.update,
      required this.type,
      required this.deckSize,
      required this.ratings})
      : super(key: key);

  @override
  State<ReviewFlashcards> createState() => _ReviewFlashcardsState();
}

class _ReviewFlashcardsState extends State<ReviewFlashcards> {
  bool lastPage = false;
  bool wasClicked = false;
  bool showPinyin =
      Preferences.getPreference("show_pinyin_by_default_in_review");
  bool showHint = false;
  bool showShowHint = false;
  bool showSentences = false;
  final PageController _pageController = PageController(initialPage: 0);
  int offset = 0;

  late Future<List<Map<String, dynamic>>> reviewList;

  @override
  void initState() {
    reviewList = widget.hskList;
    super.initState();
    setShowHint();
    setLanguage();
  }

  setShowHint() async {
    List<WordItem> wordList = createWordList(await widget.hskList);
    showShowHint = wordList[0].hanzi.length > 1;
  }

  nextButtonCallback() {
    setState(() {
      wasClicked = true;
    });
  }

  Future<List<Map<String, dynamic>>> appendElements(
      Future<List<Map<String, dynamic>>> listFuture,
      Future<List<Map<String, dynamic>>> elementsToAdd) async {
    final list = await listFuture;
    final list2 = await elementsToAdd;
    final list3 = [...list, ...list2];
    return list3;
  }

  Duration getRandomDuration(Duration min, Duration max) {
    int minMilliseconds = min.inMilliseconds;
    int maxMilliseconds = max.inMilliseconds;
    Random rnd = Random();
    var range = (maxMilliseconds - minMilliseconds);
    return Duration(milliseconds: minMilliseconds + rnd.nextInt(range));
  }

  answerButtonCallBack(int id) {
    return (int value) async {
      int stat = value == 0 || value == 1 ? 0 : 1;
      StatsSql.insertStat(value: stat, id: id);
      ReviewRating rating =
          widget.ratings.firstWhere((element) => element.id == value);
      late DateTime dateTime;
      if (rating.start == rating.end) {
        dateTime = DateTime.now().add(rating.start);
      } else {
        dateTime =
            DateTime.now().add(getRandomDuration(rating.start, rating.end));
      }
      final int time = dateTime.toUtc().millisecondsSinceEpoch ~/ 1000;
      ReviewFlashcardsSql.updateReview(id: id, time: time, ratingId: rating.id);
      widget.update();
      /*
      still needs some thought on what we should do here
      if(widget.type == "SRS"){
        final newList =  ReviewSql.getSrsReview(deckSize: 10);
        setState(() {
          reviewList = newList;
        });}
       */
      if (_pageController.hasClients) {
        if (lastPage) {
          Navigator.pop(context);
        } else {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      }
      setState(() {
        wasClicked = false;
        showHint = false;
      });
    };
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  FlutterTts flutterTts = FlutterTts();
  setLanguage() async {
    await flutterTts.setLanguage("zh-CN");
  }

  Future speak(String text) async {
    await flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text("Review"),
      ),
      child: SafeArea(
        child: Column(
          children: [
            FutureBuilder<List<Map<String, dynamic>>>(
                future: reviewList,
                builder: (BuildContext context,
                    AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                  if (snapshot.hasData) {
                    List<WordItem> wordList = createWordList(snapshot.data!);
                    return Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Visibility(
                                visible: showShowHint,
                                child: TextButton(
                                    onPressed: () {
                                      setState(() {
                                        showHint = !showHint;
                                      });
                                    },
                                    child: showHint
                                        ? const Text("Hide Hint")
                                        : const Text("Show Hint")),
                              ),
                              TextButton(
                                  onPressed: () {
                                    setState(() {
                                      showSentences = !showSentences;
                                    });
                                  },
                                  child: showSentences
                                      ? const Text("Hide Sentences")
                                      : const Text("Show Sentences")),
                              TextButton(
                                  onPressed: () {
                                    setState(() {
                                      showPinyin = !showPinyin;
                                    });
                                  },
                                  child: showPinyin
                                      ? const Text("Hide Pinyin")
                                      : const Text("Show Pinyin")),
                            ],
                          ),
                          Expanded(
                              child: PageView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            controller: _pageController,
                            itemCount: wordList.length,
                            onPageChanged: (index) {
                              if (index + 1 == wordList.length) {
                                lastPage = true;
                              }
                              showSentences = false;
                              setState(() {
                                showShowHint = wordList[index].hanzi.length > 1;
                              });
                            },
                            itemBuilder: (context, pageIndex) {
                              final sentencesFuture =
                                  WordViewSql.getSentenceFromId(
                                      wordList[pageIndex].id);
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: FlashCard(
                                        showFrontSide: !wasClicked,
                                        front: Column(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Visibility(
                                                      visible: showPinyin,
                                                      child: Text(
                                                        wordList[pageIndex]
                                                            .pinyin,
                                                        style: const TextStyle(
                                                            fontSize: 20,
                                                            color:
                                                                Colors.black54),
                                                      )),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Visibility(
                                                        maintainState: true,
                                                        maintainSize: true,
                                                        maintainAnimation: true,
                                                        visible: false,
                                                        child: IconButton(
                                                            onPressed: () {
                                                              speak(wordList[
                                                                      pageIndex]
                                                                  .hanzi);
                                                            },
                                                            icon: const Icon(
                                                                Icons
                                                                    .volume_up)),
                                                      ),
                                                      Row(
                                                          children: List.generate(wordList[pageIndex]
                                                              .hanzi.length, (e){
                                                            return GestureDetector(
                                                              onTap: () {
                                                                Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                      builder: (context) => CharacterView(character: wordList[pageIndex]
                                                                          .hanzi[e])
                                                                  ),
                                                                );
                                                              },
                                                              child: Text(
                                                                wordList[pageIndex]
                                                                    .hanzi[e],
                                                                style: const TextStyle(
                                                                  fontSize: 40,
                                                                  color: Colors.blue
                                                                ),
                                                              ),
                                                            );
                                                          }
                                                          )
                                                      ),
                                                      Visibility(
                                                        maintainState: true,
                                                        maintainSize: true,
                                                        maintainAnimation: true,
                                                        visible: showPinyin,
                                                        child: IconButton(
                                                            onPressed: () {
                                                              speak(wordList[
                                                                      pageIndex]
                                                                  .hanzi);
                                                            },
                                                            icon: const Icon(
                                                                Icons
                                                                    .volume_up)),
                                                      ),
                                                    ],
                                                  ),
                                                  Visibility(
                                                      visible: showHint,
                                                      child: Text(
                                                        wordList[pageIndex]
                                                            .literal
                                                            .join(" + "),
                                                        style: const TextStyle(
                                                            fontSize: 20,
                                                            color:
                                                                Colors.black54),
                                                      )),
                                                ],
                                              ),
                                            ),
                                            Visibility(
                                              visible: showSentences,
                                              child: Expanded(
                                                  child: _Sentences(
                                                sentencesFuture:
                                                    sentencesFuture,
                                                showPinyin: showPinyin,
                                                showTranslation: false,
                                              )),
                                            ),
                                            _ShowNextCardButton(
                                                callback: nextButtonCallback),
                                          ],
                                        ),
                                        back: Column(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      wordList[pageIndex]
                                                          .pinyin,
                                                      style: const TextStyle(
                                                          fontSize: 25,
                                                          color: Colors.black),
                                                    ),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Visibility(
                                                          maintainState: true,
                                                          maintainSize: true,
                                                          maintainAnimation:
                                                              true,
                                                          visible: false,
                                                          child: IconButton(
                                                              onPressed: () {
                                                                speak(wordList[
                                                                        pageIndex]
                                                                    .hanzi);
                                                              },
                                                              icon: const Icon(
                                                                  Icons
                                                                      .volume_up)),
                                                        ),
                                                        Row(
                                                            children: List.generate(wordList[pageIndex]
                                                                .hanzi.length, (e){
                                                              return GestureDetector(
                                                                onTap: () {
                                                                  Navigator.push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                        builder: (context) => CharacterView(character: wordList[pageIndex]
                                                                            .hanzi[e])
                                                                    ),
                                                                  );
                                                                },
                                                                child: Text(
                                                                  wordList[pageIndex]
                                                                      .hanzi[e],
                                                                  style: const TextStyle(
                                                                      fontSize: 40,
                                                                      color: Colors.blue
                                                                  ),
                                                                ),
                                                              );
                                                            }
                                                            )
                                                        ),
                                                        Visibility(
                                                          maintainState: true,
                                                          maintainSize: true,
                                                          maintainAnimation:
                                                              true,
                                                          visible: true,
                                                          child: IconButton(
                                                              onPressed: () {
                                                                speak(wordList[
                                                                        pageIndex]
                                                                    .hanzi);
                                                              },
                                                              icon: const Icon(
                                                                  Icons
                                                                      .volume_up)),
                                                        ),
                                                      ],
                                                    ),
                                                    Text(
                                                      wordList[pageIndex]
                                                          .translation,
                                                      style: const TextStyle(
                                                          fontSize: 25,
                                                          color: Colors.black),
                                                    ),
                                                    Visibility(
                                                        visible: showHint,
                                                        child: Text(
                                                          wordList[pageIndex]
                                                              .literal
                                                              .join(" + "),
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 20,
                                                                  color: Colors
                                                                      .black54),
                                                        )),
                                                  ]),
                                            ),
                                            Visibility(
                                              visible: showSentences,
                                              child: Expanded(
                                                  child: _Sentences(
                                                sentencesFuture:
                                                    sentencesFuture,
                                                showPinyin: true,
                                                showTranslation: true,
                                              )),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(15.0),
                                              child: SingleChildScrollView(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                child: _AnswerButton(
                                                    ratings: widget.ratings,
                                                    callback:
                                                        answerButtonCallBack(
                                                            wordList[pageIndex]
                                                                .id)),
                                              ),
                                            )
                                          ],
                                        )),
                                  ),
                                ],
                              );
                            },
                          )),
                        ],
                      ),
                    );
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                }),
          ],
        ),
      ),
    );
  }
}

class _ShowNextCardButton extends StatelessWidget {
  final Function() callback;
  const _ShowNextCardButton({
    Key? key,
    required this.callback,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => {
                callback(),
              },
              child: const Text("Show"),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  final Function(int value) callback;
  final List<ReviewRating> ratings;
  const _AnswerButton({
    Key? key,
    required this.callback,
    required this.ratings,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(ratings.length, (index) {
        return TextButton(
          onPressed: () {
            callback(ratings[index].id);
          },
          child: Column(
            children: [
              Text(ratings[index].interval()),
              Text(ratings[index].name),
            ],
          ),
        );
      }),
    );
  }
}

class _Sentences extends StatelessWidget {
  const _Sentences(
      {required this.sentencesFuture,
      required this.showPinyin,
      required this.showTranslation});
  final Future<List<Map<String, dynamic>>> sentencesFuture;
  final bool showPinyin;
  final bool showTranslation;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
        future: sentencesFuture,
        builder: (BuildContext context,
            AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.hasData) {
            List<Map<String, dynamic>> sentences = snapshot.data!;
            if (sentences.isEmpty) {
              return const Column(
                children: [
                  SizedBox(
                    height: 20,
                  ),
                  Text(
                    "There are no sentences yet for this word",
                    style: TextStyle(fontSize: 20),
                  ),
                ],
              );
            } else {
              return CustomScrollView(
                slivers: [
                  SliverList(
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: PrototypeHeight(
                                    prototype: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Visibility(
                                          visible: showPinyin,
                                          child: const Text("名字爱Míngzì",
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  color: Colors.black)),
                                        ),
                                        const Text(
                                          "名字爱Míngzì",
                                          style: TextStyle(
                                              fontSize: 20,
                                              color: Colors.black),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Visibility(
                                          visible: showTranslation,
                                          child: const Text(
                                            "名字爱Míngzì",
                                            style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.black),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        )
                                      ],
                                    ),
                                    child: ListView(
                                      scrollDirection: Axis.horizontal,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Visibility(
                                              visible: showPinyin,
                                              child: Text(
                                                sentences[index]["pinyin"],
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    color: Colors.black),
                                              ),
                                            ),
                                            Text(
                                              sentences[index]["characters"],
                                              style: const TextStyle(
                                                  fontSize: 20,
                                                  color: Colors.black),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Visibility(
                                              visible: showTranslation,
                                              child: Text(
                                                sentences[index]["meaning"],
                                                style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.black),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            )
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              );
            }
          } else {
            return const SizedBox();
          }
        });
  }
}
