import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:math';
import 'package:just_audio/just_audio.dart';
import '../settings/preferences.dart';
import '../../utils/styles.dart';

class ChineseToEnglishGame extends StatefulWidget {
  final Map<String, dynamic> currWord;
  final List<Map<String, dynamic>> groupWords;
  final Function(bool value, Map<String, dynamic> currWord, bool? chineseToEnglish) callback;
  final int index;
  final bool? chineseToEnglish;
  const ChineseToEnglishGame({Key? key, required  this.currWord, required  this.groupWords, required this.callback, required this.index, required this.chineseToEnglish}) : super(key: key);

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
  late String mapKey;
  @override
  void initState() {
    super.initState();
    mapKey = widget.chineseToEnglish!? "hanzi":"translations0";
    if(widget.chineseToEnglish!){
      speak(widget.currWord[mapKey]);
    }
  }

  @override
  Widget build(BuildContext context) {
    widget.groupWords.shuffle();
    return CupertinoPageScaffold(
      child: Column(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Visibility(
                  maintainState: true,
                  maintainSize: true,
                  maintainAnimation: true,
                  visible: false,
                  child: IconButton(
                      onPressed: () {
                        speak(widget.currWord[mapKey]);
                      },
                      icon: const Icon(Icons.volume_up)
                  ),
                ),
                Text(
                  widget.currWord[mapKey],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 35),
                ),
                Visibility(
                  maintainState: true,
                  maintainSize: true,
                  maintainAnimation: true,
                  visible: widget.chineseToEnglish!,
                  child: IconButton(
                      onPressed: () {
                        speak(widget.currWord[mapKey]);
                      },
                      icon: const Icon(Icons.volume_up)
                  ),
                ),
              ],
            )
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: AnswersList(chineseToEnglish: widget.chineseToEnglish!, currWord: widget.currWord, groupWords: widget.groupWords, callback: widget.callback, index: widget.index,),
          )
        ],
      ),
    );
  }
}


class AnswersList extends StatefulWidget {
  final Map<String, dynamic> currWord;
  final List<Map<String, dynamic>> groupWords;
  final Function(bool value, Map<String, dynamic> currWord, bool? chineseToEnglish) callback;
  final int index;
  final bool chineseToEnglish;
  const AnswersList({super.key, required this.currWord, required this.groupWords, required this.callback, required this.index, required this.chineseToEnglish});

  @override
  State<AnswersList> createState() => _AnswersListState();
}

class _AnswersListState extends State<AnswersList> {

  late List<Map<String, dynamic>> buttonSelectionWords;
  bool clicked = false;
  @override
  void initState() {
    super.initState();
    setLanguage();
    bool debug = Preferences.getPreference("debug");
    final groupWordsCopy = List.generate(widget.groupWords.length, (index) => widget.groupWords[index]);
    groupWordsCopy.removeWhere((element) => element["id"] == widget.currWord["id"]);
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
        if(buttonSelectionWords[i]["id"] == widget.currWord["id"]){
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
                  speak(buttonSelectionWords[i]["hanzi"]);
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
            child: Text(
              buttonSelectionWords[i][widget.chineseToEnglish? "translations0":"hanzi"],
              style: const TextStyle(fontSize: 18),
            ));
      }),
    );
  }
}


