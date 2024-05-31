import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hsk_learner/screens/review/review_flashcards.dart';
import 'package:hsk_learner/screens/review/review_quiz.dart';
import 'package:hsk_learner/utils/collapsible.dart';
import 'package:hsk_learner/widgets/hsk_listview/hsk_listview.dart';
import '../../utils/size_transition.dart';
import '../../sql/sql_helper.dart';
import '../../utils/styles.dart';
import '../settings/preferences.dart';
import 'manage_review.dart';

class ReviewHome extends StatefulWidget {
  const ReviewHome({super.key});

  @override
  State<ReviewHome> createState() => _ReviewHomeState();
}

class _ReviewHomeState extends State<ReviewHome> {
  late PageController pageController;
  @override
  void initState() {
    pageController = PageController();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text("Review")
      ), 
      child:  SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CupertinoSlidingSegmentedControl(
                  onValueChanged: (int? value) {
                    setState(() {
                      pageController.animateToPage(
                          value!-1,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.ease
                      );
                    });
                  },
                  children: const <int, Widget>{
                    1: Text("Review"),
                    2: Text("Manage")
                  },
                ),
              ),
              Expanded(
                child: PageView(
                  controller: pageController,
                  children: const [
                    ReviewPage(),
                    ManageReview(),
                  ],
                ),
              ),
            ],
          )
      ),
    );
  }
}


class ReviewPage extends StatefulWidget {
  const ReviewPage({Key? key}) : super(key: key);
  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {

  late Future<List<Map<String, dynamic>>> hskList;
  late List<Future<List<Map<String, dynamic>>>> sentenceList;
  bool lastPage = false;
  bool hardWords = true;
  bool oldWords = false;
  bool randomWords = false;
  bool previewDeck = Preferences.getPreference("showTranslations");
  bool isCollapsed = true;
  bool deckExists = true;
  List<String> reviewTypeOptions = ["Flashcards","Quiz",];
  List<String> deckSizeOptions = ["Small", "Medium", "Large", "All"];
  List<String> deckNames = ["hsk", "wuxia"];
  String deckName = 'hsk';
  String reviewTypeValue = "Flashcards";
  String deckSizeValue = "Small";
  final PageController _pageController = PageController(initialPage: 0);
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    hskList = getReview();
  }

