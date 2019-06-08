import 'dart:async';
import 'dart:math';

import 'package:abherbs_flutter/drawer.dart';
import 'package:abherbs_flutter/filter/filter_utils.dart';
import 'package:abherbs_flutter/widgets/firebase_animated_index_list.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/settings/offline.dart';
import 'package:abherbs_flutter/utils/prefs.dart';
import 'package:abherbs_flutter/signin/authetication.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'ads.dart';

class PlantList extends StatefulWidget {
  final void Function(String) onChangeLanguage;
  final Map<String, String> filter;
  final String emptyMessage;
  final String count;
  final String path;
  PlantList(this.onChangeLanguage, this.filter, this.emptyMessage, [this.count, this.path]);

  @override
  _PlantListState createState() => _PlantListState();
}

class _PlantListState extends State<PlantList> {
  StreamSubscription<FirebaseUser> _listener;
  FirebaseUser _currentUser;
  Future<int> _count;
  Random _random;

  Widget _getImageButton(BuildContext context, Locale myLocale, String url, String name) {
    var placeholder = Stack(alignment: Alignment.center, children: [
      CircularProgressIndicator(),
      Image(
        image: AssetImage('res/images/placeholder.webp'),
      ),
    ]);
    Widget button = FlatButton(
      padding: EdgeInsets.all(10.0),
      child: getImage(url, placeholder),
      onPressed: () {
        goToDetail(this, context, myLocale, name, widget.onChangeLanguage, widget.filter);
      },
    );

    if (_random.nextInt(100) < Ads.adsFrequency) {
      return Column(
        children: [
          button,
          Ads.getAdMobBigBanner(),
        ],
      );
    } else {
      return button;
    }
  }

  _onAuthStateChanged(FirebaseUser user) {
    setState(() {
      _currentUser = user;
    });
  }

  void _checkCurrentUser() async {
    _currentUser = await Auth.getCurrentUser();
    _listener = Auth.subscribe(_onAuthStateChanged);
  }

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
    Offline.setKeepSynced(2, true);
    _random = Random();

    if (widget.count != null) {
      _count = Future<int>(() {
        return int.parse(widget.count);
      });
    } else {
      var filter = getFilterKey(widget.filter);
      _count = countsReference.child(filter).once().then((DataSnapshot snapshot) {
        return snapshot.value;
      });
      keysReference.child(filter).keepSynced(true);
    }
  }

  @override
  void dispose() {
    _listener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var self = this;
    var mainContext = context;

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).list_info),
      ),
      drawer: AppDrawer(_currentUser, widget.onChangeLanguage, widget.filter, null),
      body: FirebaseAnimatedIndexList(
          defaultChild: Center(child: CircularProgressIndicator()),
          emptyChild: Container(
            padding: EdgeInsets.all(5.0),
            alignment: Alignment.center,
            child: Text(widget.emptyMessage, style: TextStyle(fontSize: 20.0)),
          ),
          query: listsReference.orderByChild(firebaseAttributeName),
          keyQuery: widget.path != null ? rootReference.child(widget.path) : keysReference.child(getFilterKey(widget.filter)),
          itemBuilder: (_, DataSnapshot snapshot, Animation<double> animation, int index) {
            String name = snapshot.value[firebaseAttributeName];
            String family = snapshot.value[firebaseAttributeFamily];
            String url = snapshot.value[firebaseAttributeUrl];

            Locale myLocale = Localizations.localeOf(context);
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
                    goToDetail(self, context, myLocale, name, widget.onChangeLanguage, widget.filter);
                  },
                ),
                _getImageButton(context, myLocale, storagePhotos + url, name),
              ]),
            );
          }),
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
                              Navigator.pushReplacement(
                                  mainContext, getNextFilterRoute(mainContext, widget.onChangeLanguage, filter));
                            });
                          } else {
                            Navigator.pushReplacement(
                                mainContext, getNextFilterRoute(mainContext, widget.onChangeLanguage, filter));
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
