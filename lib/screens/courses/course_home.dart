import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hsk_learner/screens/courses/hsk_course.dart';
import 'package:hsk_learner/screens/learn/unit_view.dart';

import '../settings/preferences.dart';
import 'custom_course.dart';

class CourseHome extends StatefulWidget {
  const CourseHome({super.key});

  @override
  State<CourseHome> createState() => _CourseHomeState();
}

class _CourseHomeState extends State<CourseHome> {
  String course = Preferences.getPreference("default_course");
  List<String> courses = Preferences.getPreference("courses");
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          //backgroundColor: Colors.transparent,
          middle: Text("Home"),
        ),
        child: SafeArea(
          child: switch (course){
           'hsk' =>  HSKCourseView(changeCourse: changeCourse),
            _ =>  CustomCourse(courseName: course, changeCourse: changeCourse),
          },
        )
    );
  }

  void changeCourse(String courseName){
    setState(() {
      course = courseName;
    });
  }
}

