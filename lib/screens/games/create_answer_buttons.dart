import 'dart:math';

//import 'package:audioplayers/audioplayers.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../settings/preferences.dart';
import '../../utils/styles.dart';

class AnswersList extends StatefulWidget {
  final Map<String, dynamic> currWord;
  final List<Map<String, dynamic>> groupWords;
  final String type;
  final Function(bool value, Map<String, dynamic> currWord, Type gameType) callback;
  final int index;
  final Type gameType;
  const AnswersList({super.key, required this.currWord, required this.groupWords, required this.type, required this.callback, required this.index, required this.gameType});

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
                  widget.callback(isCorrect,  widget.currWord, widget.gameType);
                });
              }
            },
            child: Text(
              buttonSelectionWords[i][widget.type],
              style: const TextStyle(fontSize: 18),
            ));
      }),
    );
  }
}
