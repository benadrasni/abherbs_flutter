import 'dart:async';

import 'package:abherbs_flutter/plant_list.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';

var supportedLanguages = {
  "cs": "Čeština",
  "da": "Dansk",
  "de": "Deutsch",
  "en": "English",
  "es": "Español",
  "et": "Eesti",
  "fr": "Français",
  "hr": "Hrvatski",
  "it": "Italiano",
  "lv": "Latviešu",
  "lt": "Lietuvių",
  "hu": "Magyar",
  "nl": "Nederlands",
  "ja": "日本語",
  "nb": "Norsk",
  "pl": "Polski",
  "pt": "Português",
  "ro": "Română",
  "ru": "Русский",
  "sk": "Slovenčina",
  "sl": "Slovenščina",
  "sr": "Српски / srpski",
  "sv": "Svenska",
  "fi": "Suomi",
  "uk": "Українська"
};

Widget searchNames(Locale myLocale, Function(String) onChangeLanguage, String searchText,
    Future<Map<dynamic, dynamic>> _nativeNamesF, Future<Map<dynamic, dynamic>> _latinNamesF) {
  return FutureBuilder<List<Object>>(
    future: Future.wait([_nativeNamesF, _latinNamesF]),
    builder: (BuildContext context, AsyncSnapshot<List<Object>> snapshot) {
      switch (snapshot.connectionState) {
        case ConnectionState.done:
          return _getBody(myLocale, onChangeLanguage, searchText, snapshot.data[0], snapshot.data[1]);
        default:
          return Container(
            child: Center(
              child: const CircularProgressIndicator(),
            ),
          );
      }
    },
  );
}

Widget _getBody(Locale myLocale, Function(String) onChangeLanguage, String searchText, Map<dynamic, dynamic> nativeNames,
    Map<dynamic, dynamic> latinNames) {
  var filteredNativeNames = <String>[];
  var searchTextWithoutDiacritics = removeDiacritics(searchText).toLowerCase();
  if (nativeNames != null) {
    nativeNames.forEach((key, value) {
      if (searchText.isEmpty || removeDiacritics(key).toLowerCase().contains(searchTextWithoutDiacritics)) {
        filteredNativeNames.add(key);
      }
    });
    filteredNativeNames.sort();
  }

  var filteredLatinNames = <String>[];
  latinNames.forEach((key, value) {
    if (searchText.isEmpty || key.toLowerCase().contains(searchTextWithoutDiacritics)) {
      filteredLatinNames.add(key);
    }
  });
  filteredLatinNames.sort();

  var widgets = <Widget>[];
  if (supportedLanguages[myLocale.languageCode] != null) {
    widgets.add(Expanded(
      child: Card(
        child: ListView.builder(
          itemCount: filteredNativeNames.length,
          itemBuilder: (BuildContext context, int index) {
            return GestureDetector(
              child: Container(
                padding: new EdgeInsets.all(10.0),
                child: Text(
                  filteredNativeNames[index],
                  style: TextStyle(fontSize: 16.0, fontWeight: nativeNames[filteredNativeNames[index]][firebaseAttributeIsLabel] != null ? FontWeight.bold : FontWeight.normal),
                ),
              ),
              onTap: () {
                String path = '/' + firebaseSearch + '/' + getLanguageCode(myLocale.languageCode) + '/' + filteredNativeNames[index] + '/' + firebaseAttributeList;
                var value = nativeNames[filteredNativeNames[index]][firebaseAttributeList];
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PlantList(onChangeLanguage, {}, '', value.length.toString(), path)),
                );
              },
            );
          },
        ),
      ),
      flex: 1,
    ));
  }

  widgets.add(Expanded(
    child: Card(
      child: ListView.builder(
        itemCount: filteredLatinNames.length,
        itemBuilder: (BuildContext context, int index) {
          return GestureDetector(
            child: Container(
              padding: new EdgeInsets.all(10.0),
              child: Text(
                filteredLatinNames[index],
                style: TextStyle(fontSize: 16.0, fontWeight: latinNames[filteredLatinNames[index]][firebaseAttributeIsLabel] != null ? FontWeight.bold : FontWeight.normal),
              ),
            ),
            onTap: () {
              String path = '/' + firebaseSearch + '/' + languageLatin + '/' + filteredLatinNames[index] + '/' + firebaseAttributeList;
              var value = latinNames[filteredLatinNames[index]][firebaseAttributeList];
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PlantList(onChangeLanguage, {}, '', value.length.toString(), path)),
              );
            },
          );
        },
      ),
    ),
    flex: 1,
  ));

  return Column(
    children: widgets,
  );
}
