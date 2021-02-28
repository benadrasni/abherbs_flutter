import 'dart:async';
import 'dart:io';

import 'package:abherbs_flutter/drawer.dart';
import 'package:abherbs_flutter/filter/filter_utils.dart';
import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/plant_list.dart';
import 'package:abherbs_flutter/settings/offline.dart';
import 'package:abherbs_flutter/settings/preferences.dart';
import 'package:abherbs_flutter/signin/authentication.dart';
import 'package:abherbs_flutter/utils/dialogs.dart';
import 'package:abherbs_flutter/utils/prefs.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';

import '../ads.dart';
import '../main.dart';

class Color extends StatefulWidget {
  final Map<String, String> filter;
  Color(this.filter);

  @override
  _ColorState createState() => _ColorState();
}

class _ColorState extends State<Color> {
  GlobalKey<ScaffoldState> _key;
  StreamSubscription<firebase_auth.User> _listener;
  AppUser _currentUser;
  Future<int> _countF;
  Future<String> _rateStateF;
  Future<bool> _isNewVersionF;
  Map<String, String> _filter;

  _navigate(String value) {
    var newFilter = new Map<String, String>();
    newFilter.addAll(_filter);
    newFilter[filterColor] = value;

    var filter = getFilterKey(newFilter);
    countsReference.child(filter).keepSynced(true);
    countsReference.child(filter).once().then((DataSnapshot snapshot) {
      if (this.mounted) {
        if (snapshot.value != null && snapshot.value > 0) {
          Navigator.push(context, getNextFilterRoute(context, newFilter));
        } else {
          _key.currentState.showSnackBar(SnackBar(
            content: Text(S.of(context).snack_no_flowers),
          ));
        }
      }
    });
  }

