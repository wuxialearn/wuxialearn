import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hsk_learner/utils/larg_text.dart';
import 'package:hsk_learner/utils/prototype.dart';

class HskListview extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> hskList;
  final bool showTranslation;
  final bool connectTop;
  final Color color;
  final Axis scrollAxis;
  final bool showPlayButton;
  const HskListview({Key? key, required  this.hskList, required this.showTranslation, required this.connectTop, required this.color, required this.scrollAxis, this.showPlayButton = true}) : super(key: key);

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
                List<Map<String, dynamic>>? hskList = snapshot.data;
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ListView.builder(
                              physics: const ScrollPhysics(),
                              padding: EdgeInsets.zero,
                              scrollDirection: scrollAxis,
                              itemCount: hskList!.length,
                              itemBuilder: (context, index) {
                                return HskListviewItem(hskList: hskList[index], showTranslation: showTranslation, separator: true, callback: playCallback, showPlayButton: showPlayButton);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              else{return const Center(child: CircularProgressIndicator());}
            }
        );
      case Axis.horizontal:
        Map<String, dynamic> hskMap = LargeText.hskMap;
        return PrototypeHeight(
          backgroundColor: Colors.transparent,
          prototype: PrototypeHorizontalHskListView(connectTop: connectTop, color: color, hskMap: hskMap, showTranslation: showTranslation, playCallback: playCallback, showPlayButton: showPlayButton,),
          child: FutureBuilder<List<Map<String, dynamic>>>(
              future: hskList,
              builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                if (snapshot.hasData) {
                  List<Map<String, dynamic>>? hskList = snapshot.data;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: connectTop?
                        const BorderRadius.vertical(bottom: Radius.circular(10))
                            :BorderRadius.circular(10),
                        color:color,
                      ),
                      child: ListView.builder(
                        physics: const ScrollPhysics(),
                        padding: EdgeInsets.zero,
                        scrollDirection: scrollAxis,
                        itemCount: hskList!.length,
                        itemBuilder: (context, index) {
                          return HskListviewItem(
                              hskList: hskList[index],
                              showTranslation: showTranslation,
                              separator: false,
                              callback: playCallback,
                              showPlayButton: showPlayButton,
                          );
                        },
                      ),
                    ),
                  );
                }
                else{
                  return PrototypeHeight(
                    prototype: PrototypeHorizontalHskListView(connectTop: connectTop, color: color, hskMap: hskMap, showTranslation: showTranslation, playCallback: playCallback, showPlayButton: showPlayButton,),
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
  const PrototypeHorizontalHskListView({super.key, required this.connectTop, required this.color, required this.hskMap, required this.showTranslation, required this.playCallback, required this.showPlayButton});
  final bool connectTop;
  final Color color;
  final Map<String, dynamic> hskMap;
  final bool showTranslation;
  final Function(String) playCallback;
  final bool showPlayButton;
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
            HskListviewItem(hskList: hskMap, showTranslation: showTranslation, separator: false, callback: playCallback, showPlayButton: showPlayButton,)
          ],
        ),
      ),
    );
  }
}


class HskListviewItem extends StatelessWidget {
  final Map<String, dynamic> hskList;
  final bool showTranslation;
  final bool separator;
  final Function(String) callback;
  final bool showPlayButton;
  const HskListviewItem({Key? key, required this.hskList, required this.showTranslation, required this.separator, required this.callback, required this.showPlayButton,}) : super(key: key);

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
                    Text(
                      hskList["pinyin"],
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      hskList["hanzi"],
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 25),
                    ),
                  ]
                ),
                Visibility(
                  visible: showTranslation,
                  child: Text(
                    hskList["translations0"],
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
                  callback(hskList["hanzi"],);
                },
                icon: const Icon(Icons.volume_up))
              : const SizedBox(height: 0,)
          ],
        ),
      ),
    );
  }
}