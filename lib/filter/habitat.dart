import 'dart:async';

import 'package:abherbs_flutter/ads.dart';
import 'package:abherbs_flutter/drawer.dart';
import 'package:abherbs_flutter/filter/filter_utils.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/offline.dart';
import 'package:abherbs_flutter/plant_list.dart';
import 'package:abherbs_flutter/preferences.dart';
import 'package:abherbs_flutter/utils.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

final countsReference = FirebaseDatabase.instance.reference().child(firebaseCounts);

class Habitat extends StatefulWidget {
  final void Function(String) onChangeLanguage;
  final void Function(PurchasedItem) onBuyProduct;
  final Map<String, String> filter;
  Habitat(this.onChangeLanguage, this.onBuyProduct, this.filter);

  @override
  _HabitatState createState() => _HabitatState();
}

class _HabitatState extends State<Habitat> {
  Future<int> _countF;
  Map<String, String> _filter;
  GlobalKey<ScaffoldState> _key;

  _navigate(String value) {
    var newFilter = new Map<String, String>();
    newFilter.addAll(_filter);
    newFilter[filterHabitat] = value;

    countsReference.child(getFilterKey(newFilter)).once().then((DataSnapshot snapshot) {
      if (this.mounted) {
        if (snapshot.value != null && snapshot.value > 0) {
          Navigator.push(context, getNextFilterRoute(context, widget.onChangeLanguage, widget.onBuyProduct, newFilter)).then((value) {
            Ads.showBannerAd(this);
          });
        } else {
          _key.currentState.showSnackBar(SnackBar(
            content: Text(S
                .of(context)
                .snack_no_flowers),
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

  @override
  void initState() {
    super.initState();
    Offline.setKeepSynced(1, true);
    _filter = new Map<String, String>();
    _filter.addAll(widget.filter);
    _filter.remove(filterHabitat);
    _key = new GlobalKey<ScaffoldState>();

    _setCount();

    Ads.showBannerAd(this);
  }

  @override
  Widget build(BuildContext context) {
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
        actions: getActions(context, widget.onChangeLanguage, widget.onBuyProduct, widget.filter),
      ),
      drawer: AppDrawer(widget.onChangeLanguage, widget.onBuyProduct, _filter, null),
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
                child: Text(S.of(context).habitat_message,
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
        currentIndex: Preferences.myFilterAttributes.indexOf(filterHabitat),
        items: getBottomNavigationBarItems(context, _filter),
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          onBottomNavigationBarTap(context, widget.onChangeLanguage, widget.onBuyProduct, _filter, index, Preferences.myFilterAttributes.indexOf(filterHabitat));
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
