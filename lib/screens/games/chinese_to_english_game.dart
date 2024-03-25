import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'create_answer_buttons.dart';

class ChineseToEnglishGame extends StatefulWidget {
  final Map<String, dynamic> currWord;
  final List<Map<String, dynamic>> groupWords;
  final Function(bool value, Map<String, dynamic> currWord, Type gameType) callback;
  final int index;
  const ChineseToEnglishGame({Key? key, required  this.currWord, required  this.groupWords, required this.callback, required this.index}) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    speak(widget.currWord["hanzi"]);
  }

  @override
  Widget build(BuildContext context) {
    widget.groupWords.shuffle();
    return CupertinoPageScaffold(
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Text(
                widget.currWord["hanzi"],
                style: const TextStyle(fontSize: 35),
              )
            )
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: AnswersList(currWord: widget.currWord, groupWords: widget.groupWords, type: "translations0", callback: widget.callback, index: widget.index, gameType: widget.runtimeType),
          )
        ],
      ),
    );
  }
}

