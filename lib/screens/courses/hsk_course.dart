import 'package:flutter/material.dart';
import 'package:hsk_learner/screens/learn/test_out.dart';
import '../../sql/learn_sql.dart';
import '../settings/preferences.dart';
import '../../sql/sql_helper.dart';
import 'course_view.dart';

class HSKCourseView extends StatefulWidget {
  final void Function(String courseName) changeCourse;
  const HSKCourseView({Key? key, required this.changeCourse,}) : super(key: key);

  @override
  State<HSKCourseView> createState() => _HSKCourseViewState();
}

class _HSKCourseViewState extends State<HSKCourseView> {

  late Future<List<Map<String, dynamic>>> unitNumList;
  final bool debug = Preferences.getPreference("debug");
  @override
  void initState() {
    super.initState();
    unitNumList = getUnitNum();
  }
  Future<List<Map<String, dynamic>>> getUnitNum() async {
    final data = await LearnSql.count2(courseName: 'hsk');
    return data;
  }

  updateUnits(){
    setState(() {
      unitNumList = getUnitNum();
    });
  }

  @override
  Widget build(BuildContext context) {
    bool allowSkipUnits = Preferences.getPreference("allow_skip_units");
    List<Widget> gridItems (List<Map<String, dynamic>> hskList){
      List<Widget> widgets = [];
      List<int> hskListOffset = [];
      List<int> hskListUnitLengths = [];
      List<bool> hskIsCompletedList = [];
      for (int i = 0; i< hskList.length; i++){
        if (i == 0){hskListOffset.add(0);}
        else if(hskList[i]["hsk"] != hskList[i-1]["hsk"]){
          hskListUnitLengths.add(i-hskListOffset.last);
          hskListOffset.add(i);
          hskIsCompletedList.add(hskList[i-1]["completed"] == 1);
        }
        if(i == hskList.length -1){
          //+1 because we are using the i from last of the current unit rather than the first of the next unit
          hskListUnitLengths.add(i-hskListOffset.last +1);
          hskIsCompletedList.add(hskList[i]["completed"] == 1);
        }
      }
      for(int i = 0; i<hskListOffset.length; i++){
        widgets.add(
            SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              sliver: SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Visibility(
                          maintainAnimation: true,
                          maintainState: true,
                          maintainSize: true,
                          visible: false,
                          child: TextButton(onPressed: (){}, child: const Text("Test Out"))
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
                        child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(7.0),
                              boxShadow: [BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 3,
                                blurRadius: 5,
                                offset: const Offset(0, 3), // changes position of shadow
                              ),],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
                              child: Text("hsk ${i+2}", style: const TextStyle(fontSize: 20),),
                            )
                        ),
                      ),
                      Visibility(
                        maintainAnimation: true,
                        maintainState: true,
                        maintainSize: true,
                        visible: !hskIsCompletedList[i],
                        child: TextButton(
                            onPressed: (){
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TestOut(hsk: i+2),
                                ),
                              ).then((_){
                                setState(() {
                                  unitNumList = getUnitNum();
                                });
                              });
                            },
                            child: const Text("Test Out")
                        ),
                      )
                    ],
                  ),
                ),
              ),
            )
        );
        widgets.add(
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 100.0,
              mainAxisSpacing: 30.0,
              crossAxisSpacing: 30.0,
              childAspectRatio: 1,
            ),
            delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                return GridItem(index:index+hskListOffset[i], unitList:hskList, updateUnits: updateUnits, courseName: "hsk", allowSkipUnits: allowSkipUnits,);
              },
              childCount: hskListUnitLengths[i],
            ),
          ),
        );
      }
      return widgets;
    }
    return CourseView(unitList: unitNumList, gridItems: gridItems, update: updateUnits, courseName: "hsk", changeCourse: widget.changeCourse,);
  }
}
