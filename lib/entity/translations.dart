class Translations {
  List<String> translatedTexts;

  Translations.fromJson(Map response) {
    translatedTexts = [];
    var translations = response['data']['translations'];
    for(Map translatedText in translations) {
      translatedTexts.add(translatedText['translatedText']);
    }
  }
}