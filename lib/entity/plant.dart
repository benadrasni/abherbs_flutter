class Plant{
  final String key;
  int gbifId;
  int kewId;
  String usdaId;
  String name;
  String wikiName;
  Map<dynamic, dynamic> apgIV;
  int flowerinFrom;
  int floweringTo;
  int heightFrom;
  int heightTo;
  int toxicityClass;
  String illustrationUrl;
  List<dynamic> photoUrls;
  List<dynamic> sourceUrls;
  List<dynamic> synonyms;
  Map<dynamic, dynamic> wikiLinks;

  Plant.fromJson(this.key, Map data) {
    name = data['name'];
    wikiLinks = data['wikilinks'];
  }
}