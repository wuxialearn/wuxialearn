import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../settings/preferences.dart';
import '../../widgets/fixed_align.dart';

class SentenceGame extends StatefulWidget {
  final Map<String, dynamic> currSentence;
  final Function(bool value, Map<String, dynamic> currWord, bool buildEnglish)
      callback;
  final int index;
  final bool buildEnglish;

  const SentenceGame(
      {Key? key,
      required this.callback,
      required this.currSentence,
      required this.index,
      required this.buildEnglish})
      : super(key: key);

  @override
  State<SentenceGame> createState() => _SentenceGameState();
}

class _SentenceGameState extends State<SentenceGame> {
  late final String alreadyBuiltSentence;
  late final String sentenceToBuild;
  late final List<String> words;

  @override
  void initState() {
    alreadyBuiltSentence = widget.buildEnglish ? widget.currSentence["characters"] : widget.currSentence["meaning"];
    sentenceToBuild = widget.buildEnglish ? widget.currSentence["meaning"] : widget.currSentence["characters"];
    //now that we have tokenized we can just do one for both
    //words = widget.buildEnglish ? sentenceToBuild.split(" ") : sentenceToBuild.replaceAll(" ", "").split("");
    words = sentenceToBuild.split(" ");
    super.initState();
  }

  Widget checkAnswerWidget = const SizedBox(height: 0,);
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(
                  height: 30,
                ),
                Center(
                  child: Text(
                    alreadyBuiltSentence,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      return _SentenceGameMain(
                          alreadyBuiltSentence: alreadyBuiltSentence,
                          sentenceToBuild: sentenceToBuild,
                          words: words,
                          callback: widget.callback,
                          buildEnglish: widget.buildEnglish,
                          currSentence: widget.currSentence,
                          constraints: constraints,
                          setCheckAnswerWidget: (Widget w){
                            setState(() {
                              checkAnswerWidget = w;
                            });
                          },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          checkAnswerWidget,
        ],
      ),
    );
  }
}

class _SentenceGameMain extends StatefulWidget {
  final Function(bool value, Map<String, dynamic> currWord, bool buildEnglish) callback;
  final BoxConstraints constraints;
  final List<String> words;
  final String alreadyBuiltSentence;
  final String sentenceToBuild;
  final bool buildEnglish;
  final Map<String, dynamic> currSentence;
  final Function(Widget) setCheckAnswerWidget;
  const _SentenceGameMain({Key? key, required this.callback, required this.constraints, required this.words, required this.alreadyBuiltSentence, required this.sentenceToBuild, required this.buildEnglish, required this.currSentence, required this.setCheckAnswerWidget}) : super(key: key);

  @override
  State<_SentenceGameMain> createState() => _SentenceGameMainState();
}

class _SentenceGameMainState extends State<_SentenceGameMain> {
  double fontSize = 20;
  List<_WordCord> wordCords = [];
  List<int> rowStartIndex = [0];
  List<double> bottomLength = [];
  double screenWidth = 0;
  List<int> onTop = [];
  List<int> rows = [];
  List<double> topLength = [0];
  bool init = false;
  double totalLength = 0;
  double padding = 20;
  int numRows = 1;
  double textHeight = 25;
  List<double> topHeights = [-1];
  final player = AudioPlayer();
  bool isNotAnswered = true;
  late bool isCorrect;

  @override
  void initState() {
    super.initState();
    setLanguage();
    if(!widget.buildEnglish){
      speak(widget.sentenceToBuild);
    }
    bool debug = Preferences.getPreference("debug");
    if (!debug) widget.words.shuffle();
    screenWidth = widget.constraints.maxWidth;
  }

  FlutterTts flutterTts = FlutterTts();
  setLanguage() async{
    await flutterTts.setLanguage("zh-CN");
  }
  Future speak(String text) async{
    await flutterTts.speak(text);
  }

