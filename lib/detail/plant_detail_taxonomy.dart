import 'dart:async';

import 'package:abherbs_flutter/detail/plant_detail_synonyms.dart';
import 'package:abherbs_flutter/entity/plant.dart';
import 'package:abherbs_flutter/entity/plant_translation.dart';
import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../ads.dart';

Widget getTaxonomy(BuildContext context, Locale myLocale, Plant plant, Future<PlantTranslation> _plantTranslationF, double _fontSize) {
  Future<int> _countSynonymsF = synonymsReference.child(plant.name).child(firebaseAttributeIPNI).once().then((DataSnapshot snapshot) {
    return snapshot.value?.length ?? 0;
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
          padding: EdgeInsets.only(top: 15.0, bottom: 10.0),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(
              plant.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22.0,
              ),
              textAlign: TextAlign.center,
            ),
            Text('  '),
            Text(
              plant.author ?? '',
              style: TextStyle(
                fontSize: 18.0,
              ),
              textAlign: TextAlign.center,
            ),
          ]),
        ),
        FutureBuilder<int>(
          future: _countSynonymsF,
          builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
            if (snapshot.connectionState == ConnectionState.done && snapshot.data > 0) {
              return ListTile(
                title: Center(
                    child: Text(
                  S.of(context).plant_tap_synonyms,
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                    fontSize: 16.0,
                  ),
                )),
                leading: Icon(Icons.library_books),
                trailing: Icon(Icons.library_books),
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

  cards.add(Ads.getAdMobBigBanner());

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
  Future<String> translationF = translationsTaxonomyReference.child(getLanguageCode(myLocale.languageCode)).child(taxon).once().then((DataSnapshot snapshot) {
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
