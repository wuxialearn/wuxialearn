import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../learn/unit_view.dart';
import '../settings/preferences.dart';

class CourseView extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> unitList;
  final List<Widget> Function(List<Map<String, dynamic>> hskList) gridItems;
  final Function update;
  final void Function(String courseName) changeCourse;
  final String courseName;
  const CourseView({
    super.key,
    required this.unitList,
    required this.gridItems,
    required this.update,
    required this.courseName,
    required this.changeCourse,
  });

  @override
  State<CourseView> createState() => _CourseViewState();
}

class _CourseViewState extends State<CourseView> {
  List<String> courses = Preferences.getPreference("courses");
  late int hskLevel;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20),
            child: FutureBuilder<List<Map<String, dynamic>>>(
                future: widget.unitList,
                builder: (BuildContext context,
                    AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                  if (snapshot.hasData) {
                    List<Map<String, dynamic>> courseList = snapshot.data!;
                    hskLevel = getHskLevel(courseList);
                    return CustomScrollView(
                      scrollDirection: Axis.vertical,
                      physics: const ScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.only(top: 10, bottom: 20),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextButton(
                                    onPressed: () {
                                      _showActionSheet(context);
                                    },
                                    child: const Text("Change Course")),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.white,
                                  ),
                                  padding: const EdgeInsets.only(top: 10.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Text(
                                        '${widget.courseName} course',
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        ...widget.gridItems(courseList),
                      ],
                    );
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                }),
          ),
        ),
      ],
    );
  }

  _showActionSheet<bool>(BuildContext context) {
    showCupertinoModalPopup<bool>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        //title: const Text('Courses'),
        title: const Text('Select a course'),
        actions:
            List<CupertinoActionSheetAction>.generate(courses.length, (index) {
          return CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
              if (courses[index] != widget.courseName) {
                final allowSkipUnits =
                    Preferences.getPreference("allow_skip_units");
                var allowedChangeCourse = hskLevel > 2 || allowSkipUnits;
                if (allowedChangeCourse) {
                  widget.changeCourse(courses[index]);
                } else {
                  showCupertinoDialog(
                      barrierDismissible: true,
                      context: context,
                      builder: (context) {
                        return CupertinoAlertDialog(
                          content: const Text(
                            "You need to complete HSK 2 to start this course",
                            style: TextStyle(fontSize: 16),
                          ),
                          actions: [
                            CupertinoDialogAction(
                              /// This parameter indicates this action is the default,
                              /// and turns the action's text to bold text.
                              isDefaultAction: true,
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        );
                      });
                }
              }
            },
            child: Text(courses[index]),
          );
        }),
      ),
    );
  }

  int getHskLevel(List<Map<String, dynamic>> unitList) {
    if (widget.courseName != "hsk") {
      return 3;
    }
    int topHskLevel = 2;
    bool fullCompleted = true;
    for (final unit in unitList) {
      int hskLevel = unit["hsk"];
      if (hskLevel > topHskLevel) {
        int completed = unit["completed"];
        if (completed == 1) {
          topHskLevel = hskLevel;
        }
      } else if (hskLevel == topHskLevel) {
        int completed = unit["completed"];
        if (completed != 1) {
          fullCompleted = false;
        }
      }
    }
    topHskLevel = fullCompleted ? topHskLevel + 1 : topHskLevel;
    return topHskLevel;
  }
}

class GridItem extends StatelessWidget {
  final int index;
  final List<Map<String, dynamic>> unitList;
  final Function updateUnits;
  final String courseName;
  final bool allowSkipUnits;
  const GridItem(
      {super.key,
      required this.index,
      required this.unitList,
      required this.courseName,
      required this.updateUnits,
      required this.allowSkipUnits});

  @override
  Widget build(BuildContext context) {
    bool isUnitOpen =
        allowSkipUnits || index == 0 || unitList[index - 1]["completed"] == 1;
    final Color unitColor = index == 0 || unitList[index - 1]["completed"] == 1
        ? Colors.green
        : Colors.blue;
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: unitColor, width: 3)),
      child: TextButton(
        style: ButtonStyle(
            overlayColor: MaterialStateProperty.all(Colors.transparent)),
        onPressed: () {
          if (isUnitOpen) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UnitView(
                  unit: unitList[index]["unit_id"],
                  name: unitList[index]["unit_name"],
                  updateUnits: updateUnits,
                  courseName: courseName,
                ),
              ),
            ).then((_) {
              updateUnits();
            });
          }
        },
        child: Text(
          unitList[index]["unit_name"],
          style: TextStyle(color: unitColor, fontSize: 18),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
