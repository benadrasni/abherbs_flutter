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
  List<String> inflorescenceType = [];
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
    photoUrls = data['photoUrls'] ?? [];
    videoUrls = data['videoUrls'] ?? [];
    sourceUrls = data['sourceUrls'] ?? [];
    synonyms = data['synonyms'] ?? [];
    inflorescenceType = _stringList(data['inflorescenceType']);
    wikiLinks = data['wikilinks'] ?? [];
  }
}

List<String> _stringList(dynamic raw) {
  if (raw is List) {
    return raw.map((item) => item.toString()).where((item) => item.isNotEmpty).toList();
  }
  if (raw is Map) {
    final keys = raw.keys.toList()
      ..sort((a, b) => (int.tryParse(a.toString()) ?? 0).compareTo(int.tryParse(b.toString()) ?? 0));
    return keys
        .map((key) => raw[key].toString())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return [];
}