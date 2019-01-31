import 'dart:async';

import 'package:abherbs_flutter/plant_list.dart';
import 'package:abherbs_flutter/utils.dart';
import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';

Widget searchNames(Locale myLocale, Function(String) onChangeLanguage, Function() onBuyProduct, String searchText,
    Future<Map<dynamic, dynamic>> _nativeNamesF, Future<Map<dynamic, dynamic>> _latinNamesF) {
  return FutureBuilder<List<Object>>(
    future: Future.wait([_nativeNamesF, _latinNamesF]),
    builder: (BuildContext context, AsyncSnapshot<List<Object>> snapshot) {
      switch (snapshot.connectionState) {
        case ConnectionState.done:
          return _getBody(myLocale, onChangeLanguage, onBuyProduct, searchText, snapshot.data[0], snapshot.data[1]);
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

Widget _getBody(Locale myLocale, Function(String) onChangeLanguage, Function() onBuyProduct, String searchText, Map<dynamic, dynamic> nativeNames,
    Map<dynamic, dynamic> latinNames) {
  var filteredNativeNames = <String>[];
  nativeNames.forEach((key, value) {
    if (searchText.isEmpty || removeDiacritics(key).toLowerCase().contains(searchText.toLowerCase())) {
      filteredNativeNames.add(key);
    }
  });
  filteredNativeNames.sort();

  var filteredLatinNames = <String>[];
  latinNames.forEach((key, value) {
    if (searchText.isEmpty || key.toLowerCase().contains(searchText.toLowerCase())) {
      filteredLatinNames.add(key);
    }
  });
  filteredLatinNames.sort();

  return Column(
    children: [
      Expanded(
        child: Card(
          child: ListView.builder(
            itemCount: filteredNativeNames.length,
            itemBuilder: (BuildContext context, int index) {
              return GestureDetector(
                child: Container(
                  padding: new EdgeInsets.all(10.0),
                  child: Text(
                    filteredNativeNames[index],
                    style: TextStyle(fontSize: 16.0),
                  ),
                ),
                onTap: () {
                  String path = '/' + firebaseSearch + '/' + myLocale.languageCode + '/' + filteredNativeNames[index];
                  Map<dynamic, dynamic> value = nativeNames[filteredNativeNames[index]];
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PlantList(onChangeLanguage, onBuyProduct, {}, value.length.toString(), path)),
                  );
                },
              );
            },
          ),
        ),
        flex: 1,
      ),
      Expanded(
        child: Card(
          child: ListView.builder(
            itemCount: filteredLatinNames.length,
            itemBuilder: (BuildContext context, int index) {
              return GestureDetector(
                child: Container(
                  padding: new EdgeInsets.all(10.0),
                  child: Text(
                    filteredLatinNames[index],
                    style: TextStyle(fontSize: 16.0),
                  ),
                ),
                onTap: () {
                  String path = '/' + firebaseSearch + '/' + languageLatin + '/' + filteredLatinNames[index];
                  Map<dynamic, dynamic> value = latinNames[filteredLatinNames[index]];
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PlantList(onChangeLanguage, onBuyProduct, {}, value.length.toString(), path)),
                  );
                },
              );
            },
          ),
        ),
        flex: 1,
      )
    ],
  );
}
