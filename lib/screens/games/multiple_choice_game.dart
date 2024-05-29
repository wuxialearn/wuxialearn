import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hsk_learner/data_model/word_item.dart';
import 'package:hsk_learner/screens/games/unit_game.dart';
import 'dart:math';
import 'package:just_audio/just_audio.dart';
import '../settings/preferences.dart';
import '../../utils/styles.dart';

class ChineseToEnglishGame extends StatefulWidget {
  final WordItem currWord;
  final List<WordItem> wordList;
  final Function(bool value, WordItem currWord, bool? chineseToEnglish) callback;
  final int index;
  final bool? chineseToEnglish;
  const ChineseToEnglishGame({Key? key, required  this.currWord, required  this.wordList, required this.callback, required this.index, required this.chineseToEnglish}) : super(key: key);

  @override
  State<ChineseToEnglishGame> createState() => _ChineseToEnglishGameState();
}
class _ChineseToEnglishGameState extends State<ChineseToEnglishGame> {


  FlutterTts flutterTts = FlutterTts();
  setLanguage() async{
    await flutterTts.setLanguage("zh-CN");
  }
  Future speak(String text) async{
    await flutterTts.speak(text);
  }
  late final String wordToTranslate;
  late bool showPinyin;
  @override
  void initState() {
    super.initState();
    showPinyin = ShowPinyin.showPinyin;
    wordToTranslate = widget.chineseToEnglish!?
    widget.currWord.hanzi: widget.currWord.translation;
    if(widget.chineseToEnglish!){
      speak(wordToTranslate);
    }
  }

  @override
  Widget build(BuildContext context) {
    widget.wordList.shuffle();
    return CupertinoPageScaffold(
      child: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: (){
                      setState(() {
                        showPinyin = !showPinyin;
                        ShowPinyin.showPinyin = showPinyin;
                      });
                    },
                    child: showPinyin
                        ? const Text("Hide Pinyin")
                        : const Text("Show Pinyin")
                )
              ],
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Visibility(
                      visible: widget.chineseToEnglish! && showPinyin,
                      child: Text(
                        widget.currWord.pinyin,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20),
                      )
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Visibility(
                        maintainState: true,
                        maintainSize: true,
                        maintainAnimation: true,
                        visible: false,
                        child: IconButton(
                            onPressed: () {
                              speak(wordToTranslate);
                            },
                            icon: const Icon(Icons.volume_up)
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal:  3.0),
                        child: Text(
                          wordToTranslate,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 35),
                        ),
                      ),
                      Visibility(
                        maintainState: true,
                        maintainSize: true,
                        maintainAnimation: true,
                        visible: widget.chineseToEnglish!,
                        child: IconButton(
                            onPressed: () {
                              speak(wordToTranslate);
                            },
                            icon: const Icon(Icons.volume_up)
                        ),
                      ),
                    ],
                  ),
                ],
              )
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: AnswersList(chineseToEnglish: widget.chineseToEnglish!, currWord: widget.currWord, wordList: widget.wordList, callback: widget.callback, index: widget.index, showPinyin: showPinyin),
            )
          ],
        ),
      ),
    );
  }
}


class AnswersList extends StatefulWidget {
  final WordItem currWord;
  final List<WordItem> wordList;
  final Function(bool value, WordItem currWord, bool? chineseToEnglish) callback;
  final int index;
  final bool chineseToEnglish;
  final bool showPinyin;
  const AnswersList({super.key, required this.currWord, required this.wordList, required this.callback, required this.index, required this.chineseToEnglish, required this.showPinyin});

  @override
  State<AnswersList> createState() => _AnswersListState();
}

class _AnswersListState extends State<AnswersList> {

  late List<WordItem> buttonSelectionWords;
  bool clicked = false;
  @override
  void initState() {
    super.initState();
    setLanguage();
    bool debug = Preferences.getPreference("debug");
    final groupWordsCopy = List.generate(widget.wordList.length, (index) => widget.wordList[index]);
    groupWordsCopy.removeWhere((element) => element.id == widget.currWord.id);
    groupWordsCopy.shuffle();
    buttonSelectionWords = List.generate(min(groupWordsCopy.length, 4), (index) => groupWordsCopy[index]);
    buttonSelectionWords.insert(0, widget.currWord);
    if(!debug)buttonSelectionWords.shuffle();
    colorsList = List.generate(buttonSelectionWords.length, (int index) => const Color(0xFFEEEEEE));
  }

  final player = AudioPlayer();
  FlutterTts flutterTts = FlutterTts();
  setLanguage() async{
    await flutterTts.setLanguage("zh-CN");
  }
  Future speak(String text) async{
    await flutterTts.awaitSpeakCompletion(true);
    await flutterTts.speak(text);
  }
  late List<Color> colorsList;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List<Widget>.generate(buttonSelectionWords.length, (int i) {
        bool isCorrect;
        if(buttonSelectionWords[i].id == widget.currWord.id){
          isCorrect = true;
        }else{
          isCorrect = false;
        }
        return TextButton(
            style: Styles.createButton(colorsList[i]),
            onPressed: () async {
              if(!clicked){
                setState(() {
                  clicked = true;
                });
                if(isCorrect) {
                  setState(() {
                    colorsList[i] = const Color(0xFF00FF00);
                  });
                  try{
                    //await player.play(AssetSource('correct.wav'));
                    await player.setAsset('assets/correct.wav');
                    await player.load();
                    player.play();
                  }catch(e){
                    print(e);
                  }
                  speak(buttonSelectionWords[i].hanzi);
                }else{
                  setState(() {
                    colorsList[i] = const Color(0xFFFF0000);
                  });
                  await player.setAsset('assets/wrong.wav');
                  await player.load();
                  player.play();
                  //await player.play(AssetSource('wrong.wav'));
                }
                Future.delayed(const Duration(milliseconds: 500), () {
                  widget.callback(isCorrect,  widget.currWord, widget.chineseToEnglish);
                });
              }
            },
            child: Column(
              children: [
                Visibility(
                  visible: widget.showPinyin && !widget.chineseToEnglish,
                  child: Text(buttonSelectionWords[i].pinyin)
                ),
                Text(
                  widget.chineseToEnglish?
                      buttonSelectionWords[i].translation
                    : buttonSelectionWords[i].hanzi,
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ));
      }),
    );
  }
}


