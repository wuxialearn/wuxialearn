import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hsk_learner/sql/review_sql.dart';
import 'package:hsk_learner/widgets/delayed_progress_indecator.dart';

import '../../data_model/review_rating.dart';
class ManageRatings extends StatefulWidget {
  const ManageRatings({super.key});

  @override
  State<ManageRatings> createState() => _ManageRatingsState();
}

class _ManageRatingsState extends State<ManageRatings> {
  Future<List<Map<String, dynamic>>> ratingsFuture = ReviewSql.getReviewRatings();
  void update(){
    setState(() {
      ratingsFuture = ReviewSql.getReviewRatings();
    });
  }
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: ratingsFuture,
        builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if(snapshot.hasData){
            final ratings = createReviewRating(snapshot.data!);
            return  Column(
              children: [
                const SizedBox(height: 5),
                const Text("Manage Ratings"),
                const SizedBox(height: 15),
                Table(
                  children: List.generate(ratings.length, (int index){
                    final rating = ratings[index];
                    return TableRow(
                      children: [
                        Text(rating.name),
                        Text(rating.interval()),
                        TextButton(
                          onPressed: (){
                            showCupertinoDialog<String>(
                              barrierDismissible: true,
                              context: context,
                              builder: (BuildContext context) => Dialog(
                                  child: _EditReviewRatingForm(rating: rating, update: update,)
                              ),
                            );
                          },
                          child: const Text("edit"),
                        ),
                        TextButton(
                          onPressed: (){
                            ReviewSql.deleteRating(id: rating.id);
                            update();
                          },
                          child: const Text("delete"),
                        )
                      ]
                    );
                  }),
                ),
                TextButton(
                    onPressed: (){
                      showCupertinoDialog<String>(
                        barrierDismissible: true,
                        context: context,
                        builder: (BuildContext context) => Dialog(
                            child: _AddReviewRatingForm(update: update,)
                        ),
                      );
                    },
                    child: const Text("add")
                ),
              ],
            );
          }else{
            return const DelayedProgressIndicator();
          }
        },
    );
  }
}

class _AddReviewRatingForm extends StatefulWidget {
  final Function update;
  const _AddReviewRatingForm({required this.update});

  @override
  State<_AddReviewRatingForm> createState() => _AddReviewRatingFormState();
}

class _AddReviewRatingFormState extends State<_AddReviewRatingForm> {
  final GlobalKey<FormState> key = GlobalKey<FormState>();
  void update(String name, int start, int end){
    ReviewSql.insertRating(name: name, start: start, end: end);
    widget.update();
  }
  @override
  Widget build(BuildContext context) {
    return _RatingsForm(
      formKey: key,
      update: update,
    );
  }
}


class _EditReviewRatingForm extends StatefulWidget {
  const _EditReviewRatingForm({required this.rating, required this.update});
  final ReviewRating rating;
  final Function update;

  @override
  State<_EditReviewRatingForm> createState() => _EditReviewRatingFormState();
}

class _EditReviewRatingFormState extends State<_EditReviewRatingForm> {
  final GlobalKey<FormState> key = GlobalKey<FormState>();
  late String name;
  late String startIntervalValue;
  late String endIntervalValue;
  late String startInterval;
  late String endInterval;
  void update(String name, int start, int end){
    ReviewSql.setReviewRating(id: widget.rating.id, name: name, start: start, end: end );
    widget.update();
  }
  @override
  void initState() {
    name = widget.rating.name;
    startInterval = widget.rating.startInterval();
    endInterval = widget.rating.endInterval();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return _RatingsForm(
      formKey: key,
      update: update,
      initialName: name,
      initialStart: startInterval,
      initialEnd: endInterval,
      initialEndIntervalValue: widget.rating.endIntervalValue(),
      initialStartIntervalValue: widget.rating.startIntervalValue(),
    );
  }
}

