import 'dart:async';

import 'package:abherbs_flutter/ads.dart';
import 'package:abherbs_flutter/drawer.dart';
import 'package:abherbs_flutter/filter/color.dart';
import 'package:abherbs_flutter/filter/distribution_2.dart';
import 'package:abherbs_flutter/filter/filter_utils.dart';
import 'package:abherbs_flutter/filter/habitat.dart';
import 'package:abherbs_flutter/filter/petal.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/plant_list.dart';
import 'package:abherbs_flutter/prefs.dart';
import 'package:abherbs_flutter/settings/settings.dart';
import 'package:abherbs_flutter/utils.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

final countsReference = FirebaseDatabase.instance.reference().child(firebaseCounts);

class Distribution extends StatefulWidget {
  final void Function(String) onChangeLanguage;
  final void Function() onBuyProduct;
  final Map<String, String> filter;
  Distribution(this.onChangeLanguage, this.onBuyProduct, this.filter);

  @override
  _DistributionState createState() => _DistributionState();
}

class _DistributionState extends State<Distribution> {
  Future<int> _count;
  Map<String, String> _filter;
  Future<String> _myRegionF;
  String _myRegion;
  GlobalKey<ScaffoldState> _key;

  void _openRegion(String region) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => Distribution2(widget.onChangeLanguage, widget.onBuyProduct, widget.filter, int.parse(region))));
  }

  void _navigate(String value) {
    var newFilter = new Map<String, String>();
    newFilter.addAll(_filter);
    newFilter[filterDistribution] = value;

    countsReference.child(getFilterKey(newFilter)).once().then((DataSnapshot snapshot) {
      if (snapshot.value != null && snapshot.value > 0) {
        Navigator.push(context, getNextFilterRoute(context, widget.onChangeLanguage, widget.onBuyProduct, newFilter)).then((value) {
          Ads.showBannerAd(this);
        });
      } else {
        _key.currentState.showSnackBar(SnackBar(
          content: Text(S.of(context).snack_no_flowers),
        ));
      }
    });
  }

  _setCount() {
    _count = countsReference.child(getFilterKey(_filter)).once().then((DataSnapshot snapshot) {
      return snapshot.value;
    });
  }

  void setMyRegion() {
    _myRegion = "";
    _myRegionF = Prefs.getStringF(keyMyRegion);
    _myRegionF.then((region) {
      setState(() {
        _myRegion = region;
      });
    });
  }

  Widget _getBody(BuildContext context) {
    var _firstLevelTextStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 22.0,
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
    regionWidgets.add(GridTile(
      child: FlatButton(
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
              MaterialPageRoute(builder: (context) => SettingsScreen(widget.onChangeLanguage)),
            ).then((result) {
              setMyRegion();
            });
          }
        },
      ),
    ));
    regionWidgets.addAll(regions.map((List<String> items) {
      return GridTile(
        child: FlatButton(
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
        ),
      );
    }).toList());

    regionWidgets.add(GridTile(
      child: FlatButton(
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
    ));

    regionWidgets.add(Container(
        padding: EdgeInsets.only(top: 10.0, bottom: 10.0, left: 70.0, right: 70.0),
        child: Stack(alignment: Alignment.center,
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

    regionWidgets.add(getAdMobBanner());

    return Container(
        color: Colors.white30,
        child: GridView.count(
          crossAxisCount: 1,
          childAspectRatio: 4.0,
          children: regionWidgets,
        ));
  }

  @override
  void initState() {
    super.initState();
    _filter = new Map<String, String>();
    _filter.addAll(widget.filter);
    _filter.remove(filterDistribution);
    _key = new GlobalKey<ScaffoldState>();

    _setCount();

    Ads.showBannerAd(this);
    setMyRegion();
  }

  @override
  Widget build(BuildContext context) {
    var mainContext = context;
    return Scaffold(
      key: _key,
      appBar: new AppBar(
        title: new Text(S.of(context).filter_distribution),
        actions: getActions(context, widget.onChangeLanguage, widget.onBuyProduct),
      ),
      drawer: AppDrawer(widget.onChangeLanguage, widget.onBuyProduct, _filter, this.setMyRegion),
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Image.asset(
              "res/images/app_background.webp",
              fit: BoxFit.fitWidth,
              alignment: Alignment.bottomCenter,
            ),
          ),
          _getBody(context),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        items: getBottomNavigationBarItems(context, _filter),
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index != 3) {
            var route;
            var nextFilterAttribute;
            switch (index) {
              case 0:
                route = MaterialPageRoute(builder: (context) => Color(widget.onChangeLanguage, widget.onBuyProduct, _filter));
                nextFilterAttribute = filterColor;
                break;
              case 1:
                route = MaterialPageRoute(builder: (context) => Habitat(widget.onChangeLanguage, widget.onBuyProduct, _filter));
                nextFilterAttribute = filterHabitat;
                break;
              case 2:
                route = MaterialPageRoute(builder: (context) => Petal(widget.onChangeLanguage, widget.onBuyProduct, _filter));
                nextFilterAttribute = filterPetal;
                break;
            }
            if (filterRoutes[nextFilterAttribute] != null && filterRoutes[nextFilterAttribute].isActive) {
              Navigator.removeRoute(context, filterRoutes[nextFilterAttribute]);
            }
            filterRoutes[nextFilterAttribute] = route;
            Navigator.push(context, route);
          }
        },
      ),
      floatingActionButton: new Container(
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
                        setState(() {
                          clearFilter(_filter, _setCount);
                        });
                      },
                      child: FloatingActionButton(
                        onPressed: () {
                          Navigator.push(
                            mainContext,
                            MaterialPageRoute(builder: (context) => PlantList(widget.onChangeLanguage, widget.onBuyProduct, _filter)),
                          ).then((value) {
                            Ads.showBannerAd(this);
                          });
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
