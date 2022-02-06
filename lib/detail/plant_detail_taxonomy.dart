import 'dart:async';

import 'package:abherbs_flutter/detail/plant_detail_synonyms.dart';
import 'package:abherbs_flutter/entity/plant.dart';
import 'package:abherbs_flutter/entity/plant_translation.dart';
import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/settings/settings_remote.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:flutter/material.dart';

Widget getTaxonomy(BuildContext context, Locale myLocale, Plant plant, Future<PlantTranslation> _plantTranslationF, double _fontSize) {
  Future<List<String>> _firstSynonymF = synonymsReference.child(plant.name).child(firebaseAttributeIPNI).once().then((event) {
    List<String> result = [];
    if (event.snapshot.value != null) {
      result.add([(event.snapshot.value as List).first['name'], (event.snapshot.value as List).first['suffix']].join(' '));
      result.add((event.snapshot.value as List).first['author']);
    }
    return result;
  });

  List<Widget> cards = [];

  cards.add(Card(
      child: FutureBuilder<PlantTranslation>(
    future: _plantTranslationF,
    builder: (BuildContext context, AsyncSnapshot<PlantTranslation> plantTranslationSnapshot) {
      if (plantTranslationSnapshot.connectionState == ConnectionState.done) {
        return Container(padding: EdgeInsets.only(top: 15.0, bottom: 15.0), child: _getNames(plant, plantTranslationSnapshot.data));
      } else {
        return Container();
      }
    },
  )));

  cards.add(Card(
    child: Column(
      children: [
        Container(
          padding: EdgeInsets.only(top: 10.0),
          child: Text(
            S.of(context).plant_scientific_label,
          ),
        ),
        ListTile(
          title: Text(
            plant.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22.0,
            ),
            textAlign: TextAlign.center,
          ),
          subtitle: Text(
            plant.author ?? '',
            style: TextStyle(
              fontSize: 18.0,
            ),
            textAlign: TextAlign.center,
          ),
          onTap: () {
            if (plant.ipniId != null) {
              launchURL(RemoteConfiguration.remoteConfig.getString(remoteConfigIPNIServerWithTaxon) + plant.ipniId);
            }
          },
        ),
        FutureBuilder<List<String>>(
          future: _firstSynonymF,
          builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
            if (snapshot.connectionState == ConnectionState.done && snapshot.data.length > 0) {
              return GestureDetector(
                child: Column(children: [
                  Container(
                    child: Text(
                      S.of(context).plant_synonyms,
                    ),
                  ),
                  ListTile(
                    title: Text(
                      snapshot.data[0],
                      style: TextStyle(
                        fontSize: 18.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    subtitle: Text(
                      snapshot.data[1],
                      style: TextStyle(
                        fontSize: 16.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    leading: Icon(Icons.arrow_right),
                    trailing: Icon(Icons.insert_link),
                  ),
                  Container(
                    padding: EdgeInsets.only(bottom: 10.0),
                    child: Text(
                      S.of(context).plant_tap_synonyms,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16.0,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ]),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PlantSynonyms(myLocale, plant), settings: RouteSettings(name: 'PlantSynonyms')),
                  );
                },
              );
            } else {
              return Container();
            }
          },
        ),
      ],
    ),
  ));

  cards.add(Card(
    child: Container(
      padding: EdgeInsets.all(10.0),
      child: _getTaxonomy(context, myLocale, plant, _fontSize),
    ),
  ));

  return ListView(
    shrinkWrap: true,
    padding: EdgeInsets.all(5.0),
    children: cards,
  );
}

Widget _getNames(Plant plant, PlantTranslation plantTranslation) {
  var names = <Text>[];
  names.add(Text(
    plantTranslation?.label ?? plant.name,
    style: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 22.0,
    ),
    textAlign: TextAlign.center,
  ));
  if (plantTranslation.names != null) {
    names.add(Text(
      plantTranslation.names.join(', '),
      style: TextStyle(
        fontStyle: FontStyle.italic,
        fontSize: 14.0,
      ),
      textAlign: TextAlign.center,
    ));
  }

  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: names,
  );
}

Widget _getTaxonomy(BuildContext context, Locale myLocale, Plant plant, double fontSize) {
  var taxonTiles = <Widget>[];

  var taxonKeys = <String>[];
  for (var item in plant.apgIV.keys) {
    taxonKeys.add(item);
  }
  taxonKeys.sort();
  for (var taxonKey in taxonKeys) {
    taxonTiles.add(Container(
        padding: EdgeInsets.only(top: 5.0, bottom: 5.0),
        child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          Expanded(
            child: Text(getTaxonLabel(context, taxonKey.substring(taxonKey.indexOf('_') + 1)), style: TextStyle(fontSize: fontSize)),
            flex: 2,
          ),
          _getTaxonInLanguage(myLocale, plant.apgIV[taxonKey], fontSize),
        ])));
  }

  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: taxonTiles,
  );
}

Widget _getTaxonInLanguage(Locale myLocale, String taxon, double fontSize) {
  Future<String> translationF = translationsTaxonomyReference.child(getLanguageCode(myLocale.languageCode)).child(taxon).once().then((event) {
    if (event.snapshot.value != null && (event.snapshot.value as List).length > 0) {
      return (event.snapshot.value as List).join(', ');
    } else {
      return null;
    }
  });

  return Expanded(
    child: FutureBuilder<String>(
        future: translationF,
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          var names = <Text>[];

          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.data != null) {
              names.add(Text(snapshot.data, style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)));
            }
          }
          names.add(Text(
            taxon,
            style: TextStyle(fontSize: fontSize),
          ));

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: names,
          );
        }),
    flex: 3,
  );
}
