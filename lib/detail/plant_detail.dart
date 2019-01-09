import 'dart:convert';

import 'package:abherbs_flutter/drawer.dart';
import 'package:abherbs_flutter/entity/plant.dart';
import 'package:abherbs_flutter/entity/plant_translation.dart';
import 'package:abherbs_flutter/entity/translations.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/keys.dart';
import 'package:abherbs_flutter/main.dart';
import 'package:abherbs_flutter/detail/plant_detail_gallery.dart';
import 'package:abherbs_flutter/detail/plant_detail_info.dart';
import 'package:abherbs_flutter/utils.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

final plantsReference = FirebaseDatabase.instance.reference().child(firebasePlants);
final translationsReference = FirebaseDatabase.instance.reference().child(firebaseTranslations);

const String sourceWikipedia = "wikipedia";
const String sourceWikimediaCommons = "commons.wikimedia.org";
const String sourceWikimediaCommonsTitle = "commons";
const String sourceWikimediaSpecies = "species.wikimedia.org";
const String sourceWikimediaSpeciesTitle = "species";
const String sourceWikimediaData = "wikidata.org";
const String sourceWikimediaDataTitle = "wikidata";
const String sourceLuontoportii = "luontoportti.com";
const String sourceBotany = "botany.cz";
const String sourceFloraNordica = "floranordica.org";
const String sourceEflora = "efloras.org";
const String sourceBerkeley = "berkeley.edu";
const String sourceHortipedia = "hortipedia.com";
const String sourceUsda = "plants.usda.gov";
const String sourceUsfs = "forestryimages.org";
const String sourceTelaBotanica = "tela-botanica.org";

class PlantDetail extends StatefulWidget {
  final Locale myLocale;
  final void Function(String) onChangeLanguage;
  final Map<String, String> filter;
  final String plantName;
  PlantDetail(this.myLocale, this.onChangeLanguage, this.filter, this.plantName);

  @override
  _PlantDetailState createState() => _PlantDetailState();
}

class _PlantDetailState extends State<PlantDetail> {
  Future<Plant> _plantF;
  Future<PlantTranslation> _plantTranslationF;

  int _currentIndex;

  @override
  void initState() {
    super.initState();

    Ads.hideBannerAd();

    _plantF = plantsReference.child(widget.plantName).once().then((DataSnapshot snapshot) {
      return Plant.fromJson(snapshot.key, snapshot.value);
    });

    _plantTranslationF = translationsReference.child(widget.myLocale.languageCode).child(widget.plantName).once().then((DataSnapshot snapshot) {
      var plantTranslation = PlantTranslation.fromJson(snapshot.value);
      if (plantTranslation != null && plantTranslation.isTranslated()) {
        return plantTranslation;
      } else {
        return translationsReference
            .child(widget.myLocale.languageCode + languageGTSuffix)
            .child(widget.plantName)
            .once()
            .then((DataSnapshot snapshot) {
          var plantTranslationGT = PlantTranslation.copy(plantTranslation);
          if (snapshot.value != null) {
            plantTranslationGT = PlantTranslation.fromJson(snapshot.value);
            plantTranslationGT.mergeWith(plantTranslation);
          }
          if (plantTranslationGT.label == null) {
            plantTranslationGT.label = widget.plantName;
          }
          if (plantTranslationGT.isTranslated()) {
            return plantTranslationGT;
          } else {
            return translationsReference
                .child(widget.myLocale.languageCode == 'cs' ? languageSlovak : languageEnglish)
                .child(widget.plantName)
                .once()
                .then((DataSnapshot snapshot) {
              var plantTranslationOriginal = PlantTranslation.fromJson(snapshot.value);
              var uri = googleTranslateEndpoint + '?key=' + translateAPIKey;
              uri += '&source=' + ('cs' == widget.myLocale.languageCode ? 'sk' : 'en');
              uri += '&target=' + widget.myLocale.languageCode;
              for (var text in plantTranslation.getTextsToTranslate(plantTranslationOriginal)) {
                uri += '&q=' + text;
              }
              return http.get(uri).then((response) {
                if (response.statusCode == 200) {
                  Translations translations = Translations.fromJson(json.decode(response.body));
                  PlantTranslation onlyGoogleTranslation = plantTranslation.fillTranslations(translations.translatedTexts, plantTranslationOriginal);
                  translationsReference
                      .child(widget.myLocale.languageCode + languageGTSuffix)
                      .child(widget.plantName)
                      .set(onlyGoogleTranslation.toJson());
                  return plantTranslation;
                } else {
                  return plantTranslation.mergeWith(plantTranslationOriginal);
                }
              });
            });
          }
        });
      }
    });

    _currentIndex = 0;
  }

  Widget _getBody(BuildContext context) {
    switch (_currentIndex) {
      case 0:
        return getInfo(context, widget.myLocale, _plantF, _plantTranslationF);
      case 1:
        return getGallery(context, _plantF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plantName),
      ),
      drawer: AppDrawer(widget.onChangeLanguage, widget.filter, null),
      body: _getBody(context),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.info), title: Text(S.of(context).filter_habitat)),
          BottomNavigationBarItem(icon: Icon(Icons.photo_library), title: Text(S.of(context).filter_petal)),
          BottomNavigationBarItem(icon: Icon(Icons.format_list_bulleted), title: Text(S.of(context).filter_distribution)),
        ],
        fixedColor: Colors.blue,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
