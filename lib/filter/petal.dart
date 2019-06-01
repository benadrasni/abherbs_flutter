import 'dart:async';

import 'package:abherbs_flutter/drawer.dart';
import 'package:abherbs_flutter/filter/filter_utils.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/settings/offline.dart';
import 'package:abherbs_flutter/plant_list.dart';
import 'package:abherbs_flutter/settings/preferences.dart';
import 'package:abherbs_flutter/signin/authetication.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class Petal extends StatefulWidget {
  final void Function(String) onChangeLanguage;
  final Map<String, String> filter;
  final MaterialPageRoute<dynamic> redirect;
  Petal(this.onChangeLanguage, this.filter, this.redirect);

  @override
  _PetalState createState() => _PetalState();
}

class _PetalState extends State<Petal> {
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
    newFilter[filterPetal] = value;

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
    _filter.remove(filterPetal);
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
    var mainContext = context;
    var _defaultTextStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 22.0,
    );
    return Scaffold(
      key: _key,
      appBar: AppBar(
        title: Text(S.of(context).filter_petal),
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
              Container(
                padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: FlatButton(
                        padding: EdgeInsets.all(10.0),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                          Text(
                            S.of(context).petal_4,
                            style: _defaultTextStyle,
                          ),
                          Image(
                            image: AssetImage('res/images/nop_4.webp'),
                          ),
                        ]),
                        onPressed: () {
                          _navigate('1');
                        },
                      ),
                      flex: 1,
                    ),
                    Expanded(
                      child: FlatButton(
                        padding: EdgeInsets.all(10.0),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                          Text(
                            S.of(context).petal_5,
                            style: _defaultTextStyle,
                          ),
                          Image(
                            image: AssetImage('res/images/nop_5.webp'),
                          ),
                        ]),
                        onPressed: () {
                          _navigate('2');
                        },
                      ),
                      flex: 1,
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: FlatButton(
                        padding: EdgeInsets.all(10.0),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                          Text(
                            S.of(context).petal_many,
                            style: _defaultTextStyle,
                          ),
                          Image(
                            image: AssetImage('res/images/nop_many.webp'),
                          ),
                        ]),
                        onPressed: () {
                          _navigate('3');
                        },
                      ),
                      flex: 1,
                    ),
                    Expanded(
                      child: FlatButton(
                        padding: EdgeInsets.all(10.0),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                          Text(
                            S.of(context).petal_zygomorphic,
                            style: _defaultTextStyle,
                          ),
                          Image(
                            image: AssetImage('res/images/nop_zygomorphic.webp'),
                          ),
                        ]),
                        onPressed: () {
                          _navigate('4');
                        },
                      ),
                      flex: 1,
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.only(top: 10.0, bottom: 10.0, left: 70.0, right: 70.0),
                child: Text(
                  S.of(context).petal_message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              getAdMobBanner(),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: Preferences.myFilterAttributes.indexOf(filterPetal),
        items: getBottomNavigationBarItems(context, _filter),
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          onBottomNavigationBarTap(context, widget.onChangeLanguage, _filter, index, Preferences.myFilterAttributes.indexOf(filterPetal));
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
                                builder: (context) => PlantList(widget.onChangeLanguage, _filter, '')),
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
