import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hsk_learner/data_model/word_item.dart';
import 'package:hsk_learner/sql/sql_helper.dart';
import '../../utils/styles.dart';
import 'flashcard.dart';
class ReviewFlashcards extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> hskList;
  const ReviewFlashcards({Key? key, required this.hskList}) : super(key: key);

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
    return(bool value){
      int stat = value? 1:0;
      SQLHelper.insertStat(value: stat, id: id);
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
  final Function(bool value) callback;
  const _AnswerButton({Key? key, required this.callback,}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        IconButton(
          onPressed: (){callback(false);},
          icon: const Icon(Icons.not_interested),
          iconSize: 30,
        ),
        IconButton(
          onPressed: (){callback(true);},
          icon: const Icon(Icons.check),
          iconSize: 30,
        )
      ],
    );
  }
}
