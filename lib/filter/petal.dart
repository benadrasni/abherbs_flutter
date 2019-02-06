import 'dart:async';

import 'package:abherbs_flutter/ads.dart';
import 'package:abherbs_flutter/drawer.dart';
import 'package:abherbs_flutter/filter/filter_utils.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/plant_list.dart';
import 'package:abherbs_flutter/preferences.dart';
import 'package:abherbs_flutter/utils.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

final countsReference = FirebaseDatabase.instance.reference().child(firebaseCounts);

class Petal extends StatefulWidget {
  final void Function(String) onChangeLanguage;
  final void Function(PurchasedItem) onBuyProduct;
  final Map<String, String> filter;
  Petal(this.onChangeLanguage, this.onBuyProduct, this.filter);

  @override
  _PetalState createState() => _PetalState();
}

class _PetalState extends State<Petal> {
  Future<int> _count;
  Map<String, String> _filter;
  GlobalKey<ScaffoldState> _key;

  _navigate(String value) {
    var newFilter = new Map<String, String>();
    newFilter.addAll(_filter);
    newFilter[filterPetal] = value;

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
    _count = countsReference.child(getFilterKey(_filter)).once().then((DataSnapshot snapshot) {
      return snapshot.value;
    });
  }

  @override
  void initState() {
    super.initState();
    _filter = new Map<String, String>();
    _filter.addAll(widget.filter);
    _filter.remove(filterPetal);
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
    );

    return Scaffold(
      key: _key,
      appBar: AppBar(
        title: Text(S.of(context).filter_petal),
        actions: getActions(context, widget.onChangeLanguage, widget.onBuyProduct),
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
                child: Text(S.of(context).petal_message,
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
          onBottomNavigationBarTap(context, widget.onChangeLanguage, widget.onBuyProduct, _filter, index, Preferences.myFilterAttributes.indexOf(filterPetal));
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