  Function() changeRow(int index,) {
    return () {
      if (onTop.contains(index)) {
        _WordCord currentWord = wordCords[index];
        int start = onTop.indexOf(index);
        int currRow = rows[start];
        bool completed = false;
        onTop.remove(index);
        rows.removeAt(start);
        double width = currentWord.size;
        topLength[currRow] -= width;
        setState(() {
          currentWord.x = currentWord.initialX;
          currentWord.y = currentWord.initialY;
        });
        bool newWidth = true;
        int i = start;
        // i here starts from the clicked word
        while (i < onTop.length && !completed) {
          int currIndex = onTop[i];
          if (currRow == rows[i]) {
            setState(() {
              wordCords[currIndex].x -= 2 * width / screenWidth;
            });
          } else if (wordCords[currIndex].size + topLength[currRow] < screenWidth) {
            if (newWidth) {
              width = 0;
              newWidth = false;
            }
            setState(() {
              wordCords[currIndex].x  = -1 + (2 * topLength[currRow] / screenWidth);
              wordCords[currIndex].y  = topHeights[currRow];
            });
            rows[i] -= 1;
            width += wordCords[currIndex].size;
            topLength[currRow] += wordCords[currIndex].size;
            topLength[currRow + 1] -= wordCords[currIndex].size;
            if (currRow + 1 == topLength.length - 1 &&
              topLength[currRow + 1] == 0) {
              topLength.removeAt(topLength.length - 1);
              topHeights.removeAt(topHeights.length - 1);
            }
            if (onTop[i] == onTop.last) {
              completed = true;
            } else if (wordCords[onTop[i + 1]].size + topLength[currRow] >= screenWidth) {
              currRow++;
              newWidth = true;
            }
          } else {
            completed = true;
          }
          i++;
        }
      } else {
        if(!widget.buildEnglish){
          String word = widget.words[index];
          List<String> specialChars = [",", " ,", ", ", " , ", "，", " ，", " ，", " ， ", " 、", " 、", " , "];
          if(!specialChars.contains(word)){
            speak(widget.words[index]);
          }
        }
        onTop.add(index);
        if (topLength.last + wordCords[index].size > screenWidth) {
          topLength.add(0);
          topHeights.add(
              topHeights.last + 4 * textHeight / widget.constraints.maxHeight);
          setState(() {
            wordCords[index].y = topHeights.last;
            wordCords[index].x = -1 + 2 * topLength.last / screenWidth;
          });
        } else {
          setState(() {
            wordCords[index].y = topHeights.last;
            wordCords[index].x = -1 + 2 * topLength.last / screenWidth;
          });
        }
        rows.add(topLength.length - 1);
        topLength.last += wordCords[index].size;
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    buildWidths();
    int index = -1;
    List<Widget> stackWidget = [];
    buildWordCords(index, stackWidget);
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Stack(
              children: stackWidget
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
              bottom: 8.0, top: 15.0, left: 30.0, right: 30.0),
          child: Row(
            children: [
              Flexible(
                fit: FlexFit.tight,
                child: TextButton(
                    onPressed: () async {
                      if(isNotAnswered){
                        List<String> topWords = [];
                        for (int i = 0; i < onTop.length; i++) {
                          topWords.add(widget.words[onTop[i]]);
                        }
                        if (topWords.join(" ") == widget.sentenceToBuild || topWords.join("") == widget.sentenceToBuild.replaceAll(" ", "")) {
                          isCorrect = true;
                          void callback(){
                            widget.callback(true, widget.currSentence, widget.buildEnglish);
                          }
                          setState(() {
                            isNotAnswered = false;
                            widget.setCheckAnswerWidget(
                                _CheckAnswerDialog(callback: callback, correctSentence: widget.sentenceToBuild, constraints: widget.constraints, isCorrect: isCorrect)
                            );
                          });
                          await player.setAsset('assets/correct.wav');
                          player.play();
                          //player.play(AssetSource('correct.wav'));
                          //player.release();
                        } else {
                          isCorrect = false;
                          await player.setAsset('assets/wrong.wav');
                          player.play();
                          //player.play(AssetSource('wrong.wav'));
                          //player.release();
                          void callback (){
                            widget.callback(false, widget.currSentence, widget.buildEnglish);
                          }
                          setState(() {
                            isNotAnswered = false;
                            widget.setCheckAnswerWidget(
                                _CheckAnswerDialog(callback: callback, correctSentence: widget.sentenceToBuild, constraints: widget.constraints, isCorrect: isCorrect,)
                            );
                          });
                        }
                      }else{
                        widget.callback(isCorrect, widget.currSentence, widget.buildEnglish);
                      }
                    },
                    child: isNotAnswered ? const Text("check answer") : const Text("continue")),
              ),
            ],
          ),
        )
      ],
    );
  }

  void buildWidths() {
    if (init == false) {
      double currRowLength = 0;
      List<double> middleOffset = [];
      List<double> wordSizes = [];
      for (int i = 0; i < widget.words.length; i++) {
        final Size size = (TextPainter(
            text: TextSpan(
                text: widget.words[i],
                style: TextStyle(fontSize: fontSize)),
            maxLines: 1,
            textScaleFactor: MediaQuery.of(context).textScaleFactor,
            textDirection: TextDirection.ltr)
          ..layout())
            .size;
        double sizeWithPadding = size.width + padding;
        wordSizes.add(sizeWithPadding);
        totalLength += sizeWithPadding;
        double lastSize = currRowLength;
        currRowLength += sizeWithPadding;
        if (currRowLength > screenWidth) {
          numRows++;
          middleOffset.add(lastSize / screenWidth);
          currRowLength = sizeWithPadding;
          bottomLength.add(0);
          rowStartIndex.add(i);
        }
        if (i == widget.words.length - 1) {
          middleOffset.add(currRowLength / screenWidth);
          bottomLength.add(0);
        }
      }
      for (int i = 0; i < numRows; i++) {
        int until;
        if (i == numRows - 1) {
          until = widget.words.length;
        } else {
          until = rowStartIndex[i + 1];
        }
        for (int j = rowStartIndex[i]; j < until; j++) {
          double normalizedHeight =
              i * 4 * textHeight / widget.constraints.maxHeight;
          double normalizedWidth = 2 * bottomLength[i] / screenWidth;
          double xCord = 0 - middleOffset[i] + normalizedWidth;
          double yCord = 1 - normalizedHeight;
          bottomLength[i] += wordSizes[j];
          wordCords.add(_WordCord(x: xCord, y: yCord, size: wordSizes[j], initialX: xCord, initialY: yCord));
        }
      }
      init = true;
    }
  }

  void buildWordCords(int index, List<Widget> stackWidget) {
    for (int i = 0; i < wordCords.length; i++) {
      index++;
      stackWidget.add(FixedAnimatedAlign(
          alignment: Alignment(wordCords[i].x, wordCords[i].y),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          child: GestureDetector(
              onTap: changeRow(i),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: padding / 4),
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: padding / 4, vertical: padding / 4),
                  decoration: BoxDecoration(
                    color: Colors.lightBlueAccent,
                    borderRadius: const BorderRadius.all(Radius.circular(3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 1,
                        blurRadius: 2,
                        offset: const Offset(0, 3), // changes position of shadow
                      ),
                    ],
                  ),
                  //color: Colors.grey,
                  child: Text(widget.words[index], style: TextStyle(fontSize: fontSize)),
                ),
              )
          )
      )
      );}
  }
}

