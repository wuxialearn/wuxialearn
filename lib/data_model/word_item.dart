class WordItem {
  late final int id;
  late final String hanzi;
  late final String pinyin;
  late final String translation;
  final List<String> literal = [];
  WordItem(Map<String, dynamic> wordMap) {
    id = wordMap["id"];
    hanzi = wordMap["hanzi"];
    pinyin = wordMap["pinyin"];
    translation = wordMap["translations0"];
    if (wordMap["char_one"] != null) {
      literal.add(wordMap["char_one"]);
      if (wordMap["char_two"] != null) {
        literal.add(wordMap["char_two"]);
        if (wordMap["char_three"] != null) {
          literal.add(wordMap["char_three"]);
          if (wordMap["char_four"] != null) {
            literal.add(wordMap["char_four"]);
          }
        }
      }
    }
  }
}

class WordItemWithSubunit extends WordItem {
  late final int subunit;
  WordItemWithSubunit(Map<String, dynamic> wordMap) : super(wordMap) {
    subunit = wordMap["subunit"];
  }
}

List<WordItem> createWordList(List<Map<String, dynamic>> wordList) {
  List<WordItem> wordItemList = [];
  for (final word in wordList) {
    wordItemList.add(WordItem(word));
  }
  return wordItemList;
}

List<WordItemWithSubunit> createWordListWithSubunit(
    List<Map<String, dynamic>> wordList) {
  List<WordItemWithSubunit> wordItemList = [];
  for (final word in wordList) {
    wordItemList.add(WordItemWithSubunit(word));
  }
  return wordItemList;
}
