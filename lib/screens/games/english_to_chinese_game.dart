import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'create_answer_buttons.dart';

class EnglishToChineseGame extends StatefulWidget {
  final Map<String, dynamic> currWord;
  final List<Map<String, dynamic>> groupWords;
  final Function(bool value, Map<String, dynamic> currWord, Type gameType) callback;
  final int index;
  const EnglishToChineseGame({Key? key, required this.currWord, required this.groupWords, required this.callback, required this.index}) : super(key: key);

  @override
  State<EnglishToChineseGame> createState() => _EnglishToChineseGameState();
}

class _EnglishToChineseGameState extends State<EnglishToChineseGame> {
  @override
  Widget build(BuildContext context) {
    widget.groupWords.shuffle();
    return CupertinoPageScaffold(
      child: Column(
        children: [
          Expanded(
              child: Center(
                  child: Text(
                    widget.currWord["translations0"],
                    style: const TextStyle(fontSize: 35),
                  )
              )
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: AnswersList(currWord: widget.currWord, groupWords: widget.groupWords, type: "hanzi", callback: widget.callback, index: widget.index, gameType: widget.runtimeType),
          )
        ],
      ),
    );
  }
}
