import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hsk_learner/data_model/review_rating.dart';
import 'package:hsk_learner/screens/review/review_flashcards.dart';
import 'package:hsk_learner/screens/review/review_progress.dart';
import 'package:hsk_learner/screens/review/review_quiz.dart';
import 'package:hsk_learner/widgets/collapsible.dart';
import 'package:hsk_learner/widgets/delayed_progress_indecator.dart';
import 'package:hsk_learner/widgets/hsk_listview/hsk_listview.dart';
import '../../sql/review_sql.dart';
import '../../widgets/size_transition.dart';
import '../../utils/styles.dart';
import '../settings/preferences.dart';
import 'manage_ratings.dart';
import 'manage_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      navigationBar: const CupertinoNavigationBar(middle: Text("Review")),
      child: SafeArea(
          child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CupertinoSlidingSegmentedControl(
              onValueChanged: (int? value) {
                setState(() {
                  pageController.animateToPage(value! - 1,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.ease);
                });
              },
              children: const <int, Widget>{
                1: Text("Review"),
                2: Text("Progress"),
                3: Text("Ratings"),
                4: Text("Decks"),
              },
            ),
          ),
          Expanded(
            child: PageView(
              controller: pageController,
              children: const [
                ReviewPage(),
                ReviewProgress(),
                ManageRatings(),
                ManageReview(),
              ],
            ),
          ),
        ],
      )),
    );
  }
}

class ReviewPage extends StatefulWidget {
  const ReviewPage({Key? key}) : super(key: key);
  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

const flashCardType = "Flashcards";
const quizType = "Quiz (ungraded)";

class _ReviewPageState extends State<ReviewPage> {
  late Future<List<Map<String, dynamic>>> hskList;
  late List<Future<List<Map<String, dynamic>>>> sentenceList;
  Future<List<Map<String, dynamic>>> reviewRatingFuture =
      ReviewSql.getReviewRatings();
  bool lastPage = false;
  int numCards = -1;
  bool previewDeck = Preferences.getPreference("showTranslations");
  bool showPinyin =
      Preferences.getPreference("show_pinyin_by_default_in_review");
  bool isCollapsed = true;
  bool deckExists = true;
  List<String> reviewWordsOptions = [
    "SRS",
    "random words",
    "difficult words",
    "old words",
    "uncategorized", // Added new option
  ];
  List<String> reviewTypeOptions = [
    flashCardType,
    quizType,
  ];
  List<String> deckSizeOptions = ["Small", "Medium", "Large", "All"];
  List<String> deckNames = ["hsk", "wuxia"];
  String deckName = 'hsk';
  String reviewTypeValue = flashCardType;
  String reviewWordsValue = "SRS";
  String deckSizeValue = "Small";
  final PageController _pageController = PageController(initialPage: 0);
  final SharedPreferences prefs = SharedPrefs.prefs;
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadReviewType();
    hskList = getReview();
  }

  void _loadReviewType() {
    setState(() {
      reviewTypeValue = prefs.getString('reviewType') ??
          flashCardType; // Default to Flashcards
      reviewWordsValue = prefs.getString('reviewWords') ?? 'SRS'; // Default to
      deckSizeValue =
          prefs.getString('deckSize') ?? 'Small'; // Default to Flashcards
      deckName = prefs.getString('deckName') ?? 'hsk'; // Default to Flashcards
    });
  }

  void update() {
    if (reviewWordsValue == "SRS") {
      setState(() {
        hskList = getReview();
      });
    }
  }

