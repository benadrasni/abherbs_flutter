import 'dart:async';

import 'package:abherbs_flutter/drawer.dart';
import 'package:abherbs_flutter/filter/distribution_2.dart';
import 'package:abherbs_flutter/filter/filter_utils.dart';
import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/settings/offline.dart';
import 'package:abherbs_flutter/plant_list.dart';
import 'package:abherbs_flutter/settings/preferences.dart';
import 'package:abherbs_flutter/utils/prefs.dart';
import 'package:abherbs_flutter/settings/settings.dart';
import 'package:abherbs_flutter/signin/authentication.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../keys.dart';
import '../main.dart';

class Distribution extends StatefulWidget {
  final Map<String, String> filter;
  Distribution(this.filter);

  @override
  _DistributionState createState() => _DistributionState();
}

class _DistributionState extends State<Distribution> {
  StreamSubscription<firebase_auth.User> _listener;
  Future<int> _countF;
  Map<String, String> _filter;
  Future<String> _myRegionF;
  String _myRegion;
  GlobalKey<ScaffoldState> _key;
  BannerAd _ad;

  void _openRegion(String region) {
    var route = MaterialPageRoute(builder: (context) => Distribution2(widget.filter, int.parse(region)), settings: RouteSettings(name: 'Distribution2'));
    filterRoutes[filterDistribution2] = route;
    Navigator.push(context, route).then((value) {
      filterRoutes[filterDistribution2] = null;
    });
  }

  void _navigate(String value) {
    var newFilter = new Map<String, String>();
    newFilter.addAll(_filter);
    newFilter[filterDistribution] = value;

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
      return event.snapshot.value;
    });
  }

  _setMyRegion() {
    if (mounted) {
      _myRegion = "";
      _myRegionF = Prefs.getStringF(keyMyRegion);
      _myRegionF.then((region) {
        setState(() {
          _myRegion = region;
        });
      });
    }
  }

  Widget _getBody(BuildContext context) {
    var _firstLevelTextStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 22.0,
      color: Colors.black,
    );

    var regions = <List<String>>[];
    regions.add([S.of(context).europe, 'res/images/wgsrpd_europe.webp', '1']);
    regions.add([S.of(context).africa, 'res/images/wgsrpd_africa.webp', '2']);
    regions.add([S.of(context).asia_temperate, 'res/images/wgsrpd_asia_temperate.webp', '3']);
    regions.add([S.of(context).asia_tropical, 'res/images/wgsrpd_asia_tropical.webp', '4']);
    regions.add([S.of(context).australasia, 'res/images/wgsrpd_australasia.webp', '5']);
    regions.add([S.of(context).pacific, 'res/images/wgsrpd_pacific.webp', '6']);
    regions.add([S.of(context).northern_america, 'res/images/wgsrpd_northern_america.webp', '7']);
    regions.add([S.of(context).southern_america, 'res/images/wgsrpd_southern_america.webp', '8']);

    var regionWidgets = <Widget>[];
    regionWidgets.add(
      TextButton(
        style: ButtonStyle(
          padding: MaterialStateProperty.all(EdgeInsets.only(bottom: 5.0)),
        ),
        child: Stack(alignment: Alignment.center, children: [
          Image(
            image: AssetImage('res/images/wgsrpd_my_region.webp'),
          ),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(
              S.of(context).my_region,
              style: _firstLevelTextStyle,
            ),
            FutureBuilder<String>(
                future: _myRegionF,
                builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                  var value = "";
                  if (snapshot.connectionState == ConnectionState.done) {
                    value = snapshot.data.isNotEmpty ? getFilterDistributionValue(context, snapshot.data) : "";
                  }
                  return Text(
                    value,
                    style: TextStyle(
                      fontSize: 20.0,
                      fontStyle: FontStyle.italic,
                    ),
                  );
                }),
          ])
        ]),
        onPressed: () {
          if (_myRegion.isNotEmpty) {
            _navigate(_myRegion);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsScreen(widget.filter), settings: RouteSettings(name: 'Settings')),
            ).then((result) {
              _setMyRegion();
            });
          }
        },
      ),
    );
    regionWidgets.addAll(regions.map((List<String> items) {
      return TextButton(
        style: ButtonStyle(
          padding: MaterialStateProperty.all(EdgeInsets.only(bottom: 5.0)),
        ),
        child: Stack(alignment: Alignment.center, children: [
          Image(
            image: AssetImage(items[1]),
          ),
          Text(
            items[0],
            style: _firstLevelTextStyle,
          ),
        ]),
        onPressed: () {
          _openRegion(items[2]);
        },
      );
    }).toList());

    regionWidgets.add(
      TextButton(
        style: ButtonStyle(
          padding: MaterialStateProperty.all(EdgeInsets.only(bottom: 5.0)),
        ),
        child: Stack(alignment: Alignment.center, children: [
          Image(
            image: AssetImage('res/images/wgsrpd_antarctic.webp'),
          ),
          Text(
            S.of(context).subantarctic_islands,
            style: _firstLevelTextStyle,
          ),
        ]),
        onPressed: () {
          _navigate('90');
        },
      ),
    );

    regionWidgets.add(Container(
        padding: EdgeInsets.only(top: 10.0, bottom: 10.0, left: 70.0, right: 70.0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              S.of(context).distribution_message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        )));

    regionWidgets.add(Container(height: 10.0 + getFABPadding()));

    return ListView(
      padding: EdgeInsets.all(5.0),
      children: regionWidgets,
    );
  }

  @override
  void initState() {
    super.initState();

    _listener = Auth.subscribe((firebase_auth.User user) => setState(() {}));
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
      _ad.load();
    }

    _filter = new Map<String, String>();
    _filter.addAll(widget.filter);
    _filter.remove(filterDistribution);
    _key = new GlobalKey<ScaffoldState>();

    _setCount();

    _setMyRegion();
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
    return Scaffold(
      key: _key,
      appBar: new AppBar(
        title: new Text(S.of(context).filter_distribution),
        actions: getActions(context, _key, widget.filter),
      ),
      drawer: AppDrawer(_filter, this._setMyRegion),
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
                child: _getBody(context),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: !Purchases.isNoAds()
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
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: Preferences.myFilterAttributes.indexOf(filterDistribution),
        items: getBottomNavigationBarItems(context, _filter),
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          onBottomNavigationBarTap(context, _filter, index, Preferences.myFilterAttributes.indexOf(filterDistribution));
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
