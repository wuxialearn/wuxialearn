import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hsk_learner/utils/delayed_progress_indecator.dart';

import '../../data_model/word_item.dart';
import '../../sql/sql_helper.dart';
import '../../utils/styles.dart';
import '../stats/word_view.dart';


class ManageReview extends StatefulWidget {
  const ManageReview({Key? key}) : super(key: key);

  @override
  State<ManageReview> createState() => _ManageReviewState();
}

class _ManageReviewState extends State<ManageReview> {

  late Future<List<Map<String, dynamic>>> statsListFuture;
  String sortValue = "Score";
  String orderValue = "Ascending";
  List<String> sortOptions = ["Score", "Last Seen", "Unit"];
  List<String> orderOption = ["Ascending", "Descending"];
  List<String> deckNames = ["Any", "hsk", "wuxia"];
  String deckName = 'hsk';
  @override
  initState() {
    super.initState();
    refresh();
  }

  Future<List<Map<String, dynamic>>> getManageReview({required String sortBy, required String orderBy, required String deck})  async {
    final data = await SQLHelper.getManageReview(sortBy: sortBy, orderBy: orderBy, deckSize: -1, deck: deck);
    return data;
  }

  void refresh(){
    String orderSQL = "ASC";
    String sortSQl = "unit";
    String deck = "where deck = '$deckName'";
    switch(orderValue){
      case "Ascending" : orderSQL = "ASC"; break;
      case "Descending": orderSQL = "DESC"; break;
    }
    switch(sortValue){
      case "Unit": sortSQl = "unit"; break;
      case "Score": sortSQl = "score"; break;
      case "Last Seen": sortSQl = "last_seen"; break;
    }
    switch(deckName){
      case "Any": deck = "where deck = 'any'"; break;
    }
    setState(() {
      statsListFuture = getManageReview(sortBy: sortSQl, orderBy: orderSQL, deck: deck);
    });
  }
  bool showRemove(){
    return deckName != "Any";
  }
  onClick(int id){
    List<String> options = [...deckNames];
    options.remove(deckName);
    if(showRemove()){
      SQLHelper.removeFromDeck(id: id, deck: deckName);
    }else{
      showCupertinoDialog(
          barrierDismissible: true,
          context: context,
          builder: (context) {
            return Dialog(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(10),
                ),
              ),
              backgroundColor: Colors.white,
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      children: List.generate(options.length, (index) {
                        return TextButton(
                            onPressed: (){
                              SQLHelper.addToReviewDeck(id: id, deck: options[index]);
                              Navigator.pop(context);
                            },
                            child: Text(options[index])
                        );
                      }),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          }
      );
      SQLHelper.addToReviewDeck(id: id, deck: "wuxia");
    }
    print(id);
    refresh();
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
              child: Wrap(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Deck:"),
                      TextButton(
                          onPressed: (){_showReviewDeckActionSheet(context);},
                          child: Text(deckName)
                      )
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Sort by:"),
                      TextButton(
                          onPressed: (){_showSortByActionSheet(context);},
                          child: Text(sortValue)
                      )
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Order By:"),
                      TextButton(
                          onPressed: (){_showOrderByActionSheet(context);},
                          child: Text(orderValue)
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        _HskListview(statsListFuture: statsListFuture, showTranslation: true, connectTop: true, color: Colors.transparent, scrollAxis: Axis.vertical, onClick: onClick, showRemove: showRemove(),)
      ],
    );
  }

  _showSortByActionSheet<bool>(BuildContext context) {
    showCupertinoModalPopup<bool>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Sort by'),
        actions:
        List<CupertinoActionSheetAction>.generate(sortOptions.length,(index){
          return CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context, true);
              setState(() {
                sortValue = sortOptions[index];
              });
              refresh();
            },
            child: Text(sortOptions[index]),
          );
        }),
      ),
    );
  }
  _showOrderByActionSheet<bool>(BuildContext context) {
    showCupertinoModalPopup<bool>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Order by'),
        actions:
        List<CupertinoActionSheetAction>.generate(orderOption.length,(index){
          return CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context, true);
              setState(() {
                orderValue = orderOption[index];
              });
              refresh();
            },
            child: Text(orderOption[index]),
          );
        }),
      ),
    );
  }
  _showReviewDeckActionSheet<bool>(BuildContext context) {
    showCupertinoModalPopup<bool>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Select a deck'),
        actions:
        List<CupertinoActionSheetAction>.generate(deckNames.length,(index){
          return CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context, true);
              setState(() {
                deckName = deckNames[index];
              });
              refresh();
            },
            child: Text(deckNames[index]),
          );
        }),
      ),
    );
  }
}


class _HskListview extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> statsListFuture;
  final bool showTranslation;
  final bool connectTop;
  final Color color;
  final Axis scrollAxis;
  final Function onClick;
  final bool showRemove;

  const _HskListview({Key? key, required  this.statsListFuture, required this.showTranslation, required this.connectTop, required this.color, required this.scrollAxis, required this.onClick, required this.showRemove}) : super(key: key);

  playCallback(int i){
    onClick(i);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
        future: statsListFuture,
        builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.hasData) {
            List<WordItem> wordList = createWordList(snapshot.data!);
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ListView.builder(
                            physics: const ScrollPhysics(),
                            padding: EdgeInsets.zero,
                            scrollDirection: scrollAxis,
                            itemCount: wordList.length,
                            itemBuilder: (context, index) {
                              return _HskListviewItem(wordItem: wordList[index], showTranslation: showTranslation, separator: true, callback: playCallback, showRemove: showRemove,);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
          else{return const Center(child: DelayedProgressIndicator());}
        }
    );
  }
}

class _HskListviewItem extends StatelessWidget {
  final WordItem wordItem;
  final bool showTranslation;
  final bool separator;
  final Function(int) callback;
  final bool showRemove;
  const _HskListviewItem({Key? key, required this.wordItem, required this.showTranslation, required this.separator, required this.callback, required this.showRemove,}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
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
                        wordItem.pinyin,
                        style: const TextStyle(fontSize: 14),
                      ),
                      TextButton(
                        style: Styles.blankButtonNoPadding,
                        onPressed: (){
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WordView(wordId: wordItem.id),
                            ),
                          );
                        },
                        child: Text(
                          wordItem.hanzi,
                          style: const TextStyle(fontSize: 25),
                        ),
                      ),
                    ]
                ),
                Visibility(
                  visible: showTranslation,
                  child: Text(
                    wordItem.translation,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF999EA3),
                    ),
                  ),
                )
              ],
            ),
            Row(
              children: [
                Visibility(
                  visible: showRemove,
                  child: IconButton(
                      onPressed: (){
                          callback(wordItem.id);
                      },
                      icon: const Icon(CupertinoIcons.minus_circle)
                  ),
                ),
                Visibility(
                  visible: !showRemove,
                  child: IconButton(
                      onPressed: (){
                        callback(wordItem.id);
                      },
                      icon: const Icon(CupertinoIcons.add)
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

