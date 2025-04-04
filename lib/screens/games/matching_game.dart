import 'dart:async';

//import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hsk_learner/data_model/word_item.dart';
import 'package:hsk_learner/screens/games/unit_game.dart';
import 'package:hsk_learner/utils/large_text.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../settings/preferences.dart';
import '../../utils/styles.dart';

class MatchingGame extends StatefulWidget {
  final List<WordItem> wordList;
  final Function(bool value, WordItem currWord, bool? chineseToEnglish)
  callback;

  const MatchingGame({
    super.key,
    required this.wordList,
    required this.callback,
  });

  @override
  State<MatchingGame> createState() => _MatchingGameState();
}

class _MatchingGameState extends State<MatchingGame> {
  int numCords = 0;
  List leftYCords = [];
  List rightYCords = [];
  List isWrongLeft = [false, false, false, false, false];
  List isWrongRight = [false, false, false, false, false];
  Map<String, dynamic> isClicked = {"side": "", "index": 0};
  String lastClicked = "";
  int nextLeft = 0;
  int nextRight = 0;
  int nextValue = 0;
  double top = -1.0;
  bool first = true;
  double offset = 0.2;
  List completed = [];
  bool isFinished = false;
  final player = AudioPlayer();
  FlutterTts flutterTts = FlutterTts();
  late bool showPinyin;
  setLanguage() async {
    await flutterTts.setLanguage("zh-CN");
  }

  Future speak(String text) async {
    await flutterTts.awaitSpeakCompletion(true);
    await flutterTts.speak(text);
  }

  @override
  void initState() {
    super.initState();
    setLanguage();
    showPinyin = ShowPinyin.showPinyin;
    numCords = widget.wordList.length;
    leftYCords = createYCordList(numCords);
    rightYCords = createYCordList(numCords);
    bool debug = Preferences.getPreference("debug");
    if (!debug) {
      leftYCords.shuffle();
      rightYCords.shuffle();
    }
  }

  pushToTop({required int index, required String side}) {
    if (side == "left") {
      speak(widget.wordList[index].hanzi);
    }
    if (lastClicked != side && lastClicked != "") {
      int leftIndex = 0;
      int rightIndex = 0;
      if (side == "left") {
        leftIndex = index;
        rightIndex = nextValue;
      }
      if (side == "right") {
        leftIndex = nextValue;
        rightIndex = index;
      }
      if (!completed.contains(index)) {
        if (leftIndex == rightIndex) {
          completed.add(index);
          setState(() {
            push(index: leftIndex, list: leftYCords);
            push(index: rightIndex, list: rightYCords);
          });
          top = top + (2 / (numCords - 1));
        } else {
          setState(() {
            isWrongLeft[leftIndex] = true;
            isWrongRight[rightIndex] = true;
          });
          Timer(const Duration(milliseconds: 500), () {
            setState(() {
              isWrongLeft[leftIndex] = false;
              isWrongRight[rightIndex] = false;
            });
          });
        }
      }
      lastClicked = "";
      isClicked["side"] = "";
      if (completed.length == leftYCords.length) {
        setState(() {
          isFinished = true;
        });
      }
    } else {
      setState(() {
        isClicked["side"] = side;
        isClicked["index"] = index;
      });
      nextValue = index;
      lastClicked = side;
    }
  }

  push({required int index, required List list}) {
    for (int i = 0; i < list.length; i++) {
      if (list[i] < list[index] && list[i] >= top) {
        if (list[i] != list[index]) {
          list[i] = list[i] + (2 / (numCords - 1));
        }
      }
    }
    list[index] = top;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> stackLayers = List<Widget>.generate(
      widget.wordList.length * 2,
      (index) {
        if (index < widget.wordList.length) {
          return createAnimatedAlign(
            index: index,
            yCords: leftYCords,
            side: "left",
            wordType: "hanzi",
            xCord: (-1.0 + offset),
            fontSize: 20,
            isWrong: isWrongLeft,
          );
        } else {
          var newIndex = index % numCords;
          return createAnimatedAlign(
            index: newIndex,
            yCords: rightYCords,
            side: "right",
            wordType: "translations0",
            xCord: (1.0 - offset),
            fontSize: 14,
            isWrong: isWrongRight,
          );
        }
      },
    );
    return CupertinoPageScaffold(
      child: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      showPinyin = !showPinyin;
                      ShowPinyin.showPinyin = showPinyin;
                    });
                  },
                  child:
                      showPinyin
                          ? const Text("Hide Pinyin")
                          : const Text("Show Pinyin"),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(
                child: Text("Match the words", style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  //width: 250.0,
                  height: 475.0,
                  child: Stack(children: stackLayers),
                ),
              ),
            ),
            Visibility(
              maintainState: true,
              maintainAnimation: true,
              maintainSize: true,
              visible: isFinished,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Flexible(
                      fit: FlexFit.tight,
                      child: TextButton(
                        onPressed: () async {
                          await player.setAsset('assets/correct.wav');
                          player.play();
                          widget.callback(
                            true,
                            WordItem(LargeText.hskMap),
                            null,
                          );
                        },
                        child: const Text("Continue"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  createAnimatedAlign({
    required int index,
    required List yCords,
    required String side,
    required String wordType,
    required double xCord,
    required double fontSize,
    required List isWrong,
  }) {
    return AnimatedAlign(
      alignment: Alignment(xCord, yCords[index]),
      duration: const Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
      child: TextButton(
        style:
            completed.contains(index)
                ? Styles.createButton2(const Color(0xFF00FF00))
                : isWrong[index]
                ? Styles.createButton2(const Color(0xFFFF0000))
                : isClicked["side"] == side && isClicked["index"] == index
                ? Styles.createButton2(
                  const Color(0xFFB0B0B0),
                  border: const Color(0xff0000ff),
                )
                : Styles.createButton2(const Color(0xFFB0B0B0)),
        onPressed: () {
          pushToTop(index: index, side: side);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Visibility(
              visible: wordType == "hanzi" && showPinyin,
              child: Text(widget.wordList[index].pinyin),
            ),
            Text(
              wordType == "hanzi"
                  ? widget.wordList[index].hanzi
                  : widget.wordList[index].translation,
              style: TextStyle(fontSize: fontSize),
            ),
          ],
        ),
      ),
    );
  }
}

createYCordList(length) {
  double offset = 2 / (length - 1);
  final fixedLengthList = List<double>.generate(length, (int index) {
    if (index == length - 1) {
      return -1.0;
    }
    var currYCord = 1.0 - (index * offset);
    return currYCord;
  });
  return fixedLengthList;
}
