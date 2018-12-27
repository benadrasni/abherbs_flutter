class PlantTranslation {
  String label;
  List<dynamic> names;
  List<dynamic> sourceUrls;
  String wikipedia;
  String description;
  String flower;
  String inflorescence;
  String fruit;
  String leaf;
  String stem;
  String habitat;
  String toxicity;
  String herbalism;
  String trivia;

  bool isTranslated;

  PlantTranslation.fromJson(Map data) {
    label = data['label'];
    names = data['names'];
    sourceUrls = data['sourceUrls'];
    wikipedia = data['wikipedia'];
    description = data['description'];
    flower = data['flower'];
    inflorescence = data['inflorescence'];
    fruit = data['fruit'];
    leaf = data['leaf'];
    stem = data['stem'];
    habitat = data['habitat'];
    toxicity = data['toxicity'];
    herbalism = data['herbalism'];
    trivia = data['trivia'];

    isTranslated = description != null && flower != null && inflorescence != null && fruit != null && leaf != null && stem != null && habitat != null;
  }

  void copyFrom(PlantTranslation plantTranslation) {
    label = plantTranslation.label ?? label;
    names = plantTranslation.names ?? names;
    sourceUrls = plantTranslation.sourceUrls ?? sourceUrls;
    wikipedia = plantTranslation.wikipedia ?? wikipedia;
    description = plantTranslation.description ?? description;
    flower = plantTranslation.flower ?? flower;
    inflorescence = plantTranslation.inflorescence ?? inflorescence;
    fruit = plantTranslation.fruit ?? fruit;
    leaf = plantTranslation.leaf ?? leaf;
    stem = plantTranslation.stem ?? stem;
    habitat = plantTranslation.habitat ?? habitat;
    toxicity = plantTranslation.toxicity ?? toxicity;
    herbalism = plantTranslation.herbalism ?? herbalism;
    trivia = plantTranslation.trivia ?? trivia;
  }
}