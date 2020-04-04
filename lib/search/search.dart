import 'dart:async';

import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/settings/offline.dart';
import 'package:abherbs_flutter/search/search_names.dart';
import 'package:abherbs_flutter/search/search_taxonomy.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class Search extends StatefulWidget {
  final Locale myLocale;
  final void Function(String) onChangeLanguage;
  Search(this.myLocale, this.onChangeLanguage);

  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  int _currentIndex;
  GlobalKey<ScaffoldState> _key;
  Future<Map<dynamic, dynamic>> _nativeNamesF;
  Future<Map<dynamic, dynamic>> _latinNamesF;
  Future<Map<dynamic, dynamic>> _apgIVF;
  Future<Map<dynamic, dynamic>> _translationsTaxonomyF;

  final TextEditingController _filter = TextEditingController();
  String _searchText = '';

  _SearchState() {
    _filter.addListener(() {
      setState(() {
        _searchText = _filter.text;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    Offline.setKeepSynced(4, true);

    _currentIndex = 0;
    _key = new GlobalKey<ScaffoldState>();
  }

  Widget _getBody() {
    switch (_currentIndex) {
      case 0:
        if (_nativeNamesF == null) {
          searchReference.child(getLanguageCode(widget.myLocale.languageCode)).keepSynced(true);
          _nativeNamesF = searchReference.child(getLanguageCode(widget.myLocale.languageCode)).once().then((DataSnapshot snapshot) {
            return snapshot.value;
          });
        }
        if (_latinNamesF == null) {
          searchReference.child(languageLatin).keepSynced(true);
          _latinNamesF = searchReference.child(languageLatin).once().then((DataSnapshot snapshot) {
            return snapshot.value;
          });
        }
        return searchNames(widget.myLocale, widget.onChangeLanguage, _searchText, _nativeNamesF, _latinNamesF);
      case 1:
        if (_apgIVF == null) {
          apgIVReference.keepSynced(true);
          _apgIVF = apgIVReference.once().then((DataSnapshot snapshot) {
            return snapshot.value;
          });
        }
        if (_translationsTaxonomyF == null) {
          translationsTaxonomyReference.child(getLanguageCode(widget.myLocale.languageCode)).keepSynced(true);
          _translationsTaxonomyF = translationsTaxonomyReference.child(getLanguageCode(widget.myLocale.languageCode)).once().then((DataSnapshot snapshot) {
            return snapshot.value;
          });
        }
        return searchTaxonomy(widget.myLocale, widget.onChangeLanguage, _searchText, _apgIVF, _translationsTaxonomyF);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      appBar: AppBar(
        title: TextField(
          controller: _filter,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: S.of(context).search,
          ),
        ),
      ),
      body: _getBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.search), title: Text(S.of(context).search_names)),
          BottomNavigationBarItem(icon: Icon(Icons.find_in_page), title: Text(S.of(context).search_taxonomy)),
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
