import 'dart:async';

import 'package:abherbs_flutter/ads.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/offline.dart';
import 'package:abherbs_flutter/search/search_names.dart';
import 'package:abherbs_flutter/search/search_taxonomy.dart';
import 'package:abherbs_flutter/utils.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class Search extends StatefulWidget {
  final Locale myLocale;
  final void Function(String) onChangeLanguage;
  final void Function(PurchasedItem) onBuyProduct;
  Search(this.myLocale, this.onChangeLanguage, this.onBuyProduct);

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

  final TextEditingController _filter = new TextEditingController();
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

    Ads.hideBannerAd();
  }

  Widget _getBody() {
    switch (_currentIndex) {
      case 0:
        if (_nativeNamesF == null) {
          _nativeNamesF = searchReference.child(getLanguageCode(widget.myLocale.languageCode)).once().then((DataSnapshot snapshot) {
            return snapshot.value;
          });
        }
        if (_latinNamesF == null) {
          _latinNamesF = searchReference.child(languageLatin).once().then((DataSnapshot snapshot) {
            return snapshot.value;
          });
        }
        return searchNames(widget.myLocale, widget.onChangeLanguage, widget.onBuyProduct, _searchText, _nativeNamesF, _latinNamesF);
      case 1:
        if (_apgIVF == null) {
          _apgIVF = apgIVReference.once().then((DataSnapshot snapshot) {
            return snapshot.value;
          });
        }
        if (_translationsTaxonomyF == null) {
          _translationsTaxonomyF = translationsTaxonomyReference.child(getLanguageCode(widget.myLocale.languageCode)).once().then((DataSnapshot snapshot) {
            return snapshot.value;
          });
        }
        return searchTaxonomy(widget.myLocale, widget.onChangeLanguage, widget.onBuyProduct, _searchText, _apgIVF, _translationsTaxonomyF);
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
