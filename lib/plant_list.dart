import 'dart:async';

import 'package:abherbs_flutter/drawer.dart';
import 'package:abherbs_flutter/filter/filter_utils.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/widgets/firebase_animated_index_list.dart';
import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/settings/offline.dart';
import 'package:abherbs_flutter/utils/prefs.dart';
import 'package:abherbs_flutter/signin/authentication.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'keys.dart';
import 'main.dart';

class PlantList extends StatefulWidget {
  final Map<String, String> filter;
  final String emptyMessage;
  final DatabaseReference pathToIndex;
  PlantList(this.filter, this.emptyMessage, this.pathToIndex);

  @override
  _PlantListState createState() => _PlantListState();
}

class _PlantListState extends State<PlantList> {
  StreamSubscription<firebase_auth.User> _listener;
  AppUser _currentUser;
  Future<int> _count;
  BannerAd _ad;
  bool _showAd;

  Widget _getImageButton(BuildContext context, Locale myLocale, String url, String name) {
    double screenWidth = MediaQuery.of(context).size.width - 20;
    var placeholder = Stack(alignment: Alignment.center, children: [
      CircularProgressIndicator(),
      Image(
        image: AssetImage('res/images/placeholder.webp'),
      ),
    ]);
    Widget button = TextButton(
      style: ButtonStyle(
        padding: MaterialStateProperty.all(EdgeInsets.all(5.0)),
      ),
      child: Container(
        child: getImage(url, placeholder),
        width: screenWidth,
        height: screenWidth,
      ),
      onPressed: () {
        goToDetail(this, context, myLocale, name, widget.filter);
      },
    );

    return button;
  }

  _onAuthStateChanged(firebase_auth.User user) {
    setState(() {
      _currentUser = Auth.getAppUser();
    });
  }

  void _checkCurrentUser() {
    _currentUser = Auth.getAppUser();
    _listener = Auth.subscribe(_onAuthStateChanged);
  }

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
    Offline.setKeepSynced(2, true);

    _showAd = !Purchases.isNoAds();

    if (_showAd) {
      _ad = BannerAd(
        adUnitId: getBannerAdUnitId(),
        size: AdSize.banner,
        request: AdRequest(),
        listener: BannerAdListener(
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            setState(() {
              _showAd = false;
            });
            ad.dispose();
          },
          onAdClosed: (Ad ad) {
            setState(() {
              _showAd = false;
            });
            ad.dispose();
          },
        ),
      );
      _ad.load();
    }

    widget.pathToIndex.keepSynced(true);
    _count = widget.pathToIndex.once().then((DataSnapshot snapshot) {
      var result = snapshot.value ?? [];
      int length = result is List ? result.fold(0, (t, value) => t + (value == null ? 0 : 1)) : result.values.length;
      return length;
    });
  }

  @override
  void dispose() {
    _listener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    App.currentContext = context;
    var self = this;
    var mainContext = context;

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(mainContext).list_info),
      ),
      drawer: AppDrawer(_currentUser, widget.filter, null),
      body: Column(
        children: [
          Expanded(
            child: FirebaseAnimatedIndexList(
                defaultChild: Center(child: CircularProgressIndicator()),
                emptyChild: Container(
                  padding: EdgeInsets.all(5.0),
                  alignment: Alignment.center,
                  child: Text(widget.emptyMessage, style: TextStyle(fontSize: 20.0)),
                ),
                query: listsReference.orderByChild(firebaseAttributeName),
                keyQuery: widget.pathToIndex,
                itemBuilder: (_, DataSnapshot snapshot, Animation<double> animation, int index) {
                  String name = snapshot.value[firebaseAttributeName];
                  String family = snapshot.value[firebaseAttributeFamily];
                  String url = snapshot.value[firebaseAttributeUrl];

                  Locale myLocale = Localizations.localeOf(mainContext);
                  Future<String> nameF = translationCache.containsKey(name)
                      ? Future<String>(() {
                          return translationCache[name];
                        })
                      : translationsReference.child(getLanguageCode(myLocale.languageCode)).child(name).child(firebaseAttributeLabel).once().then((DataSnapshot snapshot) {
                          if (snapshot.value != null) {
                            translationCache[name] = snapshot.value;
                            return snapshot.value;
                          } else {
                            return null;
                          }
                        });
                  Future<String> familyF = translationCache.containsKey(family)
                      ? Future<String>(() {
                          return translationCache[family];
                        })
                      : translationsTaxonomyReference.child(getLanguageCode(myLocale.languageCode)).child(family).once().then((DataSnapshot snapshot) {
                          if (snapshot.value != null && snapshot.value.length > 0) {
                            translationCache[family] = snapshot.value[0];
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
                            storageFamilies + family + defaultExtension,
                            Container(
                              width: 0.0,
                              height: 0.0,
                            ),
                            width: 50.0,
                            height: 50.0),
                        onTap: () {
                          goToDetail(self, mainContext, myLocale, name, widget.filter);
                        },
                      ),
                      _getImageButton(mainContext, myLocale, storagePhotos + url, name),
                    ]),
                  );
                }),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _showAd
                ? Container(
                    alignment: Alignment.center,
                    margin: EdgeInsets.only(bottom: 5.0, top: 5.0),
                    child: AdWidget(ad: _ad),
                    width: _ad.size.width.toDouble(),
                    height: _ad.size.height.toDouble(),
                  )
                : Container(
                    height: 0.0,
                  ),
          ),
        ],
      ),
      floatingActionButton: Container(
        height: 70.0 + getFABPadding(),
        width: 70.0,
        padding: EdgeInsets.only(bottom: getFABPadding()),
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
                              Navigator.pushReplacement(mainContext, getNextFilterRoute(mainContext, filter));
                            });
                          } else {
                            Navigator.pushReplacement(mainContext, getNextFilterRoute(mainContext, filter));
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
