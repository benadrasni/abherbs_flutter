import 'dart:async';

import 'package:abherbs_flutter/drawer.dart';
import 'package:abherbs_flutter/filter/filter_utils.dart';
import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/settings/offline.dart';
import 'package:abherbs_flutter/plant_list.dart';
import 'package:abherbs_flutter/settings/preferences.dart';
import 'package:abherbs_flutter/signin/authentication.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../keys.dart';
import '../main.dart';

class Petal extends StatefulWidget {
  final Map<String, String> filter;
  Petal(this.filter);

  @override
  _PetalState createState() => _PetalState();
}

class _PetalState extends State<Petal> {
  StreamSubscription<firebase_auth.User> _listener;
  AppUser _currentUser;
  Future<int> _countF;
  Map<String, String> _filter;
  GlobalKey<ScaffoldState> _key;
  BannerAd _ad;
  bool _showAd;

  _navigate(String value) {
    var newFilter = new Map<String, String>();
    newFilter.addAll(_filter);
    newFilter[filterPetal] = value;

    var filter = getFilterKey(newFilter);
    countsReference.child(filter).keepSynced(true);
    countsReference.child(filter).once().then((DataSnapshot snapshot) {
      if (this.mounted) {
        if (snapshot.value != null && snapshot.value > 0) {
          Navigator.push(context, getNextFilterRoute(context, newFilter));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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
    App.currentContext = context;
    super.initState();
    Offline.setKeepSynced(1, true);
    _checkCurrentUser();

    _showAd = !Purchases.isNoAds();

    if (_showAd) {
      _ad = BannerAd(
        adUnitId: getBannerAdUnitId(),
        size: AdSize.banner,
        request: AdRequest(),
        listener: AdListener(
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

    _filter = new Map<String, String>();
    _filter.addAll(widget.filter);
    _filter.remove(filterPetal);
    _key = new GlobalKey<ScaffoldState>();

    _setCount();
  }

  @override
  void dispose() {
    _listener.cancel();
    _ad.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var mainContext = context;
    var _defaultTextStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 22.0,
      color: Colors.black,
    );
    return Scaffold(
      key: _key,
      appBar: AppBar(
        title: Text(S.of(context).filter_petal),
        actions: getActions(context, _key, _currentUser, widget.filter),
      ),
      drawer: AppDrawer(_currentUser, _filter, null),
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
                      child: TextButton(
                        style: ButtonStyle(
                          padding: MaterialStateProperty.all(EdgeInsets.all(10.0)),
                        ),
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
                      child: TextButton(
                        style: ButtonStyle(
                          padding: MaterialStateProperty.all(EdgeInsets.all(10.0)),
                        ),
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
                      child: TextButton(
                        style: ButtonStyle(
                          padding: MaterialStateProperty.all(EdgeInsets.all(10.0)),
                        ),
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
                      child: TextButton(
                        style: ButtonStyle(
                          padding: MaterialStateProperty.all(EdgeInsets.all(10.0)),
                        ),
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
              Container(height: 10.0 + getFABPadding()),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _showAd
                ? Container(
                    alignment: Alignment.center,
                    margin: EdgeInsets.only(bottom: 5.0),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: Preferences.myFilterAttributes.indexOf(filterPetal),
        items: getBottomNavigationBarItems(context, _filter),
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          onBottomNavigationBarTap(context, _filter, index, Preferences.myFilterAttributes.indexOf(filterPetal));
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
                            MaterialPageRoute(builder: (context) => PlantList(_filter, '', keysReference.child(getFilterKey(_filter))), settings: RouteSettings(name: 'PlantList')),
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
