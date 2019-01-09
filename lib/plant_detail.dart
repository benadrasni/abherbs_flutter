import 'package:abherbs_flutter/utils.dart';
import 'package:flutter/material.dart';
import 'package:abherbs_flutter/drawer.dart';
import 'package:abherbs_flutter/entity/plant.dart';
import 'package:abherbs_flutter/entity/plant_translation.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/main.dart';
import 'package:abherbs_flutter/keys.dart';
import 'package:abherbs_flutter/entity/translations.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  List<Widget> _getSources(Plant plant, PlantTranslation plantTranslation) {
    var rows = <Widget>[];

    var sources = [];
    if (plantTranslation.wikipedia != null) {
      sources.add(plantTranslation.wikipedia);
    }
    if (plant.wikiLinks != null) {
      sources.addAll(plant.wikiLinks.values);
    }
    if (plantTranslation.sourceUrls != null) {
      sources.addAll(plantTranslation.sourceUrls);
    }
    if (sources != null) {
      rows.add(Text(
        'Sources',
        style: TextStyle(
          fontSize: 22.0,
        ),
        textAlign: TextAlign.center,
      ));

      for (int i = 0; i < sources.length; i += 3) {
        var sourceButtons = <Widget>[];
        for (int j = 0; j < 3; j++) {
          if (i + j < sources.length) {
            sourceButtons.add(_getSourceButton(sources[i + j]));
          }
        }
        rows.add(Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: sourceButtons,
        ));
      }
    }
    return rows;
  }

  FlatButton _getSourceButton(String url) {
    assert(url.contains('//') && url.contains('/'), url.indexOf('//')+2);
    String imageSource = 'res/images/internet.png';
    String textSource = url.substring(url.indexOf('//')+2, url.indexOf('/', url.indexOf('//')+2));

    if (url.contains(sourceWikipedia)) {
      imageSource = 'res/images/wikipedia.png';
      textSource = sourceWikipedia;
    } else if (url.contains(sourceWikimediaCommons)) {
      imageSource = 'res/images/commons.png';
      textSource = sourceWikimediaCommonsTitle;
    } else if (url.contains(sourceWikimediaData)) {
      imageSource = 'res/images/wikidata.png';
      textSource = sourceWikimediaDataTitle;
    }  else if (url.contains(sourceWikimediaSpecies)) {
      imageSource = 'res/images/species.png';
      textSource = sourceWikimediaSpeciesTitle;
    } else if (url.contains(sourceLuontoportii)) {
      imageSource = 'res/images/luontoportti.png';
      textSource = sourceLuontoportii;
    } else if (url.contains(sourceBotany)) {
      imageSource = 'res/images/botany.png';
      textSource = sourceBotany;
    } else if (url.contains(sourceFloraNordica)) {
      imageSource = 'res/images/floranordica.png';
      textSource = sourceFloraNordica;
    } else if (url.contains(sourceEflora)) {
      imageSource = 'res/images/eflora.png';
      textSource = sourceEflora;
    } else if (url.contains(sourceBerkeley)) {
      imageSource = 'res/images/berkeley.png';
      textSource = sourceBerkeley;
    } else if (url.contains(sourceHortipedia)) {
      imageSource = 'res/images/hortipedia.png';
      textSource = sourceHortipedia;
    } else if (url.contains(sourceUsda)) {
      imageSource = 'res/images/usda.png';
      textSource = sourceUsda;
    } else if (url.contains(sourceUsfs)) {
      imageSource = 'res/images/usfs.png';
      textSource = sourceUsfs;
    } else if (url.contains(sourceTelaBotanica)) {
      imageSource = 'res/images/tela_botanica.png';
      textSource = sourceTelaBotanica;
    }

    return FlatButton(
      padding: EdgeInsets.only(bottom: 5.0),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Image(
          image: AssetImage(imageSource),
          width: 50.0,
          height: 50.0,
        ),
        Text(
          textSource,
          textAlign: TextAlign.center,
        ),
      ]),
      onPressed: () {
        launchURL(url);
      },
    );
  }

  RichText _getRichText(String text) {
    var sections = <TextSpan>[];
    for (String part in text.split('<b>')) {
      if (part.isNotEmpty) {
        var subParts = part.split('</b>');
        if (subParts.length == 1) {
          sections.add(TextSpan(text: subParts[0]));
        } else {
          sections.add(TextSpan(text: subParts[0], style: new TextStyle(fontWeight: FontWeight.bold)));
          sections.add(TextSpan(text: subParts[1]));
        }
      }
    }

    return RichText(
      text: TextSpan(
        // Note: Styles for TextSpans must be explicitly defined.
        // Child text spans will inherit styles from parent
        style: TextStyle(
          fontSize: 14.0,
          color: Colors.black,
        ),
        children: sections,
      ),
    );
  }

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plantName),
      ),
      drawer: AppDrawer(widget.onChangeLanguage, widget.filter, null),
      body: FutureBuilder<PlantTranslation>(
          future: _plantTranslationF,
          builder: (BuildContext context, AsyncSnapshot<PlantTranslation> snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.done:
                List<Widget> cards = [];
                cards.add(Card(
                  child: Container(
                    padding: EdgeInsets.only(top: 15.0, bottom: 15.0),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(
                        snapshot.data.label,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        snapshot.data.names == null ? '' : snapshot.data.names.take(3).join(', '),
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 14.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ]),
                  ),
                ));
                cards.add(Card(
                  child: Container(
                    padding: EdgeInsets.all(10.0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _getRichText(snapshot.data.description),
                    ]),
                  ),
                ));
                cards.add(Card(
                  child: Container(
                    padding: EdgeInsets.only(left: 10.0, bottom: 10.0, right: 10.0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      ListTile(
                        title: Text(S.of(context).plant_inflorescence),
                        leading: Image(
                          image: AssetImage('res/images/ic_inflorescence_grey_24dp.png'),
                          width: 24.0,
                          height: 24.0,
                        ),
                      ),
                      _getRichText(snapshot.data.inflorescence),
                    ]),
                  ),
                ));
                cards.add(Card(
                  child: Container(
                    padding: EdgeInsets.only(left: 10.0, bottom: 10.0, right: 10.0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      ListTile(
                        title: Text(S.of(context).plant_flower),
                        leading: Image(
                          image: AssetImage('res/images/ic_flower_grey_24dp.png'),
                          width: 24.0,
                          height: 24.0,
                        ),
                      ),
                      _getRichText(snapshot.data.flower),
                    ]),
                  ),
                ));
                cards.add(Card(
                  child: Container(
                    padding: EdgeInsets.only(left: 10.0, bottom: 10.0, right: 10.0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      ListTile(
                        title: Text(S.of(context).plant_fruit),
                        leading: Image(
                          image: AssetImage('res/images/ic_fruit_grey_24dp.png'),
                          width: 24.0,
                          height: 24.0,
                        ),
                      ),
                      _getRichText(snapshot.data.fruit),
                    ]),
                  ),
                ));
                cards.add(Card(
                  child: Container(
                    padding: EdgeInsets.only(left: 10.0, bottom: 10.0, right: 10.0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      ListTile(
                        title: Text(S.of(context).plant_leaf),
                        leading: Image(
                          image: AssetImage('res/images/ic_leaf_grey_24dp.png'),
                          width: 24.0,
                          height: 24.0,
                        ),
                      ),
                      _getRichText(snapshot.data.leaf),
                    ]),
                  ),
                ));
                cards.add(Card(
                  child: Container(
                    padding: EdgeInsets.only(left: 10.0, bottom: 10.0, right: 10.0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      ListTile(
                        title: Text(S.of(context).plant_stem),
                        leading: Image(
                          image: AssetImage('res/images/ic_stem_grey_24dp.png'),
                          width: 24.0,
                          height: 24.0,
                        ),
                      ),
                      _getRichText(snapshot.data.stem),
                    ]),
                  ),
                ));
                cards.add(Card(
                  child: Container(
                    padding: EdgeInsets.only(left: 10.0, bottom: 10.0, right: 10.0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      ListTile(
                        title: Text(S.of(context).plant_habitat),
                        leading: Image(
                          image: AssetImage('res/images/ic_home_grey_24dp.png'),
                          width: 24.0,
                          height: 24.0,
                        ),
                      ),
                      _getRichText(snapshot.data.habitat),
                    ]),
                  ),
                ));

                // optional attributes
                if (snapshot.data.toxicity != null) {
                  cards.add(Card(
                    child: Container(
                      padding: EdgeInsets.only(left: 10.0, bottom: 10.0, right: 10.0),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        ListTile(
                          title: Text(S.of(context).plant_toxicity),
                          leading: Image(
                            image: AssetImage('res/images/ic_toxicity_grey_24dp.png'),
                            width: 24.0,
                            height: 24.0,
                          ),
                        ),
                        _getRichText(snapshot.data.toxicity),
                      ]),
                    ),
                  ));
                }
                if (snapshot.data.herbalism != null) {
                  cards.add(Card(
                    child: Container(
                      padding: EdgeInsets.only(left: 10.0, bottom: 10.0, right: 10.0),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        ListTile(
                          title: Text(S.of(context).plant_herbalism),
                          leading: Image(
                            image: AssetImage('res/images/ic_local_pharmacy_grey_24dp.png'),
                            width: 24.0,
                            height: 24.0,
                          ),
                        ),
                        _getRichText(snapshot.data.herbalism),
                      ]),
                    ),
                  ));
                }
                if (snapshot.data.trivia != null) {
                  cards.add(Card(
                    child: Container(
                      padding: EdgeInsets.only(left: 10.0, bottom: 10.0, right: 10.0),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        ListTile(
                          title: Text(S.of(context).plant_trivia),
                          leading: Image(
                            image: AssetImage('res/images/ic_question_mark_grey_24dp.png'),
                            width: 24.0,
                            height: 24.0,
                          ),
                        ),
                        _getRichText(snapshot.data.trivia),
                      ]),
                    ),
                  ));
                }

                cards.add(Card(
                    child: FutureBuilder<Plant>(
                  future: _plantF,
                  builder: (BuildContext context, AsyncSnapshot<Plant> plantSnapshot) {
                    if (plantSnapshot.connectionState == ConnectionState.done) {
                      return Container(
                        padding: EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: _getSources(plantSnapshot.data, snapshot.data),
                        ),
                      );
                    } else {
                      return Container();
                    }
                  },
                )));

                return ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.all(5.0),
                  children: cards,
                );
              default:
                return Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator()]);
            }
          }),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.info), title: Text(S.of(context).filter_habitat)),
          BottomNavigationBarItem(icon: Icon(Icons.photo_library), title: Text(S.of(context).filter_petal)),
          BottomNavigationBarItem(icon: Icon(Icons.format_list_bulleted), title: Text(S.of(context).filter_distribution)),
        ],
        fixedColor: Colors.blue,
        onTap: (index) {},
      ),
    );
  }
}
