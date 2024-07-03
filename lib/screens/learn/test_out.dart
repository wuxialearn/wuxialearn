import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hsk_learner/data_model/word_item.dart';
import '../../sql/test_out_sql.dart';
import '../games/multiple_choice_game.dart';
import '../games/unit_game.dart';

class TestOut extends StatefulWidget {
  final int hsk;
  const TestOut({super.key, required this.hsk});

  @override
  State<TestOut> createState() => _TestOutState();
}

class _TestOutState extends State<TestOut> {
  late Future<List<Map<String, dynamic>>> reviewWordsListFuture;
  @override
  void initState() {
    reviewWordsListFuture = TestOutSql.getTestOutWords(hsk: widget.hsk);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        leading: ConfirmBackButtonIcon(),
        middle: Text("Test Out"),
      ),
      child: FutureBuilder<List<Map<String, dynamic>>>(
          future: reviewWordsListFuture,
          builder: (BuildContext context,
              AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
            if (snapshot.hasData) {
              List<WordItem> wordList = createWordList(snapshot.data!);
              return _TestOutController(
                wordList: wordList,
                hsk: widget.hsk,
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          }),
    );
  }
}

class _TestOutController extends StatefulWidget {
  final List<WordItem> wordList;
  final int hsk;
  const _TestOutController({
    Key? key,
    required this.wordList,
    required this.hsk,
  }) : super(key: key);

  @override
  State<_TestOutController> createState() => _TestOutControllerState();
}

class _TestOutControllerState extends State<_TestOutController> {
  final PageController _pageController = PageController();
  List<Widget> gamesList = [];
  int gameIndex = 0;
  int numIncorrect = 0;
  bool showPinyin = true;
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void callback(bool value, WordItem currWord, bool? empty) async {
    if (value == false) {
      numIncorrect++;
    }
    if (numIncorrect == 2) {
      setState(() {
        gamesList[gameIndex + 1] = (Scaffold(
            body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Center(child: Text("Try Again")),
            Center(
                child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Close")))
          ],
        )));
        _pageController.animateToPage(gameIndex + 1,
            duration: const Duration(milliseconds: 300), curve: Curves.linear);
      });
    } else {
      updatePage();
    }
  }

  void updatePage() {
    bool lastPage = gameIndex + 1 == gamesList.length;
    if (lastPage) {
      TestOutSql.completeHSKLevel(widget.hsk);
      Navigator.pop(context);
    } else {
      _pageController.animateToPage(gameIndex + 1,
          duration: const Duration(milliseconds: 300), curve: Curves.linear);
      gameIndex++;
    }
  }

  void createGamesListForGroup(List<WordItem> wordList) {
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
  }

  @override
  void initState() {
    super.initState();
    final groupNum = min(widget.wordList.length, 5);
    for (int i = 0; i < (widget.wordList.length ~/ groupNum); i++) {
      createGamesListForGroup(
        widget.wordList.sublist(i * groupNum,
            min((i * groupNum) + groupNum, widget.wordList.length)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      physics: const NeverScrollableScrollPhysics(),
      controller: _pageController,
      children: gamesList,
    );
  }
}
