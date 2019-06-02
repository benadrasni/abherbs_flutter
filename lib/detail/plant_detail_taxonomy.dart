import 'dart:async';

import 'package:abherbs_flutter/entity/plant.dart';
import 'package:abherbs_flutter/entity/plant_translation.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../ads.dart';

final translationsTaxonomyReference = FirebaseDatabase.instance.reference().child(firebaseTranslationsTaxonomy);

Widget getTaxonomy(BuildContext context, Locale myLocale, Plant plant, Future<PlantTranslation> _plantTranslationF) {
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
    child: Container(
      padding: EdgeInsets.all(10.0),
      child: _getSynonyms(plant),
    ),
  ));

  cards.add(Card(
    child: Container(
      padding: EdgeInsets.all(10.0),
      child: _getTaxonomy(context, myLocale, plant),
    ),
  ));

  cards.add(Ads.getAdMobBanner());

  return ListView(
    shrinkWrap: true,
    padding: EdgeInsets.all(5.0),
    children: cards,
  );
}

Widget _getNames(Plant plant, PlantTranslation plantTranslation) {
  var names = <Text>[];
  names.add(Text(
    plantTranslation.label ?? plant.name,
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

Widget _getSynonyms(Plant plant) {
  var latinNames = <Text>[];
  latinNames.add(Text(
    plant.name,
    style: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 22.0,
    ),
    textAlign: TextAlign.center,
  ));
  if (plant.synonyms != null) {
    latinNames.add(Text(
      plant.synonyms.join(', '),
      style: TextStyle(
        fontStyle: FontStyle.italic,
        fontSize: 14.0,
      ),
      textAlign: TextAlign.center,
    ));
  }

  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: latinNames,
  );
}

Widget _getTaxonomy(BuildContext context, Locale myLocale, Plant plant) {
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
            child: Text(getTaxonLabel(context, taxonKey.substring(taxonKey.indexOf('_') + 1))),
            flex: 2,
          ),
          _getTaxonInLanguage(myLocale, plant.apgIV[taxonKey]),
        ])));
  }

  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: taxonTiles,
  );
}

Widget _getTaxonInLanguage(Locale myLocale, String taxon) {
  Future<String> translationF =
      translationsTaxonomyReference.child(getLanguageCode(myLocale.languageCode)).child(taxon).once().then((DataSnapshot snapshot) {
    if (snapshot.value != null && snapshot.value.length > 0) {
      return snapshot.value.join(', ');
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
              names.add(Text(snapshot.data, style: TextStyle(fontWeight: FontWeight.bold)));
            }
          }
          names.add(Text(taxon));

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: names,
          );
        }),
    flex: 3,
  );
}
