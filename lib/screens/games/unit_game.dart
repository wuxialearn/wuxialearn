import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../data_model/word_item.dart';
import '../../sql/learn_sql.dart';
import '../../sql/manage_review_sql.dart';
import '../../sql/stats_sql.dart';
import 'matching_game.dart';
import 'multiple_choice_game.dart';
import 'sentence_game.dart';

class UnitGame extends StatefulWidget {
  final List<WordItem> wordList;
  final List<Map<String, dynamic>> sentenceList;
  final int unit;
  final int subunit;
  final bool lastSubunit;
  final String name;
  final Function updateUnits;
  final String courseName;
  const UnitGame(
      {Key? key,
      required this.wordList,
      required this.sentenceList,
      required this.unit,
      required this.subunit,
      required this.lastSubunit,
      required this.name,
      required this.updateUnits,
      required this.courseName})
      : super(key: key);

  @override
  State<UnitGame> createState() => _UnitGameState();
}

class _UnitGameState extends State<UnitGame> {
  final PageController _pageController = PageController();
  List<Widget> gamesList = [];
  int gameIndex = 0;
  bool showPinyin = true;
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final groupNum = min(widget.wordList.length, 5);
    for (int i = 0; i < (widget.wordList.length ~/ groupNum); i++) {
      createGamesListForGroup(
          widget.wordList.sublist(i * groupNum,
              min((i * groupNum) + groupNum, widget.wordList.length)),
          widget.sentenceList.sublist(i * groupNum,
              min((i * groupNum) + groupNum, widget.sentenceList.length)));
    }
    _initPlayers();
  }

  final player = AudioPlayer();

  //this is an issue on android where the first play of the player is cut off
  Future<void> _initPlayers() async {
    await player.setAsset('assets/correct.wav');
    await player.load();
    final volume = player.volume;
    await player.setVolume(0.0);
    await player.play();
    await player.stop();
    await player.setVolume(volume);
  }

  void callback(bool value, WordItem currWord, bool? chineseToEnglish) async {
    if (widget.unit > 0 && chineseToEnglish != null) {
      final int result = value ? 1 : 0;
      StatsSql.insertStat(value: result, id: currWord.id);
      ManageReviewSql.addToReviewDeck(
          id: currWord.id, deck: widget.courseName, value: value);
    }
    if (value == false) {
      setState(() {
        gamesList.add(ChineseToEnglishGame(
            chineseToEnglish: chineseToEnglish,
            currWord: currWord,
            wordList: widget.wordList,
            callback: callback,
            index: gameIndex));
      });
    }
    updatePage();
  }

  void sentenceGameCallBack(
      bool value, Map<String, dynamic> currSentence, bool buildEnglish) {
    if (!value) {
      setState(() {
        gamesList.add(SentenceGame(
          callback: sentenceGameCallBack,
          currSentence: currSentence,
          buildEnglish: buildEnglish,
          index: gameIndex,
        ));
      });
    }
    updatePage();
  }

  void updatePage() {
    bool lastPage = gameIndex + 1 == gamesList.length;
    if (lastPage) {
      if (widget.lastSubunit) {
        LearnSql.completeUnit(unit: widget.unit);
      }
      LearnSql.completeSubUnit(unit: widget.unit, subUnit: widget.subunit);
      //here is where we update the values for the other units
      widget.updateUnits();
      Navigator.pop(context);
    } else {
      _pageController.animateToPage(gameIndex + 1,
          duration: const Duration(milliseconds: 300), curve: Curves.linear);
      gameIndex++;
    }
  }

  void createGamesListForGroup(
      List<WordItem> wordList, List<Map<String, dynamic>> sentenceList) {
    for (int i = 0; i < wordList.length; i++) {
      if (i % 2 == 0) {
        gamesList.add(ChineseToEnglishGame(
          chineseToEnglish: false,
          currWord: wordList[i],
          wordList: wordList,
          callback: callback,
          index: gameIndex,
        ));
      } else {
        gamesList.add(ChineseToEnglishGame(
          chineseToEnglish: true,
          currWord: wordList[i],
          wordList: wordList,
          callback: callback,
          index: gameIndex,
        ));
      }
    }
    gamesList.add(MatchingGame(
      wordList: wordList,
      callback: callback,
    ));
    for (int i = 0; i < sentenceList.length; i++) {
      if (i % 2 == 0) {
        gamesList.add(SentenceGame(
            callback: sentenceGameCallBack,
            currSentence: sentenceList[i],
            index: gameIndex,
            buildEnglish: true));
      } else {
        gamesList.add(SentenceGame(
            callback: sentenceGameCallBack,
            currSentence: sentenceList[i],
            index: gameIndex,
            buildEnglish: false));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        leading: ConfirmBackButtonIcon(),
        middle: Text("Quiz"),
      ),
      child: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: _pageController,
        children: gamesList,
      ),
    );
  }
}

class ConfirmBackButtonIcon extends StatelessWidget {
  const ConfirmBackButtonIcon({super.key});
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(CupertinoIcons.chevron_back),
      onPressed: () {
        showCupertinoDialog(
            barrierDismissible: true,
            context: context,
            builder: (context) {
              return CupertinoAlertDialog(
                content: const Text(
                  "Are you sure you want to exit?",
                  style: TextStyle(fontSize: 16),
                ),
                actions: [
                  CupertinoDialogAction(
                    /// This parameter indicates this action is the default,
                    /// and turns the action's text to bold text.
                    isDefaultAction: true,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel'),
                  ),
                  CupertinoDialogAction(
                    /// This parameter indicates this action is the default,
                    /// and turns the action's text to bold text.
                    isDefaultAction: true,
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text('Exit'),
                  ),
                ],
              );
            });
      },
    );
  }
}

class ShowPinyin {
  static bool showPinyin = false;
}