class CheckAnswerBottomSheet extends StatelessWidget {
  final Function callback;
  final String correctSentence;
  final double height;
  const CheckAnswerBottomSheet({super.key, required this.callback, required this.correctSentence, required this.height,});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      maxChildSize: 0.5,
      minChildSize: 0.05,
      shouldCloseOnMinExtent: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20),),
            color: Colors.blue
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Container(
                    height: 5,
                    width: 30,
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [Text(correctSentence, style: const TextStyle(fontSize: 20),),],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    color: Colors.white,
                    child: TextButton(
                      //style: Styles.createButton(const Color(0xFFD9EAFD)),
                      onPressed: (){callback();},
                      child: const Text("continue"),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CheckAnswerDialog extends StatefulWidget {
  final Function callback;
  final String correctSentence;
  final BoxConstraints constraints;
  final bool isCorrect;
  const _CheckAnswerDialog({required this.callback, required this.correctSentence, required this.constraints, required this.isCorrect,});

  @override
  State<_CheckAnswerDialog> createState() => _CheckAnswerDialogState();
}

class _CheckAnswerDialogState extends State<_CheckAnswerDialog> {
  late double dx;
  late double dy;

  @override
  void initState() {
    dx = 0.0;
    dy = widget.constraints.maxHeight/2;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: dx,
      top: dy,
      width: widget.constraints.maxWidth,
      child: GestureDetector(
        onPanUpdate: (DragUpdateDetails details){
          setState(() {
            dx += details.delta.dx;
            dy += details.delta.dy;
          });
        },
        child: FractionallySizedBox(
          widthFactor: 0.75,
          child: Container(
              decoration:  BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                color: widget.isCorrect? Colors.blue : Colors.red,
              ),
              clipBehavior: Clip.none,
              padding: const EdgeInsets.only(top: 10.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40, left: 3.0),
                    child: Text(
                      widget.correctSentence,
                      style: const TextStyle(fontSize: 20),
                      maxLines: 2,
                    ),
                  ),
                  Container(
                    clipBehavior: Clip.none,
                    decoration:  BoxDecoration(
                      color: Colors.white,
                      borderRadius:  const BorderRadius.vertical(bottom: Radius.circular(20)),
                      boxShadow: [BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 3,
                        blurRadius: 5,
                        offset: const Offset(0, 3), // changes position of shadow
                      ),],
                    ),
                    alignment: Alignment.bottomCenter,
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Flexible(
                          fit: FlexFit.tight,
                          child: TextButton(
                            onPressed: (){widget.callback();},
                            child: const Text("continue", style: TextStyle(fontSize: 18),)
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ),
      ),
    );
  }
}


class _WordCord{
  final double initialX;
  final double initialY;
  final double size;
  double x;
  double y;
  _WordCord({
    required this.x,
    required this.y,
    required this.size,
    required this.initialX,
    required this.initialY,
  });
}

