import 'dart:math';
import 'package:flutter/material.dart';
import '../../sql/sql_helper.dart';
import '../games/multiple_choice_game.dart';


class TestOut extends StatefulWidget {
  final int hsk;
  const TestOut({super.key, required this.hsk});

  @override
  State<TestOut> createState() => _TestOutState();
}

class _TestOutState extends State<TestOut> {
  late Future<List<Map<String, dynamic>>> hskList;
  @override
  void initState() {
    hskList = SQLHelper.getTestOutWords(hsk: widget.hsk);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
        future: hskList,
        builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.hasData) {
            List<Map<String, dynamic>> hskList = snapshot.data!;
            return _TestOutController(hskList: hskList, hsk: widget.hsk,);
          }
          else{return const Center(child: CircularProgressIndicator());}
        }
    );
  }
}


class _TestOutController extends StatefulWidget {
  final List<Map<String, dynamic>> hskList;
  final int hsk;
  const _TestOutController({Key? key, required this.hskList, required this.hsk,}) : super(key: key);

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
  void callback(bool value, Map<String, dynamic> currWord, bool? empty) async {

    if(value == false){
      numIncorrect++;
    }
    if(numIncorrect == 2){
      setState(() {
        gamesList [gameIndex +1] = (
          Scaffold(
            body:  Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Center( child:  Text("Try Again")),
                Center(child: TextButton(onPressed: (){Navigator.pop(context);}, child: const Text("Close")))
              ],
            )
          )
        );
        _pageController.animateToPage(gameIndex+1, duration: const Duration(milliseconds: 300), curve: Curves.linear);
      });
    }else{
      updatePage();
    }
  }

  void updatePage(){
    bool lastPage = gameIndex+1 == gamesList.length;
    if(lastPage){
      SQLHelper.completeHSKLevel(widget.hsk);
      Navigator.pop(context);
    }else{
      _pageController.animateToPage(gameIndex+1, duration: const Duration(milliseconds: 300), curve: Curves.linear);
      gameIndex++;
    }
  }
  void updateShowPinyin({required bool showPinyin}){
    this.showPinyin = showPinyin;
  }
  void createGamesListForGroup(List<Map<String, dynamic>> hskList){
    for (int i = 0; i< hskList.length; i++){
      if(i%2==0){
        gamesList.add(ChineseToEnglishGame(chineseToEnglish: false, currWord: hskList[i], groupWords: hskList, callback: callback, index: gameIndex, showPinyin: showPinyin, updateShowPinyin: updateShowPinyin,));
      }else{
        gamesList.add(ChineseToEnglishGame(chineseToEnglish: true, currWord: hskList[i], groupWords: hskList, callback: callback, index: gameIndex, showPinyin: showPinyin, updateShowPinyin: updateShowPinyin,));
      }
    }
  }
  @override
  void initState() {
    super.initState();
    final groupNum = min(widget.hskList.length, 5);
    for(int i = 0; i <(widget.hskList.length ~/ groupNum); i++){
      createGamesListForGroup(
          widget.hskList.sublist(i*groupNum, min((i*groupNum)+groupNum, widget.hskList.length)),
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


