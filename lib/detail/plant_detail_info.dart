import 'dart:async';

import 'package:abherbs_flutter/entity/plant.dart';
import 'package:abherbs_flutter/entity/plant_translation.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

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

Widget getInfo(BuildContext context, Locale myLocale, bool isOriginal, Future<Plant> _plantF, Future<PlantTranslation> _plantTranslationF,
    Function(bool) onChangeTranslation, GlobalKey<ScaffoldState> key) {
  return FutureBuilder<PlantTranslation>(
      future: _plantTranslationF,
      builder: (BuildContext context, AsyncSnapshot<PlantTranslation> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.done:
            List<Widget> cards = [];

            cards.add(Card(
                child: FutureBuilder<Plant>(
              future: _plantF,
              builder: (BuildContext context, AsyncSnapshot<Plant> plantSnapshot) {
                if (plantSnapshot.connectionState == ConnectionState.done) {
                  return Container(
                    padding: EdgeInsets.only(top: 15.0, bottom: 15.0),
                    child: _getNames(context, plantSnapshot.data, snapshot.data, key),
                  );
                } else {
                  return Container();
                }
              },
            )));

            cards.add(Card(
                child: FutureBuilder<Plant>(
              future: _plantF,
              builder: (BuildContext context, AsyncSnapshot<Plant> plantSnapshot) {
                if (plantSnapshot.connectionState == ConnectionState.done) {
                  return Container(
                    padding: EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _getDescription(context, myLocale, plantSnapshot.data, snapshot.data),
                    ),
                  );
                } else {
                  return Container();
                }
              },
            )));

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

            if (snapshot.data.isTranslatedWithGT) {
              cards.add(Card(
                child: Container(
                  padding: EdgeInsets.all(10.0),
                  decoration: new BoxDecoration(
                    borderRadius: new BorderRadius.circular(16.0),
                    color: Theme.of(context).secondaryHeaderColor,
                  ),
                  child: Column(
                    children: [
                      Text(S.of(context).google_translate),
                      Container(
                        width: 300.0,
                        child: RaisedButton(
                          onPressed: () {
                            onChangeTranslation(!isOriginal);
                          },
                          child: new Text(isOriginal ? S.of(context).show_translation : S.of(context).show_original),
                        ),
                      ),
                      FutureBuilder<Plant>(
                        future: _plantF,
                        builder: (BuildContext context, AsyncSnapshot<Plant> plantSnapshot) {
                          if (plantSnapshot.connectionState == ConnectionState.done) {
                            return Container(
                              width: 300.0,
                              child: RaisedButton(
                                onPressed: () {
                                  launchURL(webUrl +
                                      'translate_flower?lang=' +
                                      getLanguageCode(myLocale.languageCode) +
                                      "&plant=" +
                                      plantSnapshot.data.name);
                                },
                                child: new Text(S.of(context).improve_translation),
                              ),
                            );
                          } else {
                            return Container();
                          }
                        },
                      ),
                    ],
                  ),
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
                      children: _getSources(context, plantSnapshot.data, snapshot.data),
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
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(),
                CircularProgressIndicator(),
                Container(),
              ],
            );
        }
      });
}

const TextStyle _defaultTextStyle = TextStyle(
  fontSize: 16.0,
  color: Colors.black,
);