  _setCount() {
    _countF = countsReference.child(getFilterKey(_filter)).once().then((DataSnapshot snapshot) {
      return snapshot.value;
    });
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
    Offline.setKeepSynced(1, true);

    _filter = new Map<String, String>();
    _filter.addAll(widget.filter);
    _filter.remove(filterColor);
    _key = new GlobalKey<ScaffoldState>();
    _rateStateF = Prefs.getStringF(keyRateState, rateStateInitial);
    _isNewVersionF = PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      return FirebaseDatabase.instance
          .reference()
          .child(firebaseVersions)
          .child(Platform.isAndroid ? firebaseAttributeAndroid : firebaseAttributeIOS)
          .once()
          .then((DataSnapshot snapshot) {
        return int.parse(packageInfo.buildNumber) < snapshot.value;
      });
    });

    _setCount();
  }

  @override
  void dispose() {
    _listener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    App.currentContext = context;
    var mainContext = context;
    var _widgets = <Widget>[];
    _widgets.add(Container(
      padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
      child: Row(
        children: [
          Expanded(
            child: FlatButton(
              child: Image(
                image: AssetImage('res/images/white.webp'),
              ),
              onPressed: () {
                _navigate('1');
              },
            ),
            flex: 1,
          ),
          Expanded(
            child: FlatButton(
              child: Image(
                image: AssetImage('res/images/yellow.webp'),
              ),
              onPressed: () {
                _navigate('2');
              },
            ),
            flex: 1,
          ),
        ],
      ),
    ));

    _widgets.add(FutureBuilder<String>(
        future: _rateStateF,
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.data == rateStateShould) {
              return Container(
                padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                decoration: new BoxDecoration(
                  borderRadius: new BorderRadius.circular(16.0),
                  color: Theme
                      .of(context)
                      .secondaryHeaderColor,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                      child: Text(
                        S
                            .of(context)
                            .rate_question,
                        style: TextStyle(fontSize: 18.0),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        RaisedButton(
                          child: Text(S
                              .of(context)
                              .yes),
                          onPressed: () {
                            rateDialog(context).then((_) {
                              if (mounted) {
                                setState(() {
                                  _rateStateF = Prefs.getStringF(keyRateState, rateStateInitial);
                                });
                              }
                            });
                          },
                        ),
                        RaisedButton(
                          child: Text(S
                              .of(context)
                              .no),
                          onPressed: () {
                            Prefs.setString(keyRateState, rateStateInitial).then((result) {
                              if (result) {
                                setState(() {
                                  _rateStateF = Prefs.getStringF(keyRateState, rateStateInitial);
                                });
                              }
                            });
                            Prefs.setString(keyRateCount, rateCountInitial.toString());
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            } else {
              return FutureBuilder<bool>(
                  future: _isNewVersionF,
                  builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                    if (snapshot.connectionState == ConnectionState.done && snapshot.data) {
                      return Container(
                        padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                        decoration: new BoxDecoration(
                          borderRadius: new BorderRadius.circular(16.0),
                          color: Theme.of(context).secondaryHeaderColor,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                              child: Text(
                                S.of(context).new_version,
                                style: TextStyle(fontSize: 18.0),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (Platform.isAndroid) {
                                      launchURL(playStore);
                                    } else {
                                      launchURL(appStore);
                                    }
                                  },
                                  child: Platform.isAndroid
                                      ? Image(image: AssetImage('res/images/google_play.png'))
                                      : Image(image: AssetImage('res/images/app_store.png')),
                                ),
                              ],
                            )
                          ],
                        ),
                      );
                    } else {
                      return Container();
                    }
                  });
            }
          } else {
            return Container();
          }
        }));

    _widgets.add(Container(
      padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: FlatButton(
              child: Image(
                image: AssetImage('res/images/red.webp'),
              ),
              onPressed: () {
                _navigate('3');
              },
            ),
            flex: 1,
          ),
          Expanded(
            child: FlatButton(
              child: Image(
                image: AssetImage('res/images/blue.webp'),
              ),
              onPressed: () {
                _navigate('4');
              },
            ),
            flex: 1,
          ),
        ],
      ),
    ));
    _widgets.add(Container(
      padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
      child: FlatButton(
        child: Image(
          image: AssetImage('res/images/green.webp'),
        ),
        onPressed: () {
          _navigate('5');
        },
      ),
    ));
    _widgets.add(Container(
      padding: EdgeInsets.only(top: 10.0, bottom: 10.0, left: 70.0, right: 70.0),
      child: Text(
        S.of(context).color_message,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontStyle: FontStyle.italic,
        ),
      ),
    ));

    _widgets.add(Container(height: 10.0 + getFABPadding()));

    return Scaffold(
      key: _key,
      appBar: AppBar(
        title: Text(S.of(context).filter_color),
        actions: getActions(context, _key, _currentUser, widget.filter),
      ),
      drawer: AppDrawer(_currentUser, _filter, null),
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Image.asset("res/images/app_background.webp",
              fit: BoxFit.fitWidth,
              alignment: Alignment.bottomCenter,
            ),
          ),
          ListView(
            padding: EdgeInsets.all(5.0),
            children: _widgets,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Ads.getAdMobBanner(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: Preferences.myFilterAttributes.indexOf(filterColor),
        items: getBottomNavigationBarItems(context, _filter),
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          onBottomNavigationBarTap(context, _filter, index, Preferences.myFilterAttributes.indexOf(filterColor));
        },
      ),
      floatingActionButton: Container(
        height: 70.0 + getFABPadding(),
        width: 70.0,
        padding: EdgeInsets.only(bottom: getFABPadding()),
        child: FittedBox(
          fit: BoxFit.fill,
          child: FutureBuilder<int>(
              future: _countF,
              builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.active:
                  case ConnectionState.waiting:
                    return const CircularProgressIndicator();
                  default:
                    return GestureDetector(
                      onLongPress: () {
                        setState(() {
                          clearFilter(_filter, _setCount);
                        });
                      },
                      child: FloatingActionButton(
                        onPressed: () {
                          Navigator.push(
                            mainContext,
                            MaterialPageRoute(
                                builder: (context) => PlantList(_filter, '', keysReference.child(getFilterKey(_filter))),
                                settings: RouteSettings(name: 'PlantList')),
                          );
                        },
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
