import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hsk_learner/data_model/word_item.dart';
import 'package:hsk_learner/sql/sql_helper.dart';
import '../../utils/styles.dart';
import 'flashcard.dart';
class ReviewFlashcards extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> hskList;
  final Function update;
  const ReviewFlashcards({Key? key, required this.hskList, required this.update}) : super(key: key);

  @override
  State<ReviewFlashcards> createState() => _ReviewFlashcardsState();
}

class _ReviewFlashcardsState extends State<ReviewFlashcards> {
  bool lastPage = false;
  bool wasClicked = false;
  bool showPinyin = true;
  bool showHint = false;
  bool showShowHint = false;
  final PageController _pageController = PageController(initialPage: 0);

  nextButtonCallback(){
    setState(() {
      wasClicked = true;
    });
  }

  answerButtonCallBack(int id) {
    return(int value){
      int stat = value == 0? 0:1;
      SQLHelper.insertStat(value: stat, id: id);
      DateTime dateTime = switch(value){
        0 => DateTime.now().add(const Duration(minutes: 1)),
        1 => DateTime.now().add(const Duration(minutes: 6)),
        2 => DateTime.now().add(const Duration(minutes: 10)),
        3 => DateTime.now().add(const Duration(days: 4)),
        _ => DateTime.now(),
      } ;
      final int time  = dateTime.toUtc().millisecondsSinceEpoch ~/ 1000;
      SQLHelper.updateReview(id: id, time: time);
      widget.update();
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
                future: widget.hskList,
                builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                  if (snapshot.hasData) {
                    List<WordItem> wordList = createWordList(snapshot.data!);
                    showShowHint = wordList[0].hanzi.length > 1;
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
                                    onPressed: (){
                                      setState(() {
                                        showHint = !showHint;
                                      });
                                    },
                                    child: showHint?
                                    const Text("Hide Hint")
                                        :const Text("Show Hint")
                                ),
                              ),
                              TextButton(
                                  onPressed: (){
                                    setState(() {
                                      showPinyin = !showPinyin;
                                    });
                                  },
                                  child: showPinyin?
                                    const Text("Hide Pinyin")
                                    :const Text("Show Pinyin")
                              ),
                            ],
                          ),
                          Expanded(
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: wordList.length,
                                onPageChanged: (index) {
                                  if (index + 1 == wordList.length) {
                                    lastPage = true;
                                  }
                                  setState(() {
                                    showShowHint = wordList[index].hanzi.length > 1;
                                  });
                                },
                                itemBuilder: (context, pageIndex) {
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
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Visibility(
                                                        visible: showPinyin,
                                                          child: Text(
                                                              wordList[pageIndex].pinyin,
                                                              style: const TextStyle(fontSize: 20, color: Colors.black54),
                                                          )
                                                      ),
                                                      Text(
                                                        wordList[pageIndex].hanzi,
                                                        style: const TextStyle(fontSize: 40, color: Colors.black),
                                                      ),
                                                      Visibility(
                                                          visible: showHint,
                                                          child: Text(
                                                            wordList[pageIndex].literal.join(" + "),
                                                            style: const TextStyle(fontSize: 20, color: Colors.black54),
                                                          )
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                               _ShowNextCardButton(callback: nextButtonCallback),
                                              ],
                                            ),
                                            back: Column(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Text(wordList[pageIndex].pinyin, style: const TextStyle(fontSize: 25, color: Colors.black),),
                                                      Text(wordList[pageIndex].hanzi, style: const TextStyle(fontSize: 40, color: Colors.black),),
                                                      Text(wordList[pageIndex].translation, style: const TextStyle(fontSize: 25, color: Colors.black),),
                                                      Visibility(
                                                          visible: showHint,
                                                          child: Text(
                                                            wordList[pageIndex].literal.join(" + "),
                                                            style: const TextStyle(fontSize: 20, color: Colors.black54),
                                                          )
                                                      ),
                                                   ]
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.all(15.0),
                                                  child: _AnswerButton(callback: answerButtonCallBack(wordList[pageIndex].id)),
                                                )
                                              ],
                                            )
                                          ),
                                      ),
                                    ],
                                  );
                                },
                              )
                          ),
                        ],
                      ),
                    );
                  }
                  else{return const Center(child: CircularProgressIndicator());}
                }
            ),
          ],
        ),
      ),
    );
  }
}

class _ShowNextCardButton extends StatelessWidget {
  final Function() callback;
  const _ShowNextCardButton({Key? key, required this.callback,}) : super(key: key);
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
  const _AnswerButton({Key? key, required this.callback,}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        TextButton(
          onPressed: (){callback(0);},
          child: const Column(
            children: [
              Text("< 1 min"),
              Text("Again")
            ],
          )
        ),
        TextButton(
            onPressed: (){callback(1);},
            child: const Column(
              children: [
                Text("< 6 min"),
                Text("Hard")
              ],
            )
        ),
        TextButton(
            onPressed: (){callback(2);},
            child: const Column(
              children: [
                Text("< 10 min"),
                Text("Good")
              ],
            )
        ),
        TextButton(
            onPressed: (){callback(3);},
            child: const Column(
              children: [
                Text("4 days"),
                Text("Easy")
              ],
            )
        ),
      ],
    );
  }
}