Widget _getNames(BuildContext context, Plant plant, PlantTranslation plantTranslation, GlobalKey<ScaffoldState> key) {
  var names = <Widget>[];
  names.add(GestureDetector(
    child: Text(
      plantTranslation.label,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 22.0,
      ),
      textAlign: TextAlign.center,
    ),
    onLongPress: () {
      Clipboard.setData(new ClipboardData(text: plantTranslation.label));
      key.currentState.showSnackBar(SnackBar(
        content: Text(S.of(context).snack_copy),
      ));
    },
  ));
  if (plantTranslation.names != null) {
    names.add(GestureDetector(
      child: Text(
        plantTranslation.names.take(3).join(', '),
        style: TextStyle(
          fontStyle: FontStyle.italic,
          fontSize: 14.0,
        ),
        textAlign: TextAlign.center,
      ),
      onLongPress: () {
        Clipboard.setData(new ClipboardData(text: plantTranslation.label));
        key.currentState.showSnackBar(SnackBar(
          content: Text(S.of(context).snack_copy),
        ));
      },
    ));
  }

  Widget result;
  if (plant.toxicityClass > 0) {
    result = Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          child: Image(
            image: AssetImage(plant.toxicityClass == 1 ? 'res/images/toxicity1.png' : 'res/images/toxicity2.png'),
            width: 50.0,
            height: 50.0,
          ),
          flex: 1,
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: names,
          ),
          flex: 4,
        )
      ],
    );
  } else {
    result = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: names,
    );
  }

  return result;
}

List<Widget> _getDescription(BuildContext context, Locale myLocale, Plant plant, PlantTranslation plantTranslation) {
  var descriptionWidgets = <Widget>[];

  descriptionWidgets.add(Row(children: [
    Text(
      S.of(context).plant_height_from,
      style: _defaultTextStyle,
    ),
    Text(' '),
    Text(
      plant.heightFrom.toString(),
      style: _defaultTextStyle,
    ),
    Text(' '),
    Text(
      S.of(context).plant_height_to,
      style: _defaultTextStyle,
    ),
    Text(' '),
    Text(
      plant.heightTo.toString(),
      style: _defaultTextStyle,
    ),
    Text(' '),
    Text(
      heightUnitOfMeasure,
      style: _defaultTextStyle,
    ),
  ]));

  descriptionWidgets.add(Row(children: [
    Text(
      S.of(context).plant_flowering_from,
      style: _defaultTextStyle,
    ),
    Text(' '),
    Text(
      DateFormat.MMMM(myLocale.languageCode).format(DateTime(0, plant.floweringFrom)),
      style: _defaultTextStyle,
    ),
    Text(' '),
    Text(
      S.of(context).plant_flowering_to,
      style: _defaultTextStyle,
    ),
    Text(' '),
    Text(
      DateFormat.MMMM(myLocale.languageCode).format(DateTime(0, plant.floweringTo)),
      style: _defaultTextStyle,
    ),
  ]));

  descriptionWidgets.add(_getRichText(plantTranslation.description));

  return descriptionWidgets;
}

List<Widget> _getSources(BuildContext context, Plant plant, PlantTranslation plantTranslation) {
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
      S.of(context).plant_sources,
      style: TextStyle(
        fontSize: 22.0,
      ),
      textAlign: TextAlign.center,
    ));

    for (int i = 0; i < sources.length; i += 3) {
      var sourceButtons = <Widget>[];
      for (int j = 0; j < 3; j++) {
        if (i + j < sources.length) {
          sourceButtons.add(getSourceButton(sources[i + j]));
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

FlatButton getSourceButton(String url) {
  assert(url.contains('//') && url.contains('/'), url.indexOf('//') + 2);
  String imageSource = 'res/images/internet.png';
  String textSource = url.substring(url.indexOf('//') + 2, url.indexOf('/', url.indexOf('//') + 2));

  if (url.contains(sourceWikipedia)) {
    imageSource = 'res/images/wikipedia.png';
    textSource = sourceWikipedia;
  } else if (url.contains(sourceWikimediaCommons)) {
    imageSource = 'res/images/commons.png';
    textSource = sourceWikimediaCommonsTitle;
  } else if (url.contains(sourceWikimediaData)) {
    imageSource = 'res/images/wikidata.png';
    textSource = sourceWikimediaDataTitle;
  } else if (url.contains(sourceWikimediaSpecies)) {
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
        style: TextStyle(fontSize: 12.0),
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
      style: _defaultTextStyle,
      children: sections,
    ),
  );
}
