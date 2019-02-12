import 'dart:async';

import 'package:abherbs_flutter/ads.dart';
import 'package:abherbs_flutter/detail/plant_detail.dart';
import 'package:abherbs_flutter/drawer.dart';
import 'package:abherbs_flutter/filter/filter_utils.dart';
import 'package:abherbs_flutter/firebase_animated_index_list.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/offline.dart';
import 'package:abherbs_flutter/prefs.dart';
import 'package:abherbs_flutter/utils.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

final rootReference = FirebaseDatabase.instance.reference();
final countsReference = FirebaseDatabase.instance.reference().child(firebaseCounts);
final listsReference = FirebaseDatabase.instance.reference().child(firebasePlantHeaders);
final keysReference = FirebaseDatabase.instance.reference().child(firebaseLists);
final translationsReference = FirebaseDatabase.instance.reference().child(firebaseTranslations);
final translationsTaxonomyReference = FirebaseDatabase.instance.reference().child(firebaseTranslationsTaxonomy);

class PlantList extends StatefulWidget {
  final void Function(String) onChangeLanguage;
  final void Function(PurchasedItem) onBuyProduct;
  final Map<String, String> filter;
  final String count;
  final String path;
  PlantList(this.onChangeLanguage, this.onBuyProduct, this.filter, [this.count, this.path]);

  @override
  _PlantListState createState() => _PlantListState();
}

class _PlantListState extends State<PlantList> {
  Future<int> _count;
  Map<String, String> _translationCache;

  Widget _getImageButton(BuildContext context, Locale myLocale, String url, String name) {
    var placeholder = Stack(alignment: Alignment.center, children: [
      CircularProgressIndicator(),
      Image(
        image: AssetImage('res/images/placeholder.webp'),
      ),
    ]);
    return FlatButton(
      padding: EdgeInsets.all(10.0),
      child: getImage(url, placeholder),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PlantDetail(myLocale, widget.onChangeLanguage, widget.onBuyProduct, widget.filter, name)),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    Offline.setKeepSynced2(true);

    if (widget.count != null) {
      _count = Future<int>(() {
        return int.parse(widget.count);
      });
    } else {
      _count = countsReference.child(getFilterKey(widget.filter)).once().then((DataSnapshot snapshot) {
        return snapshot.value;
      });
    }

    _translationCache = {};

    Ads.hideBannerAd();
  }

  @override
  Widget build(BuildContext context) {
    var mainContext = context;
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).list_info),
      ),
      drawer: AppDrawer(widget.onChangeLanguage, widget.onBuyProduct, widget.filter, null),
      body: Container(
        child: Column(
          children: <Widget>[
            Flexible(
              child: FirebaseAnimatedIndexList(
                  query: listsReference,
                  keyQuery: widget.path != null ? rootReference.child(widget.path) : keysReference.child(getFilterKey(widget.filter)),
                  itemBuilder: (_, DataSnapshot snapshot, Animation<double> animation, int index) {
                    String name = snapshot.value['name'];
                    String family = snapshot.value['family'];

                    Locale myLocale = Localizations.localeOf(context);
                    Future<String> nameF = _translationCache.containsKey(name)
                        ? new Future<String>(() {
                            return _translationCache[name];
                          })
                        : translationsReference.child(getLanguageCode(myLocale.languageCode)).child(name).child('label').once().then((DataSnapshot snapshot) {
                            if (snapshot.value != null) {
                              _translationCache[name] = snapshot.value;
                              return snapshot.value;
                            } else {
                              return null;
                            }
                          });
                    Future<String> familyF = _translationCache.containsKey(family)
                        ? new Future<String>(() {
                            return _translationCache[family];
                          })
                        : translationsTaxonomyReference.child(getLanguageCode(myLocale.languageCode)).child(family).once().then((DataSnapshot snapshot) {
                            if (snapshot.value != null && snapshot.value.length > 0) {
                              _translationCache[family] = snapshot.value[0];
                              return snapshot.value[0];
                            } else {
                              return null;
                            }
                          });

                    return Card(
                      child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                        ListTile(
                          title: FutureBuilder<String>(
                              future: nameF,
                              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                                String labelLocal = name;
                                if (snapshot.connectionState == ConnectionState.done) {
                                  if (snapshot.data != null) {
                                    labelLocal = snapshot.data + ' / ' + name;
                                  }
                                }
                                return Text(labelLocal);
                              }),
                          subtitle: FutureBuilder<String>(
                              future: familyF,
                              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                                String familyLocal = family;
                                if (snapshot.connectionState == ConnectionState.done) {
                                  if (snapshot.data != null) {
                                    familyLocal = snapshot.data + ' / ' + family;
                                  }
                                }
                                return Text(familyLocal);
                              }),
                          leading: getImage(
                            storageFamilies + snapshot.value['family'] + defaultExtension,
                              Container(width: 0.0, height: 0.0,),
                            width: 50.0,
                            height: 50.0
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => PlantDetail(myLocale, widget.onChangeLanguage, widget.onBuyProduct, widget.filter, name)),
                            );
                          },
                        ),
                        _getImageButton(context, myLocale, storagePhotos + snapshot.value['url'], name),
                      ]),
                    );
                  }),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        height: 70.0,
        width: 70.0,
        child: FittedBox(
          fit: BoxFit.fill,
          child: FutureBuilder<int>(
              future: _count,
              builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.active:
                  case ConnectionState.waiting:
                    return const CircularProgressIndicator();
                  default:
                    return GestureDetector(
                      onLongPress: () {
                        Prefs.getBoolF(keyAlwaysMyRegion, false).then((value) {
                          Map<String, String> filter = {};
                          if (value) {
                            Prefs.getStringF(keyMyRegion, null).then((value) {
                              if (value != null) {
                                filter[filterDistribution] = value;
                              }
                              Navigator.pushReplacement(mainContext, getNextFilterRoute(mainContext, widget.onChangeLanguage, widget.onBuyProduct, filter));
                            });
                          } else {
                            Navigator.pushReplacement(mainContext, getNextFilterRoute(mainContext, widget.onChangeLanguage, widget.onBuyProduct, filter));
                          }
                        });
                      },
                      child: FloatingActionButton(
                        onPressed: () {},
                        child: Text(snapshot.data == null ? '' : snapshot.data.toString()),
                      ),
                    );
                }
              }),
        ),
      ),
    );
  }
}
