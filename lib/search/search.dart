import 'package:abherbs_flutter/ads.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/search/search_names.dart';
import 'package:abherbs_flutter/search/search_taxonomy.dart';
import 'package:abherbs_flutter/utils.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

final searchReference = FirebaseDatabase.instance.reference().child(firebaseSearch);

class Search extends StatefulWidget {
  final Locale myLocale;
  final void Function(String) onChangeLanguage;
  final void Function() onBuyProduct;
  Search(this.myLocale, this.onChangeLanguage, this.onBuyProduct);

  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  int _currentIndex;
  GlobalKey<ScaffoldState> _key;
  Future<Map<dynamic, dynamic>> _nativeNamesF;
  Future<Map<dynamic, dynamic>> _latinNamesF;

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

    _currentIndex = 0;
    _key = new GlobalKey<ScaffoldState>();

    _nativeNamesF = searchReference.child(widget.myLocale.languageCode).once().then((DataSnapshot snapshot) {
      return snapshot.value;
    });
    _latinNamesF = searchReference.child(languageLatin).once().then((DataSnapshot snapshot) {
      return snapshot.value;
    });

    Ads.hideBannerAd();
  }

  Widget _getBody(BuildContext context, Map<dynamic, dynamic> nativeNames, Map<dynamic, dynamic> latinNames) {
    switch (_currentIndex) {
      case 0:
        return searchNames(widget.myLocale, widget.onChangeLanguage, widget.onBuyProduct, context, nativeNames, latinNames, _searchText);
      case 1:
        return searchTaxonomy(context);
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
      body: FutureBuilder<List<Object>>(
        future: Future.wait([_nativeNamesF, _latinNamesF]),
        builder: (BuildContext context, AsyncSnapshot<List<Object>> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              return _getBody(context, snapshot.data[0], snapshot.data[1]);
            default:
              return const CircularProgressIndicator();
          }
        },
      ),
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
