class PlantTranslation {
  String? label;
  List<dynamic> names = [];
  List<dynamic> sourceUrls = [];
  String? wikipedia;
  String? description;
  String? flower;
  String? inflorescence;
  String? fruit;
  String? leaf;
  String? stem;
  String? habitat;
  String? toxicity;
  String? herbalism;
  String? trivia;
  bool isTranslatedWithGT = false;

  PlantTranslation();

  PlantTranslation.fromJson(Map data) {
    label = data['label'];
    names = (data['names'] as List<dynamic>?) ?? [];
    sourceUrls = (data['sourceUrls'] as List<dynamic>?) ?? [];
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
  }

  PlantTranslation.copy(PlantTranslation plantTranslation) {
    label = plantTranslation.label;
    names = plantTranslation.names;
    sourceUrls = plantTranslation.sourceUrls;
    wikipedia = plantTranslation.wikipedia;
    description = plantTranslation.description;
    flower = plantTranslation.flower;
    inflorescence = plantTranslation.inflorescence;
    fruit = plantTranslation.fruit;
    leaf = plantTranslation.leaf;
    stem = plantTranslation.stem;
    habitat = plantTranslation.habitat;
    toxicity = plantTranslation.toxicity;
    herbalism = plantTranslation.herbalism;
    trivia = plantTranslation.trivia;
  }

  PlantTranslation mergeWith(PlantTranslation plantTranslation) {
    label = plantTranslation.label ?? label;
    names = plantTranslation.names;
    sourceUrls = plantTranslation.sourceUrls;
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

    return this;
  }

  PlantTranslation mergeDataWith(PlantTranslation plantTranslation) {
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

    return this;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    if (label != null) {
      result['label'] = label;
    }
    result['names'] = names;
    result['sourceUrls'] = sourceUrls;
    if (wikipedia != null) {
      result['wikipedia'] = wikipedia;
    }

    if (description != null) {
      result['description'] = description;
    }
    if (flower != null) {
      result['flower'] = flower;
    }
    if (inflorescence != null) {
      result['inflorescence'] = inflorescence;
    }
    if (fruit != null) {
      result['fruit'] = fruit;
    }
    if (leaf != null) {
      result['leaf'] = leaf;
    }
    if (stem != null) {
      result['stem'] = stem;
    }
    if (habitat != null) {
      result['habitat'] = habitat;
    }
    if (toxicity != null) {
      result['toxicity'] = toxicity;
    }
    if (herbalism != null) {
      result['herbalism'] = herbalism;
    }
    if (trivia != null) {
      result['trivia'] = trivia;
    }

    return result;
  }

  bool isTranslated() {
    return description != null && flower != null && inflorescence != null && fruit != null && leaf != null && stem != null && habitat != null;
  }

  List<dynamic> getTextsToTranslate(PlantTranslation plantTranslation) {
    var result = [];
    if (description == null && plantTranslation.description != null) {
      result.add(plantTranslation.description);
    }
    if (flower == null && plantTranslation.flower != null) {
      result.add(plantTranslation.flower);
    }
    if (inflorescence == null && plantTranslation.inflorescence != null) {
      result.add(plantTranslation.inflorescence);
    }
    if (fruit == null && plantTranslation.fruit != null) {
      result.add(plantTranslation.fruit);
    }
    if (leaf == null && plantTranslation.leaf != null) {
      result.add(plantTranslation.leaf);
    }
    if (stem == null && plantTranslation.stem != null) {
      result.add(plantTranslation.stem);
    }
    if (habitat == null && plantTranslation.habitat != null) {
      result.add(plantTranslation.habitat);
    }
    if (toxicity == null && plantTranslation.toxicity != null) {
      result.add(plantTranslation.toxicity);
    }
    if (herbalism == null && plantTranslation.herbalism != null) {
      result.add(plantTranslation.herbalism);
    }
    if (trivia == null && plantTranslation.trivia != null) {
      result.add(plantTranslation.trivia);
    }
    return result;
  }

  PlantTranslation fillTranslations(List<String> translations, PlantTranslation plantTranslationOriginal) {
    PlantTranslation onlyGoogleTranslation = new PlantTranslation();
    if (description == null && plantTranslationOriginal.description != null && translations.length > 0) {
      description = translations.first;
      onlyGoogleTranslation.description = description;
      translations.removeAt(0);
    }
    if (flower == null && plantTranslationOriginal.flower != null && translations.length > 0) {
      flower = translations.first;
      onlyGoogleTranslation.flower = flower;
      translations.removeAt(0);
    }
    if (inflorescence == null && plantTranslationOriginal.inflorescence != null && translations.length > 0) {
      inflorescence = translations.first;
      onlyGoogleTranslation.inflorescence = inflorescence;
      translations.removeAt(0);
    }
    if (fruit == null && plantTranslationOriginal.fruit != null && translations.length > 0) {
      fruit = translations.first;
      onlyGoogleTranslation.fruit = fruit;
      translations.removeAt(0);
    }
    if (leaf == null && plantTranslationOriginal.leaf != null && translations.length > 0) {
      leaf = translations.first;
      onlyGoogleTranslation.leaf = leaf;
      translations.removeAt(0);
    }
    if (stem == null && plantTranslationOriginal.stem != null && translations.length > 0) {
      stem = translations.first;
      onlyGoogleTranslation.stem = stem;
      translations.removeAt(0);
    }
    if (habitat == null && plantTranslationOriginal.habitat != null && translations.length > 0) {
      habitat = translations.first;
      onlyGoogleTranslation.habitat = habitat;
      translations.removeAt(0);
    }
    if (toxicity == null && plantTranslationOriginal.toxicity != null && translations.length > 0) {
      toxicity = translations.first;
      onlyGoogleTranslation.toxicity = toxicity;
      translations.removeAt(0);
    }
    if (herbalism == null && plantTranslationOriginal.herbalism != null && translations.length > 0) {
      herbalism = translations.first;
      onlyGoogleTranslation.herbalism = herbalism;
      translations.removeAt(0);
    }
    if (trivia == null && plantTranslationOriginal.trivia != null && translations.length > 0) {
      trivia = translations.first;
      onlyGoogleTranslation.trivia = trivia;
      translations.removeAt(0);
    }
    return onlyGoogleTranslation;
  }
}