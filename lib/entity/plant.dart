class Plant{
  final String key;
  int id = 0;
  int? gbifId;
  String? usdaId;
  String? ipniId;
  String name = "";
  String? author;
  Map<dynamic, dynamic> apgIV = {};
  int floweringFrom = 1;
  int floweringTo = 12;
  int heightFrom = 0;
  int heightTo = 0;
  int toxicityClass = 0;
  String? illustrationUrl;
  List<dynamic> photoUrls = [];
  List<dynamic> videoUrls = [];
  List<dynamic> sourceUrls = [];
  List<dynamic> synonyms = [];
  Map<dynamic, dynamic> wikiLinks = {};

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
    videoUrls = data['videoUrls'];
    sourceUrls = data['sourceUrls'];
    synonyms = data['synonyms'];
    wikiLinks = data['wikilinks'];
  }
}