import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hsk_learner/screens/settings/preferences.dart';
import 'package:hsk_learner/screens/stats/svg.dart';
import 'package:hsk_learner/sql/character_view_sql.dart';
import 'package:hsk_learner/utils/prototype.dart';

class CharacterView extends StatefulWidget {
  final String character;
  const CharacterView({super.key, required this.character});
  @override
  State<CharacterView> createState() => _CharacterViewState();
}

class _CharacterViewState extends State<CharacterView> {
  late Future<List<Map<String, dynamic>>> literalMeaning;
  late Future<List<Map<String, dynamic>>> sentencesFuture;
  bool showPinyin = true;
  bool showTranslations = true;

  @override
  initState() {
    super.initState();
    literalMeaning = CharacterViewSql.getCharInfo(widget.character);
    sentencesFuture = CharacterViewSql.getSentenceFromId(widget.character);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text("Character Info"),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () {
                        setState(() {
                          showTranslations = !showTranslations;
                        });
                      },
                      child: showTranslations
                          ? const Text("Hide translation")
                          : const Text("Show translation")),
                  TextButton(
                      onPressed: () {
                        setState(() {
                          showPinyin = !showPinyin;
                        });
                      },
                      child: showPinyin
                          ? const Text("Hide Pinyin")
                          : const Text("Show Pinyin")),
                ],
              ),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: literalMeaning,
                builder: (BuildContext context,
                    AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                  if (snapshot.hasData) {
                    final List<Map<String, dynamic>> stats = snapshot.data!;
                    return Column(
                      children: [
                        const SizedBox(
                          height: 30,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Column(
                              children: [
                                Visibility(
                                  visible: showPinyin,
                                  child: Text(
                                    stats[0]["pinyin"],
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                Text(
                                    stats[0]["hanzi"],
                                    style: const TextStyle(fontSize: 35),
                                ),
                                Visibility(
                                  visible: SharedPrefs.prefs.getBool("character_stroke_data_downloaded") ?? false,
                                  child: SvgCharacter(
                                    character: stats[0]["hanzi"],
                                    size: 200,
                                    onClick: (String character) {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => CharacterView(
                                            character: character,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Visibility(
                                  visible: showTranslations,
                                  child: Text(
                                    stats[0]["translation"],
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        const Divider(
                          height: 6,
                          thickness: 1.5,
                          indent: 10,
                          endIndent: 10,
                          color: Color.fromRGBO(227, 227, 227, 1.0),
                        ),
                      ],
                    );
                  } else {
                    return const SizedBox();
                  }
                },
              ),
              Expanded(
                child: _Sentences(
                  sentencesFuture: sentencesFuture,
                ),
              )
            ],
          ),
        ));
  }
}

class _Sentences extends StatefulWidget {
  const _Sentences({required this.sentencesFuture});
  final Future<List<Map<String, dynamic>>> sentencesFuture;
  @override
  State<_Sentences> createState() => _SentencesState();
}

class _SentencesState extends State<_Sentences> {
  bool showPinyin = false;
  bool showTranslations = false;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
        future: widget.sentencesFuture,
        builder: (BuildContext context,
            AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.hasData) {
            List<Map<String, dynamic>> sentences = snapshot.data!;
            if (sentences.isEmpty) {
              return const Column(
                children: [
                  SizedBox(
                    height: 20,
                  ),
                  Text(
                    "There are no sentences yet for this word",
                    style: TextStyle(fontSize: 20),
                  ),
                ],
              );
            } else {
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
                  SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                            onPressed: () {
                              setState(() {
                                showTranslations = !showTranslations;
                              });
                            },
                            child: showTranslations
                                ? const Text("Hide translation")
                                : const Text("Show translation")),
                        TextButton(
                            onPressed: () {
                              setState(() {
                                showPinyin = !showPinyin;
                              });
                            },
                            child: showPinyin
                                ? const Text("Hide Pinyin")
                                : const Text("Show Pinyin")),
                      ],
                    ),
                  ),
                  SliverList(
                    delegate:
                        SliverChildBuilderDelegate(childCount: sentences.length,
                            (BuildContext context, int index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: PrototypeHeight(
                                    prototype: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Visibility(
                                          visible: showPinyin,
                                          child: const Text(
                                            "名字爱Míngzì",
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Text(
                                          "名字爱Míngzì",
                                          style: TextStyle(fontSize: 20),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Visibility(
                                          visible: showTranslations,
                                          child: const Text(
                                            "名字爱Míngzì",
                                            style: TextStyle(fontSize: 16),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    child: ListView(
                                      scrollDirection: Axis.horizontal,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Visibility(
                                              visible: showPinyin,
                                              child: Text(
                                                sentences[index]["pinyin"],
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Text(
                                              sentences[index]["characters"],
                                              style:
                                                  const TextStyle(fontSize: 20),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Visibility(
                                              visible: showTranslations,
                                              child: Text(
                                                sentences[index]["meaning"],
                                                style: const TextStyle(
                                                    fontSize: 16),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
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
                    }),
                  ),
                ],
              );
            }
          } else {
            return const SizedBox();
          }
        });
  }
}
