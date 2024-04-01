import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
                    List<Map<String, dynamic>>? hskList = snapshot.data;
                    int? hskLength = hskList?.length;
                    return Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: hskList?.length,
                                onPageChanged: (index) {
                                  if (index + 1 == hskList?.length) {
                                    lastPage = true;
                                  }
                                },
                                itemBuilder: (context, pageIndex) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                          child: FlashCard(
                                            showFrontSide: !wasClicked,
                                            front:
                                            Column(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Text(
                                                        hskList![pageIndex]["hanzi"],
                                                        style: const TextStyle(fontSize: 25, color: Colors.black),
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
                                                      Text(hskList[pageIndex]["hanzi"], style: const TextStyle(fontSize: 25, color: Colors.black),),
                                                      Text(hskList[pageIndex]["translations0"], style: const TextStyle(fontSize: 25, color: Colors.black),),
                                                   ]
                                                  ),
                                                ),
                                                _AnswerButton(callback: answerButtonCallBack(hskList[pageIndex]["id"]))
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
    return TextButton(
      style: Styles.blankButton2,
      onPressed: () => {
        callback(),
      },
      child: const Text("Show"),
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
        TextButton(onPressed: (){callback(false);}, child: const Icon(Icons.not_interested)),
        TextButton(onPressed: (){callback(true);}, child: const Icon(Icons.check))
      ],
    );
  }
}
