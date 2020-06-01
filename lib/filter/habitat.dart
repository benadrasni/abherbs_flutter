import 'dart:async';

import 'package:abherbs_flutter/drawer.dart';
import 'package:abherbs_flutter/filter/filter_utils.dart';
import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/settings/offline.dart';
import 'package:abherbs_flutter/plant_list.dart';
import 'package:abherbs_flutter/settings/preferences.dart';
import 'package:abherbs_flutter/signin/authetication.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../ads.dart';
import '../main.dart';

class Habitat extends StatefulWidget {
  final void Function(String) onChangeLanguage;
  final Map<String, String> filter;
  final MaterialPageRoute<dynamic> redirect;
  Habitat(this.onChangeLanguage, this.filter, this.redirect);

  @override
  _HabitatState createState() => _HabitatState();
}

class _HabitatState extends State<Habitat> {
  StreamSubscription<FirebaseUser> _listener;
  FirebaseUser _currentUser;
  Future<int> _countF;
  Map<String, String> _filter;
  GlobalKey<ScaffoldState> _key;

  _redirect(BuildContext context) async {
    // redirect to route from notification
    if (widget.redirect != null) {
      Navigator.push(context, widget.redirect);
    }
  }

  _navigate(String value) {
    var newFilter = new Map<String, String>();
    newFilter.addAll(_filter);
    newFilter[filterHabitat] = value;

    var filter = getFilterKey(newFilter);
    countsReference.child(filter).keepSynced(true);
    countsReference.child(filter).once().then((DataSnapshot snapshot) {
      if (this.mounted) {
        if (snapshot.value != null && snapshot.value > 0) {
          Navigator.push(context, getNextFilterRoute(context, widget.onChangeLanguage, newFilter));
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
    Offline.setKeepSynced(1, true);
    _checkCurrentUser();

    _filter = new Map<String, String>();
    _filter.addAll(widget.filter);
    _filter.remove(filterHabitat);
    _key = new GlobalKey<ScaffoldState>();

    _setCount();

    SchedulerBinding.instance.addPostFrameCallback((_) => _redirect(context));
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
    var _defaultTextStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 22.0,
      color: Colors.white,
    );
    return Scaffold(
      key: _key,
      appBar: new AppBar(
        title: new Text(S.of(context).filter_habitat),
        actions: getActions(context, _key, _currentUser, widget.onChangeLanguage, widget.filter),
      ),
      drawer: AppDrawer(_currentUser, widget.onChangeLanguage, _filter, null),
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Image.asset(
              "res/images/app_background.webp",
              fit: BoxFit.fitWidth,
              alignment: Alignment.bottomCenter,
            ),
          ),
          ListView(
            padding: EdgeInsets.all(5.0),
            children: [
              FlatButton(
                padding: EdgeInsets.only(bottom: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/meadow.webp'),
                  ),
                  Text(
                    S.of(context).habitat_meadow,
                    style: _defaultTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('1');
                },
              ),
              FlatButton(
                padding: EdgeInsets.only(bottom: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/garden.webp'),
                  ),
                  Text(
                    S.of(context).habitat_garden,
                    style: _defaultTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('2');
                },
              ),
              FlatButton(
                padding: EdgeInsets.only(bottom: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/swamp.webp'),
                  ),
                  Text(
                    S.of(context).habitat_wetland,
                    style: _defaultTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('3');
                },
              ),
              FlatButton(
                padding: EdgeInsets.only(bottom: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/forest.webp'),
                  ),
                  Text(
                    S.of(context).habitat_forest,
                    style: _defaultTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('4');
                },
              ),
              FlatButton(
                padding: EdgeInsets.only(bottom: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/mountain.webp'),
                  ),
                  Text(
                    S.of(context).habitat_rock,
                    style: _defaultTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('5');
                },
              ),
              FlatButton(
                padding: EdgeInsets.only(bottom: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/tree.webp'),
                  ),
                  Text(
                    S.of(context).habitat_tree,
                    style: _defaultTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('6');
                },
              ),
              Container(
                padding: EdgeInsets.only(top: 10.0, bottom: 10.0, left: 70.0, right: 70.0),
                child: Text(
                  S.of(context).habitat_message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              Container(height: 10.0 + getFABPadding()),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Ads.getAdMobBanner(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: Preferences.myFilterAttributes.indexOf(filterHabitat),
        items: getBottomNavigationBarItems(context, _filter),
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          onBottomNavigationBarTap(context, widget.onChangeLanguage, _filter, index, Preferences.myFilterAttributes.indexOf(filterHabitat));
        },
      ),
      floatingActionButton: new Container(
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
                                builder: (context) => PlantList(widget.onChangeLanguage, _filter, '', keysReference.child(getFilterKey(widget.filter))),
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