  Future<List<Map<String, dynamic>>> getReview()  async {
    int numCards = -1;
    bool isAll = false;
    switch(deckSizeValue){
      case "Small": numCards = 10; break;
      case "Medium": numCards = 20; break;
      case "Large": numCards = 35; break;
      case "ALL": isAll = true; break;
    }
    late List<Map<String, dynamic>> hardWordsList =[];
    late List<Map<String, dynamic>> oldWordsList = [];
    if(hardWords || isAll) {
      hardWordsList = await SQLHelper.getReview(deckSize: numCards, sortBy: "score", orderBy: "ASC", deckName: deckName);
    }
    if(oldWords && !isAll){
      oldWordsList = await SQLHelper.getReview(deckSize: numCards, sortBy: "last_seen", orderBy: "ASC", deckName: deckName);
    }
    if(randomWords && !isAll){
      oldWordsList = await SQLHelper.getReview(deckSize: numCards, sortBy: "RANDOM()", orderBy: "ASC", deckName: deckName);
    }
    List<Map<String, dynamic>> reviewList = hardWordsList;
    List<int> idList = [];
    for (var element in reviewList) {
      idList.add(element["id"]);
    }
    for (var element in oldWordsList) {
      if(!idList.contains(element["id"])){
        reviewList.add(element);
      }
    }
    return reviewList;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Center(
        child: Column(
          mainAxisSize:  MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: deckExists ?
                  const BorderRadius.vertical(top: Radius.circular(10)):
                  BorderRadius.circular(10),
                color: Colors.white,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8.0,),
              child: Column(
                children: [
                  const SizedBox(height: 5,),
                  ShrinkWidget(
                    isCollapsed: isCollapsed,
                    child: CupertinoButton(
                      //style: Styles.blankButton3,
                      onPressed: () {
                        setState(() {
                          isCollapsed = false;
                        });
                      },
                      child: const Row(children:[Text("Review Options")]) ,
                    ),
                  ),
                  Collapsible(
                    duration: 1000,
                    isCollapsed: isCollapsed,
                    child: Column(
                    children: [
                      const SizedBox(height: 15,),
                      const Center(child: Text("Review Options"),),
                      const SizedBox(height: 25,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Show translations in preview"),
                          CupertinoSwitch(
                            // This bool value toggles the switch.
                            value: previewDeck,
                            activeColor: CupertinoColors.activeBlue,
                            onChanged: (bool? value) {
                              // This is called when the user toggles the switch.
                              setState(() {
                                previewDeck = value ?? false;
                              });
                            },
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Include difficult words"),
                          CupertinoSwitch(
                            // This bool value toggles the switch.
                            value: hardWords,
                            activeColor: CupertinoColors.activeBlue,
                            onChanged: (bool? value) {
                              // This is called when the user toggles the switch.
                              setState(() {
                                hardWords = value ?? false;
                              });
                            },
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Include old words"),
                          CupertinoSwitch(
                            // This bool value toggles the switch.
                            value: oldWords,
                            activeColor: CupertinoColors.activeBlue,
                            onChanged: (bool? value) {
                              // This is called when the user toggles the switch.
                              setState(() {
                                oldWords = value ?? false;
                              });
                            },
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Include random words"),
                          CupertinoSwitch(
                            // This bool value toggles the switch.
                            value: randomWords,
                            activeColor: CupertinoColors.activeBlue,
                            onChanged: (bool? value) {
                              // This is called when the user toggles the switch.
                              setState(() {
                                randomWords = value ?? false;
                              });
                            },
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Review type:"),
                          CupertinoButton(onPressed: (){ _showReviewTypeActionSheet(context);}, child: Text(reviewTypeValue), ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Deck size"),
                          CupertinoButton(onPressed: (){ _showReviewSizeActionSheet(context);}, child: Text(deckSizeValue), ),
                          //DropDown(dropdownOptions: deckSizeOptions, callback: (value) { deckSizeValue = value; })
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Deck"),
                          CupertinoButton(onPressed: (){ _showReviewDeckActionSheet(context);}, child: Text(deckName), ),
                          //DropDown(dropdownOptions: deckSizeOptions, callback: (value) { deckSizeValue = value; })
                        ],
                      ),
                      CupertinoButton(
                          onPressed: (){
                            setState(() {
                              hskList = getReview();
                              isCollapsed = true;
                              deckExists = true;
                            });
                          },
                          child: const Text("create deck")
                      ),
                    ],
                  ),
                  ),
                ],
              ),
            ),
            deckExists? HskListview(hskList: hskList, showTranslation: previewDeck, connectTop: true, color: Colors.white, scrollAxis: Axis.vertical,): const SizedBox(height: 0,),
            ShrinkWidget(
              //visible: isCollapsed,
              isCollapsed: isCollapsed,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
                child: Center(
                  child: TextButton(
                    style: Styles.blankButton4,
                    onPressed: (){
                      if (reviewTypeValue == "Quiz"){
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) => ReviewQuiz(hskList: hskList),
                        ),);
                      }else{
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) => ReviewFlashcards(hskList: hskList),
                        ),);
                      }
                    },
                    child: const Text("Review")
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  _showReviewTypeActionSheet<bool>(BuildContext context) {
    showCupertinoModalPopup<bool>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Select a review type course'),
        actions:
        List<CupertinoActionSheetAction>.generate(reviewTypeOptions.length,(index){
          return CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context, true);
              setState(() {
                reviewTypeValue = reviewTypeOptions[index];
              });
            },
            child: Text(reviewTypeOptions[index]),
          );
        }),
      ),
    );
  }

  _showReviewSizeActionSheet<bool>(BuildContext context) {
    showCupertinoModalPopup<bool>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Select a deck size'),
        actions:
        List<CupertinoActionSheetAction>.generate(deckSizeOptions.length,(index){
          return CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context, true);
              setState(() {
                deckSizeValue = deckSizeOptions[index];
              });
            },
            child: Text(deckSizeOptions[index]),
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
            },
            child: Text(deckNames[index]),
          );
        }),
      ),
    );
  }

}
