import 'dart:async';

import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/settings/offline.dart';
import 'package:abherbs_flutter/search/search_names.dart';
import 'package:abherbs_flutter/search/search_taxonomy.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:flutter/material.dart';

class Search extends StatefulWidget {
  final Locale myLocale;
  Search(this.myLocale);

  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  Future<Map<dynamic, dynamic>>? _nativeNamesF;
  Future<Map<dynamic, dynamic>>? _latinNamesF;
  Future<Map<dynamic, dynamic>>? _apgIVF;
  Future<Map<dynamic, dynamic>>? _translationsTaxonomyF;

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
  }

  Widget _getBody() {
    switch (_currentIndex) {
      case 0:
        if (_nativeNamesF == null) {
          searchReference.child(getLanguageCode(widget.myLocale.languageCode)).keepSynced(true);
          _nativeNamesF = searchReference.child(getLanguageCode(widget.myLocale.languageCode)).once().then((event) {
            return event.snapshot.value as Map;
          });
        }
        if (_latinNamesF == null) {
          searchReference.child(languageLatin).keepSynced(true);
          _latinNamesF = searchReference.child(languageLatin).once().then((event) {
            return event.snapshot.value as Map;
          });
        }
        return searchNames(widget.myLocale, _searchText, _nativeNamesF!, _latinNamesF!);
      case 1:
        if (_apgIVF == null) {
          apgIVReference.keepSynced(true);
          _apgIVF = apgIVReference.once().then((event) {
            return event.snapshot.value as Map;
          });
        }
        if (_translationsTaxonomyF == null) {
          translationsTaxonomyReference.child(getLanguageCode(widget.myLocale.languageCode)).keepSynced(true);
          _translationsTaxonomyF = translationsTaxonomyReference.child(getLanguageCode(widget.myLocale.languageCode)).once().then((event) {
            return event.snapshot.value as Map;
          });
        }
        return searchTaxonomy(widget.myLocale, _searchText, _apgIVF!, _translationsTaxonomyF!);
    }
    return Column(
      children: <Widget>[],
    );
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
          BottomNavigationBarItem(icon: Icon(Icons.search), label: S.of(context).search_names),
          BottomNavigationBarItem(icon: Icon(Icons.find_in_page), label: S.of(context).search_taxonomy),
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
