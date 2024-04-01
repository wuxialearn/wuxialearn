import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../sql/sql_helper.dart';
import 'matching_game.dart';
import 'multiple_choice_game.dart';
import 'sentence_game.dart';

class UnitGame extends StatefulWidget {
  final List<Map<String, dynamic>> hskList;
  final List<Map<String, dynamic>> sentenceList;
  final int unit;
  final int subunit;
  final bool lastSubunit;
  final String name;
  final Function updateUnits;
  const UnitGame({Key? key, required this.hskList, required  this.sentenceList, required this.unit, required this.subunit, required this.lastSubunit, required this.name, required this.updateUnits}) : super(key: key);

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
    final groupNum = min(widget.hskList.length, 5);
    for(int i = 0; i <(widget.hskList.length ~/ groupNum); i++){
      createGamesListForGroup(
          widget.hskList.sublist(i*groupNum, min((i*groupNum)+groupNum, widget.hskList.length)),
          widget.sentenceList.sublist(i*groupNum, min((i*groupNum)+groupNum, widget.sentenceList.length))
      );
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

  void updateShowPinyin({required bool showPinyin}){
    setState(() {
      this.showPinyin = showPinyin;
    });
  }

  void callback(bool value, Map<String, dynamic> currWord, bool? chineseToEnglish) async {
    if(widget.unit > 0 && chineseToEnglish != null) {
      SQLHelper.insertStat(value: value?1:0, id: currWord["id"]);
    }
    if(value == false){
      setState(() {
        gamesList.add(ChineseToEnglishGame(chineseToEnglish: chineseToEnglish, currWord: currWord, groupWords: widget.hskList, callback: callback, index: gameIndex, showPinyin: showPinyin, updateShowPinyin : updateShowPinyin));
      });
    }
    updatePage();
  }
  void sentenceGameCallBack(bool value, Map<String, dynamic> currSentence, bool buildEnglish){
    if(!value){
      setState(() {
        gamesList.add(SentenceGame(callback: sentenceGameCallBack, currSentence: currSentence, buildEnglish: buildEnglish, index: gameIndex,));
      });
    }
    updatePage();
  }
  void updatePage(){
    bool lastPage = gameIndex+1 == gamesList.length;
    if(lastPage){
      if (widget.lastSubunit){
        SQLHelper.completeUnit(unit:  widget.unit);
      }
      SQLHelper.completeSubUnit(unit: widget.unit, subUnit: widget.subunit);
      //here is where we update the values for the other units
      widget.updateUnits();
      Navigator.pop(context);
    }else{
      _pageController.animateToPage(gameIndex+1, duration: const Duration(milliseconds: 300), curve: Curves.linear);
      gameIndex++;
    }
  }
  void createGamesListForGroup(List<Map<String, dynamic>> hskList, List<Map<String, dynamic>> sentenceList){
    for (int i = 0; i< hskList.length; i++){
      if(i%2==0){
        gamesList.add(ChineseToEnglishGame(chineseToEnglish: false, currWord: hskList[i], groupWords: hskList, callback: callback, index: gameIndex, showPinyin: showPinyin, updateShowPinyin: updateShowPinyin,));
      }else{
        gamesList.add(ChineseToEnglishGame(chineseToEnglish: true, currWord: hskList[i], groupWords: hskList, callback: callback, index: gameIndex, showPinyin: showPinyin, updateShowPinyin: updateShowPinyin));
      }
    }
    gamesList.add(MatchingGame(groupWords: hskList, callback: callback,));
    for(int i =0; i < sentenceList.length; i++){
      if(i%2==0){
        gamesList.add(SentenceGame(callback: sentenceGameCallBack, currSentence: sentenceList[i], index: gameIndex, buildEnglish: true));
      }else{
        gamesList.add(SentenceGame(callback: sentenceGameCallBack, currSentence: sentenceList[i], index: gameIndex, buildEnglish: false));
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
            }
        );
      },
    );
  }
}
