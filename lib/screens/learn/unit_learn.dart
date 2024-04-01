import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hsk_learner/screens/games/unit_game.dart';
import 'package:hsk_learner/screens/settings/preferences.dart';
import '../../sql/sql_helper.dart';

class UnitLearn extends StatefulWidget {
  const UnitLearn({Key? key, required this.hskList, required this.unit, required this.subunit, required this.lastSubunit, required this.name, required this.updateUnits}) : super(key: key);
  final List<Map<String, dynamic>> hskList;
  final int unit;
  final int subunit;
  final bool lastSubunit;
  final String name;
  final Function updateUnits;

  @override
  State<UnitLearn> createState() => _UnitLearnState();
}

class _UnitLearnState extends State<UnitLearn> {
  final PageController _pageController = PageController();
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  FlutterTts flutterTts = FlutterTts();
  setLanguage() async{
    await flutterTts.setLanguage("zh-CN");
  }
  Future speak(String text) async{
    //await flutterTts.setLanguage("zh-CN");
    var result = await flutterTts.speak(text);
    //if (result == 1) setState(() => ttsState = TtsState.playing);
  }
  late List<Future<List<Map<String, dynamic>>>> futureList;
  late Future<List<Map<String, dynamic>>> exampleFuture;
  late Future<List<List<Map<String, dynamic>>>> futures;
  late List<Map<String, dynamic>> sentenceList = [];

  Future<List<Map<String, dynamic>>> getUnits(int index) async {
    final data = await SQLHelper.getExamples(widget.hskList[index]["hanzi"]);
    return data;
  }
  getSentenceList() async {
    sentenceList = await SQLHelper.getSentencesForSubunit(widget.unit, widget.subunit);
  }
  late bool showExampleSentences;
  bool wasClicked = false;
  bool lastPage = false;
  bool showPinyin = true;

  @override
  initState() {
    super.initState();
    exampleFuture = getUnits(0);
    futureList = List.generate(widget.hskList.length, (i) => getUnits(i));
    getSentenceList();
    setLanguage();
    showExampleSentences = Preferences.getPreference("show_sentences");
    speak(widget.hskList[0]["hanzi"]);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 3,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                    onPressed: () {Navigator.pop(context);},
                    icon: const Icon(CupertinoIcons.back)
                ),
                Row(
                  children: [
                    TextButton(
                      child:  showPinyin
                          ? const Text("Hide Pinyin")
                          : const Text("Show Pinyin"),
                      onPressed: () {
                        setState(() {
                          showPinyin = !showPinyin;
                        });
                      },
                    ),
                  ],
                )
              ],
            ),
            Expanded(
              child: PageView.builder(
                //pageSnapping: true,
                controller: _pageController,
                itemCount: widget.hskList.length,
                onPageChanged: (index) {
                  speak(widget.hskList[index]["hanzi"]);
                  if (index + 1 == widget.hskList.length) {
                    lastPage = true;
                  }
                },
                itemBuilder: (context, pageIndex) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 50,),
                      Flexible(
                        flex: showExampleSentences? 0:1,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Visibility(
                              maintainState: true,
                              maintainSize: true,
                              maintainAnimation: true,
                              visible: false,
                              child: IconButton(
                                  onPressed: () {
                                    speak(widget.hskList[pageIndex]["hanzi"]);
                                    },
                                  icon: const Icon(Icons.volume_up)
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Visibility(
                                  maintainState: true,
                                  maintainSize: true,
                                  maintainAnimation: true,
                                  visible: showPinyin,
                                  child: Text(
                                      widget.hskList[pageIndex]["pinyin"],
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                Text(widget.hskList[pageIndex]["hanzi"],
                                  style: const TextStyle(fontSize: 30),
                                ),
                                Visibility(
                                  maintainSize: true,
                                  maintainAnimation: true,
                                  maintainState: true,
                                  visible: wasClicked,
                                  child: Text(
                                      widget.hskList[pageIndex]["translations0"],
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                                onPressed: () {
                                  speak(widget.hskList[pageIndex]["hanzi"]);
                                },
                                icon: const Icon(Icons.volume_up)
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 35,
                      ),

                      Visibility(
                        visible: showExampleSentences,
                        child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                    margin: const EdgeInsets.only(left: 10.0, right: 20.0),
                                    child: const Divider(thickness: 2,)),
                              ),
                              const Text("Sentences", style: TextStyle(fontSize: 16),),
                              Expanded(
                                child: Container(
                                    margin: const EdgeInsets.only(left: 20.0, right: 10.0),
                                    child: const Divider(thickness: 2,)),
                              ),
                            ]
                        ),
                      ),
                      const SizedBox(height: 25,),

                      //sentences
                      Visibility(
                        visible: showExampleSentences,
                        child: FutureBuilder<List<Map<String, dynamic>>>(
                            future: futureList[pageIndex],
                            builder: (BuildContext context, AsyncSnapshot<List<
                                Map<String, dynamic>>> snapshot) {
                              if (snapshot.hasData) {
                                List<Map<String, dynamic>>? exampleList = snapshot.data;
                                return Column(
                                    children: [
                                      ListView.builder(
                                        physics: const ScrollPhysics(),
                                        scrollDirection: Axis.vertical,
                                        shrinkWrap: true,
                                        itemCount: exampleList!.length > 3? 3: exampleList.length,
                                        itemBuilder: (context, examplesIndex) {
                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    SizedBox(
                                                      width: 325,
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Visibility(
                                                            visible: showPinyin,
                                                            child: Text(
                                                              exampleList[examplesIndex]["pinyin"],
                                                              style: const TextStyle(
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                          ),
                                                          Text(
                                                            exampleList[examplesIndex]["characters"],
                                                            style: const TextStyle(
                                                              fontSize: 18,
                                                            ),
                                                          ),
                                                          Visibility(
                                                            maintainSize: true,
                                                            maintainAnimation: true,
                                                            maintainState: true,
                                                            visible: wasClicked,
                                                            child: Text(
                                                              exampleList[examplesIndex]["meaning"],
                                                              style: const TextStyle(
                                                                fontSize: 16,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    IconButton(
                                                        onPressed: (){speak(exampleList[examplesIndex]["characters"]);},
                                                        icon: const Icon(Icons.volume_up)
                                                    )
                                                  ],
                                                ),
                                              )
                                            ],
                                          );
                                        },
                                      ),
                                    ]
                                );
                              }
                              else {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                            }
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: FractionalOffset.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  fit: FlexFit.tight,
                                  child: TextButton(
                                    onPressed: () => {
                                      if (_pageController.hasClients && wasClicked) {
                                        if (lastPage){
                                          Navigator.pushReplacement(context, MaterialPageRoute(
                                            builder: (context) => UnitGame(
                                              hskList: widget.hskList,
                                              sentenceList: sentenceList,
                                              unit: widget.unit,
                                              subunit: widget.subunit,
                                              lastSubunit: widget.lastSubunit,
                                              name: widget.name,
                                              updateUnits: widget.updateUnits,
                                            ),
                                          ),).then((_){
                                            Navigator.pop(context);
                                          })
                                        }else{
                                          setState(() {
                                            wasClicked = false;
                                          }),
                                          _pageController.nextPage(
                                            duration: const Duration(milliseconds: 400),
                                            curve: Curves.easeInOut,
                                          )
                                        }
                                      }else{
                                        setState(() {
                                          wasClicked = true;
                                        })
                                      }
                                    },
                                    child: wasClicked
                                      ? const Text("Continue", style: TextStyle(fontSize: 16),)
                                      : const Text("Show Meaning", style: TextStyle(fontSize: 16),),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}