class _RatingsForm extends StatefulWidget {
  final String? initialName;
  final String? initialStart;
  final String? initialEnd;
  final String? initialStartIntervalValue;
  final String? initialEndIntervalValue;
  final  GlobalKey<FormState> formKey;
  final Function(String name, int start, int end) update;
  const _RatingsForm({this.initialName, this.initialStart, this.initialEnd, required this.formKey, this.initialStartIntervalValue, this.initialEndIntervalValue, required this.update});

  @override
  State<_RatingsForm> createState() => _RatingsFormState();
}

class _RatingsFormState extends State<_RatingsForm> {
  late String name;
  late String startIntervalValue;
  late String endIntervalValue;
  late String startInterval;
  late String endInterval;
  final List<String> intervals = ["min", "hrs", "days"];

  @override
  void initState() {
    startInterval = widget.initialStart ?? intervals[0];
    endInterval = widget.initialEnd ?? intervals[0];
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15.0),
      child: Form(
        key: widget.formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                const Text("name"),
                Expanded(
                  child: CupertinoTextFormFieldRow(
                    keyboardType: TextInputType.number,
                    onSaved: (String? value){name = value!;},
                    initialValue: widget.initialName,
                    placeholder: "enter a name",
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {return 'Please enter some text';}
                      return null;
                    },
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Text("start duration"),
                Expanded(
                  child: CupertinoTextFormFieldRow(
                    initialValue: widget.initialStartIntervalValue,
                    keyboardType: TextInputType.number,
                    onSaved: (String? value){startIntervalValue = value!;},
                    placeholder: 'Enter a start Duration',
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {return 'Please enter some text';}
                      return null;
                    },
                  ),
                ),
                TextButton(
                    onPressed: (){
                      _showStartIntervalActionSheet(context);
                    },
                    child: Text(startInterval)
                )
              ],
            ),
            Row(
              children: [
                const Text("end duration"),
                Expanded(
                  child: CupertinoTextFormFieldRow(
                    initialValue: widget.initialEndIntervalValue,
                    keyboardType: TextInputType.number,
                    onSaved: (String? value){endIntervalValue = value!;},
                    placeholder: "enter an end Duration",
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {return 'Please enter some text';}
                      return null;
                    },
                  ),
                ),
                TextButton(
                    onPressed: (){
                      _showEndIntervalActionSheet(context);
                    },
                    child: Text(endInterval)
                )
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  if (widget.formKey.currentState!.validate()) {
                    widget.formKey.currentState!.save();
                    Duration startDuration = switch(startInterval){
                      "min" => Duration(minutes: int.parse(startIntervalValue)),
                      "hrs" => Duration(hours: int.parse(startIntervalValue)),
                      "days" => Duration(days: int.parse(startIntervalValue)),
                      _ => const Duration(minutes: 1)
                    };
                    Duration endDuration = switch(endInterval){
                      "min" => Duration(minutes: int.parse(endIntervalValue)),
                      "hrs" => Duration(hours: int.parse(endIntervalValue)),
                      "days" => Duration(days: int.parse(endIntervalValue)),
                      _ => const Duration(minutes: 1)
                    };
                    int start = startDuration.inSeconds;
                    int end = endDuration.inSeconds;
                    widget.update(name, start, end);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  _showStartIntervalActionSheet<bool>(BuildContext context) {
    showCupertinoModalPopup<bool>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions:
        List<CupertinoActionSheetAction>.generate(intervals.length,(index){
          return CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context, true);
              setState(() {
                startInterval = intervals[index];
              });
            },
            child: Text(intervals[index]),
          );
        }),
      ),
    );
  }
  _showEndIntervalActionSheet<bool>(BuildContext context) {
    showCupertinoModalPopup<bool>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions:
        List<CupertinoActionSheetAction>.generate(intervals.length,(index){
          return CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context, true);
              setState(() {
                endInterval = intervals[index];
              });
            },
            child: Text(intervals[index]),
          );
        }),
      ),
    );
  }
}