  Future<List<Map<String, dynamic>>> getReview() async {
    switch (deckSizeValue) {
      case "Small":
        numCards = 10;
        break;
      case "Medium":
        numCards = 20;
        break;
      case "Large":
        numCards = 35;
        break;
      case "All":
        numCards = -1;
        break;
    }
    List<Map<String, dynamic>> reviewList = [];
    switch (reviewWordsValue) {
      case "SRS":
        reviewList = await ReviewSql.getSrsReview(deckSize: numCards);
        break;
      case "random words":
        reviewList = await ReviewSql.getReview(
            deckSize: numCards,
            sortBy: "RANDOM()",
            orderBy: "ASC",
            deckName: deckName);
        break;
      case "difficult words":
        reviewList = await ReviewSql.getReview(
            deckSize: numCards,
            sortBy: "score",
            orderBy: "ASC",
            deckName: deckName);
        break;
      case "old words":
        reviewList = await ReviewSql.getReview(
            deckSize: numCards,
            sortBy: "last_seen",
            orderBy: "ASC",
            deckName: deckName);
        break;
      case "uncategorized": // Handle new option
        reviewList = await ReviewSql.getUncategorizedWords(deck: deckName, deckSize: numCards);
        break;
    }
    return reviewList;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: deckExists
                    ? const BorderRadius.vertical(top: Radius.circular(10))
                    : BorderRadius.circular(10),
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
              ),
              child: Column(
                children: [
                  const SizedBox(
                    height: 5,
                  ),
                  ShrinkWidget(
                    isCollapsed: isCollapsed,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() {
                          isCollapsed = false;
                        });
                      },
                      child: const Row(children: [Text("Review Options")]),
                    ),
                  ),
                  Collapsible(
                    duration: 1000,
                    isCollapsed: isCollapsed,
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 15,
                        ),
                        const Center(
                          child: Text("Review Options"),
                        ),
                        const SizedBox(
                          height: 25,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Review words:"),
                            CupertinoButton(
                              onPressed: () {
                                _showReviewWordsActionSheet(context);
                              },
                              child: Text(reviewWordsValue),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Review type:"),
                            CupertinoButton(
                              onPressed: () {
                                _showReviewTypeActionSheet(context);
                              },
                              child: Text(reviewTypeValue),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Deck size"),
                            CupertinoButton(
                              onPressed: () {
                                _showReviewSizeActionSheet(context);
                              },
                              child: Text(deckSizeValue),
                            ),
                            //DropDown(dropdownOptions: deckSizeOptions, callback: (value) { deckSizeValue = value; })
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Deck"),
                            CupertinoButton(
                              onPressed: () {
                                _showReviewDeckActionSheet(context);
                              },
                              child: Text(deckName),
                            ),
                          ],
                        ),
                        CupertinoButton(
                            onPressed: () {
                              setState(() {
                                hskList = getReview();
                                isCollapsed = true;
                                deckExists = true;
                              });
                            },
                            child: const Text("create deck")),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            deckExists
                ? FutureBuilder(
                    future: hskList,
                    builder: (BuildContext context,
                        AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                      if (snapshot.hasData) {
                        if (snapshot.data!.isNotEmpty) {
                          return Container(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 3),
                              child: Row(
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      style: DefaultTextStyle.of(context).style,
                                      children: <TextSpan>[
                                        //const TextSpan(text: 'Review '),
                                        TextSpan(
                                            text:
                                                snapshot.data!.length.toString(),
                                            style: const TextStyle(
                                                color: Colors.blue)),
                                        const TextSpan(text: ' Words'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else {
                          return const SizedBox(height: 0);
                        }
                      } else {
                        return const SizedBox(height: 0);
                      }
                    })
                : const SizedBox(height: 0),
            deckExists
                ? HskListview(
                    hskList: hskList,
                    showTranslation: previewDeck,
                    showPinyin: showPinyin,
                    connectTop: true,
                    color: Theme.of(context).scaffoldBackgroundColor,
                    scrollAxis: Axis.vertical,
                    emptyListMessage: const Text("Nothing to review"))
                : const SizedBox(
                    height: 0,
                  ),
            ShrinkWidget(
              //visible: isCollapsed,
              isCollapsed: isCollapsed,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
                child: Center(
                  child: FutureBuilder(
                    future: reviewRatingFuture,
                    builder: (BuildContext context,
                        AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                      if (snapshot.hasData) {
                        List<ReviewRating> ratings =
                            createReviewRating(snapshot.data!);
                        return TextButton(
                            style: Styles.blankButton4,
                            onPressed: () {
                              if (reviewTypeValue == quizType) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ReviewQuiz(hskList: hskList),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReviewFlashcards(
                                      hskList: hskList,
                                      update: update,
                                      type: reviewWordsValue,
                                      deckSize: numCards,
                                      ratings: ratings,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: const Text("Review"));
                      } else {
                        return const DelayedProgressIndicator();
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _showReviewWordsActionSheet<bool>(BuildContext context) {
    showCupertinoModalPopup<bool>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Select word selection type'),
        actions: List<CupertinoActionSheetAction>.generate(
            reviewWordsOptions.length, (index) {
          return CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context, true);
              setState(() {
                reviewWordsValue = reviewWordsOptions[index];
              });
              prefs.setString('reviewWords', reviewWordsValue);
            },
            child: Text(reviewWordsOptions[index]),
          );
        }),
      ),
    );
  }

  _showReviewTypeActionSheet<bool>(BuildContext context) {
    showCupertinoModalPopup<bool>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Select a review type course'),
        actions: List<CupertinoActionSheetAction>.generate(
            reviewTypeOptions.length, (index) {
          return CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context, true);
              setState(() {
                reviewTypeValue = reviewTypeOptions[index];
              });
              prefs.setString('reviewType', reviewTypeValue);
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
        actions: List<CupertinoActionSheetAction>.generate(
            deckSizeOptions.length, (index) {
          return CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context, true);
              setState(() {
                deckSizeValue = deckSizeOptions[index];
              });
              prefs.setString('deckSize', deckSizeValue);
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
        actions: List<CupertinoActionSheetAction>.generate(deckNames.length,
            (index) {
          return CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context, true);
              setState(() {
                deckName = deckNames[index];
              });
              prefs.setString('deckName', deckName);
            },
            child: Text(deckNames[index]),
          );
        }),
      ),
    );
  }
}
