import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hsk_learner/sql/review_sql.dart';
import 'package:hsk_learner/widgets/delayed_progress_indecator.dart';
class ReviewProgress extends StatefulWidget {
  const ReviewProgress({super.key});

  @override
  State<ReviewProgress> createState() => _ReviewProgressState();
}

class _ReviewProgressState extends State<ReviewProgress> {
  List<String> deckNames = ["hsk", "wuxia", "any"];
  String deckName = "hsk";
  late Future<List<Map<String, dynamic>>> progressFuture;
  @override
  void initState() {
    progressFuture = ReviewSql.getProgress(deck: deckName);
    super.initState();
  }
  @override
  Widget build(BuildContext context) {

    return Column(
      children: [
        const SizedBox(height: 20,),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Progress for",  style: TextStyle(fontSize: 20)),
            CupertinoButton(
              onPressed: (){ _showReviewDeckActionSheet(context);},
              child: Text(deckName, style: const TextStyle(fontSize: 20),),
            ),
          ],
        ),
        Expanded(
          child: FutureBuilder(
            future: progressFuture,
            builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                if(snapshot.hasData){
                  print("data");
                  print(snapshot.data);
                  final data = snapshot.data!;
                  return Center(
                    child: GridView.count(
                      childAspectRatio: 4,
                      crossAxisCount: 2,
                      children: List.generate(data.length * 2, (int index)=>
                        Center(
                          child: index % 2 == 0?
                          Text(data[index~/2]["rating_name"], style: const TextStyle(fontSize: 20),):
                          Text(data[index~/2]["count"].toString(), style: const TextStyle(fontSize: 20),),
                        )
                      )
                    ),
                  );
                }else{
                  return  const Center(child: DelayedProgressIndicator());
                }
            },
          ),
        ),
      ],
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
