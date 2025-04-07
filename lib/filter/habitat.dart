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
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../keys.dart';
import '../main.dart';

class Habitat extends StatefulWidget {
  final Map<String, String> filter;
  Habitat(this.filter);

  @override
  _HabitatState createState() => _HabitatState();
}

class _HabitatState extends State<Habitat> {
  GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();
  Map<String, String> _filter = Map<String, String>();
  late StreamSubscription<firebase_auth.User?> _listener;
  Future<int>? _countF;
  BannerAd? _ad;

  _navigate(String value) {
    var newFilter = new Map<String, String>();
    newFilter.addAll(_filter);
    newFilter[filterHabitat] = value;

    var filter = getFilterKey(newFilter);
    countsReference.child(filter).keepSynced(true);
    countsReference.child(filter).once().then((event) {
      if (this.mounted) {
        if (event.snapshot.value != null && (event.snapshot.value as int) > 0) {
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
    _countF = countsReference.child(getFilterKey(_filter)).once().then((event) {
      return event.snapshot.value as int;
    });
  }

  @override
  void initState() {
    super.initState();

    _listener = Auth.subscribe((firebase_auth.User? user) => setState(() {}));
    Offline.setKeepSynced(1, true);

    if (!Purchases.isNoAds()) {
      _ad = BannerAd(
        adUnitId: getBannerAdUnitId(),
        size: AdSize.banner,
        request: AdRequest(),
        listener: BannerAdListener(
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            ad.dispose();
          },
          onAdClosed: (Ad ad) {
            ad.dispose();
          },
        ),
      );
      _ad?.load();
    }

    _filter.addAll(widget.filter);
    _filter.remove(filterHabitat);

    _setCount();
  }

  @override
  void dispose() {
    _listener.cancel();
    _ad?.dispose();
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
        actions: getActions(context, _key, widget.filter),
      ),
      drawer: AppDrawer(_filter, () => {}),
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Image.asset(
              "res/images/app_background.webp",
              fit: BoxFit.fitWidth,
              alignment: Alignment.bottomCenter,
            ),
          ),
          Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.all(5.0),
                  children: [
                    TextButton(
                      style: ButtonStyle(
                        padding: WidgetStateProperty.all(EdgeInsets.only(bottom: 5.0)),
                      ),
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
                    TextButton(
                      style: ButtonStyle(
                        padding: WidgetStateProperty.all(EdgeInsets.only(bottom: 5.0)),
                      ),
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
                    TextButton(
                      style: ButtonStyle(
                        padding: WidgetStateProperty.all(EdgeInsets.only(bottom: 5.0)),
                      ),
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
                    TextButton(
                      style: ButtonStyle(
                        padding: WidgetStateProperty.all(EdgeInsets.only(bottom: 5.0)),
                      ),
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
                    TextButton(
                      style: ButtonStyle(
                        padding: WidgetStateProperty.all(EdgeInsets.only(bottom: 5.0)),
                      ),
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
                    TextButton(
                      style: ButtonStyle(
                        padding: WidgetStateProperty.all(EdgeInsets.only(bottom: 5.0)),
                      ),
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
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: !Purchases.isNoAds() && _ad != null
                    ? Container(
                        alignment: Alignment.center,
                        margin: EdgeInsets.only(bottom: 5.0, top: 5.0),
                        child: AdWidget(ad: _ad!),
                        width: _ad!.size.width.toDouble(),
                        height: _ad!.size.height.toDouble(),
                      )
                    : Container(
                        height: 0.0,
                      ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: Preferences.myFilterAttributes.indexOf(filterHabitat),
        items: getBottomNavigationBarItems(context, _filter),
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          onBottomNavigationBarTap(context, _filter, index, Preferences.myFilterAttributes.indexOf(filterHabitat));
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
