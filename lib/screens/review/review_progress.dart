import 'package:flutter/material.dart';
import 'package:hsk_learner/sql/review_sql.dart';
import 'package:hsk_learner/widgets/delayed_progress_indecator.dart';
class ReviewProgress extends StatefulWidget {
  const ReviewProgress({super.key});

  @override
  State<ReviewProgress> createState() => _ReviewProgressState();
}

class _ReviewProgressState extends State<ReviewProgress> {
  Future<List<Map<String, dynamic>>> progressFuture = ReviewSql.getProgress();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: progressFuture,
      builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if(snapshot.hasData){
            print("data");
            print(snapshot.data);
            return const SizedBox(height: 0,);
          }else{
            return  const Center(child: DelayedProgressIndicator());
          }
      },
    );
  }
}
