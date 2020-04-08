import 'dart:async';

import 'package:abherbs_flutter/entity/plant_taxon.dart';
import 'package:abherbs_flutter/plant_list.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';

Widget searchTaxonomy(Locale myLocale, Function(String) onChangeLanguage, String searchText,
    Future<Map<dynamic, dynamic>> _apgIVF, Future<Map<dynamic, dynamic>> _translationsTaxonomyF) {
  return FutureBuilder<List<Object>>(
    future: Future.wait([_apgIVF, _translationsTaxonomyF]),
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

Widget _getBody(Locale myLocale, Function(String) onChangeLanguage, String searchText, Map<dynamic, dynamic> apgIV,
    Map<dynamic, dynamic> dictionary) {
  var _taxons = <PlantTaxon>[];
  _buildTaxonomy(_taxons, dictionary, apgIV[firebaseRootTaxon], 0, firebaseAPGIV + '/', firebaseRootTaxon, searchText);

  return Card(
    child: ListView.builder(
      itemCount: _taxons.length,
      itemBuilder: (BuildContext context, int index) {
        int offsetInt = _taxons[index].offset * 2;
        double offset = offsetInt.toDouble();
        return GestureDetector(
          child: Container(
            padding: new EdgeInsets.all(10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(padding: EdgeInsets.only(left: offset), child: _getName(_taxons[index])),
                  flex: 4,
                ),
                Expanded(
                  child: Text(
                    _taxons[index].count == null ? '' : '(' + _taxons[index].count.toString() + ')',
                    style: TextStyle(
                      fontSize: 16.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  flex: 1,
                ),
                Expanded(
                  child: Text(
                    getTaxonLabel(context, _taxons[index].type),
                    style: TextStyle(
                      fontSize: 16.0,
                    ),
                  ),
                  flex: 2,
                ),
              ],
            ),
          ),
          onTap: () {
            if (_taxons[index].count != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => PlantList(onChangeLanguage, {}, '',  rootReference.child(_taxons[index].path))),
              );
            }
          },
        );
      },
    ),
  );
}

Column _getName(PlantTaxon taxon) {
  if (taxon.names != null && taxon.names.length > 0) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          taxon.names.join(', '),
          style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
        ),
        Text(
          taxon.latinName,
          style: TextStyle(fontSize: 14.0, fontStyle: FontStyle.italic),
        ),
      ],
    );
  } else {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          taxon.latinName,
          style: TextStyle(fontSize: 16.0),
        )
      ],
    );
  }
}

bool _isInNames(List<dynamic> names, String searchText) {
  if (names != null) {
    var searchTextWithoutDiacritics = removeDiacritics(searchText).toLowerCase();
    for (String name in names) {
      if (removeDiacritics(name).toLowerCase().contains(searchTextWithoutDiacritics)) {
        return true;
      }
    }
  }
  return false;
}

void _buildTaxonomy(List<PlantTaxon> taxons, Map<dynamic, dynamic> dictionary, Map<dynamic, dynamic> taxonomy, int offset, String path,
    String taxonName, String searchText) {
  List<dynamic> names = dictionary[taxonName];
  if (searchText.isEmpty || taxonName.toLowerCase().contains(searchText.toLowerCase()) || _isInNames(names, searchText)) {
    PlantTaxon taxon = PlantTaxon();
    taxon.path = path + taxonName + '/' + firebaseAttributeList;
    taxon.offset = offset;
    taxon.type = taxonomy[firebaseAPGType];
    taxon.latinName = taxonName;
    taxon.names = names;
    taxon.count = taxonomy[firebaseAttributeCount];
    taxons.add(taxon);
  }

  taxonomy.forEach((key, value) {
    if (firebaseAPGType != key && firebaseAttributeList != key && firebaseAttributeCount != key && firebaseAttributeFreebase != key) {
      _buildTaxonomy(taxons, dictionary, value, offset + 1, path + taxonName + '/', key, searchText);
    }
  });
}
