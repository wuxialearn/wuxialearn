import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hsk_learner/screens/courses/course_home.dart';
import 'package:hsk_learner/screens/review/review_home.dart';
import 'package:hsk_learner/screens/settings/settings.dart';
import '../games/sentence_game.dart';
import '../stats/stats_home.dart';

class MyHomePage extends StatefulWidget {
  final int tab;
  const MyHomePage({super.key, required this.tab});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage>{

  onTappedTab(int index) {
    setState(() {tabsIndex = index;});
  }
  int tabsIndex = 4;
  late List<Widget> tabList = <Widget>[];
  DateTime lastBackPress = DateTime.utc(1960);
  void stats() async{
  }
  @override
  void initState() {
    stats();
    super.initState();
    tabsIndex = widget.tab;
    tabList = <Widget>[
      const CourseHome(),
      const ReviewPage(),
      const StatsHome(),
      const Settings(),
      //const WordView(wordId: 3)
      SentenceGame(callback: sentenceGameCallBack, currSentence: currSentence(), index: 0, buildEnglish: false)
    ];
  }
  void sentenceGameCallBack(bool value, Map<String, dynamic> currSentence, bool buildEnglish){
  }
  Map<String, dynamic> currSentence(){
    //return  {"characters": "她叫什么名字", "pinyin": "tā jiào shénme míngzì", "meaning": "what's her name"};
    //return {"characters": "我的弟弟想长高", "pinyin": "Wǒ de dìdi xiǎng zhǎng gāo", "meaning": "my younger brother wants to grow taller",};
    return {
      "characters": "我 爱 我 的 国家，它 有 很多 美丽 的 河流 和 公园",
      "pinyin": "wǒ ài wǒ de guójiā, tā yǒu hěnduō měilì de héliú hé gōngyuán",
      "meaning": "I love my country, it has many beautiful rivers and parks and more words"
    };
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (tabsIndex != 0){
          onTappedTab(0);
          return false;
        }else{
          final timestamp = DateTime.timestamp();
          var timeSinceLastPress = timestamp.difference(lastBackPress).inMilliseconds;
          lastBackPress = timestamp;
          if (timeSinceLastPress > 0 && timeSinceLastPress < 300){
            return true;
          }else{
            return false;
          }
        }
      },
      child: CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          backgroundColor: Colors.white,
          currentIndex: tabsIndex,
          //border: Border.all(color: Colors.white),
          onTap: onTappedTab,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.auto_stories), label: "Review"),
            BottomNavigationBarItem(icon: Icon(Icons.query_stats_sharp), label: "Stats"),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
            BottomNavigationBarItem(icon: Icon(Icons.construction), label: "testing"),
          ],
        ),
        tabBuilder: (BuildContext context, int index) { 
          return tabList[tabsIndex];
        },
      ),
    );
  }
}