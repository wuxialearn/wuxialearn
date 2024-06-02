import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hsk_learner/data_model/word_item.dart';
import 'package:hsk_learner/utils/delayed_progress_indecator.dart';
import 'package:hsk_learner/utils/larg_text.dart';
import 'package:hsk_learner/utils/prototype.dart';

class HskListview extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> hskList;
  final bool showTranslation;
  final bool connectTop;
  final Color color;
  final Axis scrollAxis;
  final bool showPlayButton;
  final Widget emptyListMessage;
  final bool showPinyin;
  const HskListview({
    Key? key,
    required  this.hskList,
    required this.showTranslation,
    required this.connectTop,
    required this.color,
    required this.scrollAxis,
    this.showPlayButton = true,
    this.emptyListMessage = const Text(""),
    required this.showPinyin
  }) : super(key: key);

  get flutterTts => null;
  
  @override
  Widget build(BuildContext context) {
    FlutterTts flutterTts = FlutterTts();
    setLanguage() async{
      await flutterTts.setLanguage("zh-CN");
    }
    setLanguage();
    Future speak(String text) async{
      //await flutterTts.setLanguage("zh-CN");
      var result = await flutterTts.speak(text);
      //if (result == 1) setState(() => ttsState = TtsState.playing);
    }
    playCallback(String str){
      speak(str);
    }
    switch(scrollAxis){
      case Axis.vertical:
        return FutureBuilder<List<Map<String, dynamic>>>(
            future: hskList,
            builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
              if (snapshot.hasData) {
                final wordList = createWordList(snapshot.data!);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: connectTop?
                        const BorderRadius.vertical(bottom: Radius.circular(10))
                            :BorderRadius.circular(10),
                        color:color,
                      ),
                      child:
                          wordList.isEmpty? emptyListMessage:
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ListView.builder(
                              physics: const ScrollPhysics(),
                              padding: EdgeInsets.zero,
                              scrollDirection: scrollAxis,
                              itemCount: wordList.length,
                              itemBuilder: (context, index) {
                                return HskListviewItem(wordItem: wordList[index], showTranslation: showTranslation, separator: true, callback: playCallback, showPlayButton: showPlayButton, showPinyin: showPinyin);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              else{return const Center(child: DelayedProgressIndicator());}
            }
        );
      case Axis.horizontal:
        final wordMap = WordItem(LargeText.hskMap);
        return PrototypeHeight(
          backgroundColor: Colors.transparent,
          prototype: PrototypeHorizontalHskListView(connectTop: connectTop, color: color, wordItem: wordMap, showTranslation: showTranslation, playCallback: playCallback, showPlayButton: showPlayButton, showPinyin: showPinyin,),
          child: FutureBuilder<List<Map<String, dynamic>>>(
              future: hskList,
              builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                if (snapshot.hasData) {
                  final wordList  = createWordList(snapshot.data!);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: connectTop?
                        const BorderRadius.vertical(bottom: Radius.circular(10))
                            :BorderRadius.circular(10),
                        color:color,
                      ),
                      child:
                      wordList.isEmpty? emptyListMessage:
                      ListView.builder(
                        physics: const ScrollPhysics(),
                        padding: EdgeInsets.zero,
                        scrollDirection: scrollAxis,
                        itemCount: wordList.length,
                        itemBuilder: (context, index) {
                          return HskListviewItem(
                              wordItem: wordList[index],
                              showTranslation: showTranslation,
                              separator: false,
                              callback: playCallback,
                              showPlayButton: showPlayButton,
                            showPinyin: showPinyin,
                          );
                        },
                      ),
                    ),
                  );
                }
                else{
                  return PrototypeHeight(
                    prototype: PrototypeHorizontalHskListView(connectTop: connectTop, color: color, wordItem: wordMap, showTranslation: showTranslation, playCallback: playCallback, showPlayButton: showPlayButton, showPinyin: showPinyin,),
                    child: Container(),
                  );
                }
              }
          ),
        );
    }
  }
}

class PrototypeHorizontalHskListView extends StatelessWidget {
  const PrototypeHorizontalHskListView({super.key, required this.connectTop, required this.color, required this.showTranslation, required this.playCallback, required this.showPlayButton, required this.wordItem, required this.showPinyin});
  final bool connectTop;
  final Color color;
  final WordItem wordItem;
  final bool showTranslation;
  final Function(String) playCallback;
  final bool showPlayButton;
  final bool showPinyin;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0,), // this padding is needed fo some reason
      child: Container(
        decoration: BoxDecoration(
          borderRadius: connectTop?
          const BorderRadius.vertical(bottom: Radius.circular(10))
              :BorderRadius.circular(10),
          color:color,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HskListviewItem(wordItem: wordItem, showTranslation: showTranslation, separator: false, callback: playCallback, showPlayButton: showPlayButton, showPinyin: showPinyin,)
          ],
        ),
      ),
    );
  }
}


class HskListviewItem extends StatelessWidget {
  final WordItem wordItem;
  final bool showTranslation;
  final bool separator;
  final Function(String) callback;
  final bool showPlayButton;
  final bool showPinyin;
  const HskListviewItem({Key? key, required this.wordItem, required this.showTranslation, required this.separator, required this.callback, required this.showPlayButton, required  this.showPinyin,}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          //color: Colors.transparent,
          border: separator? const Border(bottom: BorderSide(width: 1.5, color: Color(0xFFECECEC)),)
          :const Border(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Visibility(
                      visible: showPinyin,
                      child: Text(
                        wordItem.pinyin,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      wordItem.hanzi,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 25),
                    ),
                  ]
                ),
                Visibility(
                  visible: showTranslation,
                  child: Text(
                    wordItem.translation,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF999999),
                    ),
                  ),
                )
              ],
            ),
            showPlayButton
              ? IconButton(
                onPressed: () {
                  callback(wordItem.hanzi,);
                },
                icon: const Icon(Icons.volume_up))
              : const SizedBox(height: 0,)
          ],
        ),
      ),
    );
  }
}
