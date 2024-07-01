import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hsk_learner/sql/sql_helper.dart';
import 'package:hsk_learner/utils/prototype.dart';
import 'package:intl/intl.dart';

import '../../sql/word_view_sql.dart';

class WordView extends StatefulWidget {
  final int wordId;
  const WordView({super.key, required this.wordId});
  @override
  State<WordView> createState() => _WordViewState();
}

class _WordViewState extends State<WordView> {
  late Future<List<Map<String, dynamic>>> literalMeaning;
  late Future<List<Map<String, dynamic>>> sentencesFuture;

  @override
  initState(){
    super.initState();
    literalMeaning = WordViewSql.getWordInfo(widget.wordId);
    sentencesFuture = WordViewSql.getSentenceFromId(widget.wordId);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text("Word Stats"),),
      child: SafeArea(
        child: Column(
          children: [
            FutureBuilder<List<Map<String, dynamic>>>(
              future: literalMeaning,
              builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
               if(snapshot.hasData){
                 final List<Map<String, dynamic>> stats = snapshot.data!;
                 String? literal;
                 if(stats[0]["char_two"] != null){
                   literal = "${stats[0]["char_one"]} + ${stats[0]["char_two"]}";
                   if(stats[0]["char_three"] != null){
                     literal += " + ${stats[0]["char_three"]}}";
                     if(stats[0]["char_four"] != null){
                       literal = " + ${stats[0]["char_four"]}";
                     }
                   }
                 }
                  return Column(
                    children: [
                      const SizedBox(height: 30,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              Text(stats[0]["pinyin"],
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(stats[0]["hanzi"],
                                style: const TextStyle(fontSize: 28),
                              ),
                              Text(stats[0]["translations0"],
                                style: const TextStyle(fontSize: 14),
                              ),
                              literal != null ? Row(
                                children: [
                                  Text(literal)
                                ],
                              ) : const SizedBox()
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 15,),
                      const Text("Info",style: TextStyle(fontSize: 15),),
                      const SizedBox(height: 15,),
                      Wrap(
                        spacing: 13,
                        children: [
                          Text("${stats[0]["course"]} ${stats[0]["hsk"]} unit ${stats[0]["unit"]}"),
                          Text("""first seen: ${
                            DateFormat.yMd().format(
                                DateTime.fromMillisecondsSinceEpoch(stats[0]["first_seen"]*1000)
                             )
                          }"""),
                          Text("""last seen: ${
                              DateFormat.yMd().format(
                                  DateTime.fromMillisecondsSinceEpoch(stats[0]["last_seen"]*1000)
                              )}
                          """),
                          Text("seen ${stats[0]["total_seen"]} time${stats[0]["total_seen"]!=1?"s":""}"),
                          Text("correct percentage: ${stats[0]["total_correct"]}%"),
                          Text("""next review: ${
                              DateFormat.yMd().format(
                                  DateTime.fromMillisecondsSinceEpoch(stats[0]["show_next"]*1000)
                              )}
                          """),
                        ],
                      ),
                      const SizedBox(height: 3,),
                      const Divider(height: 6, thickness: 1.5, indent: 10, endIndent: 10, color: Color.fromRGBO(227, 227, 227, 1.0),),
                    ],
                  );
                } else{
                  return const SizedBox();
                }
              },
            ),
            Expanded(
              child: _Sentences(sentencesFuture: sentencesFuture,),
            )
          ],
        ),
      )
    );
  }
}

class _Sentences extends StatelessWidget {
  const _Sentences({required this.sentencesFuture});
  final Future<List<Map<String, dynamic>>> sentencesFuture;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
        future: sentencesFuture,
        builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.hasData) {
            List<Map<String, dynamic>> sentences = snapshot.data!;
            if (sentences.isEmpty){
              return const Column(
                children: [
                  SizedBox(height: 20,),
                  Text("There are no sentences yet for this word", style: TextStyle(fontSize: 20),),
                ],
              );
            }else{
              return CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Text("Sentences"),
                        ],
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                        childCount: sentences.length,
                            (BuildContext context, int index){
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10,),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: PrototypeHeight(
                                        prototype: const Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("名字爱Míngzì", overflow: TextOverflow.ellipsis,),
                                            Text("名字爱Míngzì", style: TextStyle(fontSize: 20),overflow: TextOverflow.ellipsis,),
                                            Text("名字爱Míngzì", style: TextStyle(fontSize: 16),overflow: TextOverflow.ellipsis,),
                                          ],
                                        ),
                                        child: ListView(
                                          scrollDirection: Axis.horizontal,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(sentences[index]["pinyin"], overflow: TextOverflow.ellipsis,),
                                                Text(sentences[index]["characters"], style: const TextStyle(fontSize: 20),overflow: TextOverflow.ellipsis,),
                                                Text(sentences[index]["meaning"], style: const TextStyle(fontSize: 16),overflow: TextOverflow.ellipsis,),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }
                    ),
                  ),
                ],
              );
            }
          }
          else{return const SizedBox();}
        }
    );
  }
}



//not sure if this is good. We don't maintain extra translations
/*
                stats[0]["translations0"] != null
                    ? const Text("More translations: ")
                    : const SizedBox(height: 0),
                stats[0]["translations0"] != null
                    ? Text(stats[0]["translations0"])
                    : const SizedBox(height: 0),
                stats[0]["translations1"] != null
                    ? Text(stats[0]["translations1"])
                    : const SizedBox(height: 0),
                stats[0]["translations2"] != null
                    ? Text(stats[0]["translations2"])
                    : const SizedBox(height: 0),
*/
