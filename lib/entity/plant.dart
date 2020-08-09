class Plant{
  final String key;
  int id;
  int gbifId;
  String usdaId;
  String ipniId;
  String name;
  String author;
  Map<dynamic, dynamic> apgIV;
  int floweringFrom;
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
    id = data['id'];
    name = data['name'];
    author = data['author'];
    apgIV = data['APGIV'];
    ipniId = data['ipniId'];
    floweringFrom = data['floweringFrom'];
    floweringTo = data['floweringTo'] ?? 0;
    heightFrom = data['heightFrom'] ?? 0;
    heightTo = data['heightTo'] ?? 0;
    toxicityClass = data['toxicityClass'] ?? 0;
    illustrationUrl = data['illustrationUrl'];
    photoUrls = data['photoUrls'];
    sourceUrls = data['sourceUrls'];
    synonyms = data['synonyms'];
    wikiLinks = data['wikilinks'];
  }
}